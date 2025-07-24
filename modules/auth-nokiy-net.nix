{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.auth-nokiy-net;
  authentik = inputs.compose + "/authentik";
in

{
  options.services.anso.auth-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."auth.nokiy.net" = {
      domain = "auth.nokiy.net";
    };

    services.nginx.virtualHosts."auth.nokiy.net" = {
      enableACME = false;
      useACMEHost = "auth.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.auth.localAddress}:9000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Authorization $http_authorization;
          proxy_pass_header Authorization;
        '';
      };
    };

    containers.auth = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.11";
      localAddress = "10.43.0.11";
      hostAddress6 = "fd00::10.42.0.11";
      localAddress6 = "fd00::10.43.0.11";
      bindMounts = {
        "data" = {
          hostPath = "/data/auth-nokiy-net";
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
              9000
            ];
            allowedUDPPorts = [
              9000
            ];
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          environment.etc."auth-nokiy-net/docker-compose.yaml".source = authentik + "/docker-compose.yaml";

          systemd.services.auth = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/auth-nokiy-net/docker-compose.yaml up";
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
