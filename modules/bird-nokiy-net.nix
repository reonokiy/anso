{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.bird-nokiy-net;
  docker-compose-file = builtins.readFile ./compose/bird-nokiy-net/docker-compose.yaml;
in

{
  options.services.anso.bird-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."bird.nokiy.net" = {
      domain = "bird.nokiy.net";
    };

    services.nginx.virtualHosts."bird.nokiy.net" = {
      enableACME = false;
      useACMEHost = "bird.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.bird.localAddress}:8080";
        proxyWebsockets = true;
      };
      locations."/api" = {
        proxyPass = "http://${config.containers.bird.localAddress}:8083";
        proxyWebsockets = true;
      };
      locations."/relay" = {
        proxyPass = "http://${config.containers.bird.localAddress}:8082";
        proxyWebsockets = true;
      };
      locations."/management.ManagementService/" = {
        extraConfig = ''
          # This is necessary so that grpc connections do not get closed early
          # see https://stackoverflow.com/a/67805465
          client_body_timeout 1d;

          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

          grpc_pass grpc://${config.containers.bird.localAddress}:8083;
          grpc_read_timeout 1d;
          grpc_send_timeout 1d;
          grpc_socket_keepalive on;
        '';
      };
      locations."/signalexchange.SignalExchange/".extraConfig = ''
        # This is necessary so that grpc connections do not get closed early
        # see https://stackoverflow.com/a/67805465
        client_body_timeout 1d;

        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        grpc_pass grpc://${config.containers.bird.localAddress}:8081;
        grpc_read_timeout 1d;
        grpc_send_timeout 1d;
        grpc_socket_keepalive on;
      '';
    };

    containers.bird = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.4";
      localAddress = "10.43.0.4";
      hostAddress6 = "fd00::10.42.0.4";
      localAddress6 = "fd00::10.43.0.4";
      bindMounts = {
        "data" = {
          hostPath = "/data/bird-nokiy-net";
          mountPoint = "/data";
          isReadOnly = false;
        };
      };
      ephemeral = true;
      extraFlags = [
        "--system-call-filter=@keyring"
        "--system-call-filter=bpf"
        "--system-call-filter=@network-io"
        "--system-call-filter=@basic-io"
        "--system-call-filter=@io-event"
        "--system-call-filter=@ipc"
        "--system-call-filter=@process"
        "--system-call-filter=@signal"
        "--system-call-filter=@timer"
        "--system-call-filter=@file-system"
      ];
      config =
        { lib, pkgs, ... }:
        {
          system.stateVersion = "25.05";
          networking.nameservers = [ "1.1.1.1" ];
          networking.firewall = {
            enable = true;
            allowedTCPPorts = [
              8080
              8081
              8082
              8083
            ];
            allowedUDPPorts = [
              8080
              8081
              8082
              8083
            ];
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          environment.etc."bird-nokiy-net/docker-compose.yaml".text = docker-compose-file;
          boot.tmp.cleanOnBoot = true;

          systemd.services."bird" = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/bird-nokiy-net/docker-compose.yaml up";
            serviceConfig = {
              Restart = "always";
              RestartSec = "30s";
              EnvironmentFile = [
                "/data/.env"
              ];
            };
          };
        };
    };
  };
}
