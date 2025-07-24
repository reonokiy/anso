{
  config,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.synapse-nokiy-net;
  synapse = inputs.compose + "/synapse";
  clientConfig."m.homeserver".base_url = "https://synapse.nokiy.net";
  clientConfig."m.identity_server".base_url = "https://vector.im";
  serverConfig."m.server" = "synapse.nokiy.net:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in

{
  options.services.anso.synapse-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."synapse.nokiy.net" = {
      domain = "synapse.nokiy.net";
      extraDomainNames = [ "auth.synapse.nokiy.net" ];
    };

    services.nginx.virtualHosts."nokiy.net" = {
      enableACME = false;
      useACMEHost = "nokiy.net";
      forceSSL = true;
      locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
      locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
    };

    services.nginx.virtualHosts."synapse.nokiy.net" = {
      enableACME = false;
      useACMEHost = "synapse.nokiy.net";
      forceSSL = true;
      locations."~ ^(/_matrix|/_synapse/client)" = {
        proxyPass = "http://${config.containers.synapse.localAddress}:8008";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Host $host;
          client_max_body_size 200M;
        '';
      };
      locations."~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
        proxyPass = "http://${config.containers.synapse.localAddress}:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    services.nginx.virtualHosts."auth.synapse.nokiy.net" = {
      enableACME = false;
      useACMEHost = "synapse.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.synapse.localAddress}:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    containers.synapse = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.12";
      localAddress = "10.43.0.12";
      hostAddress6 = "fd00::10.42.0.12";
      localAddress6 = "fd00::10.43.0.12";
      bindMounts = {
        "data" = {
          hostPath = "/data/synapse-nokiy-net";
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
              8008
              8080
            ];
            allowedUDPPorts = [
              8008
              8080
            ];
          };

          users.users.synapse = {
            isSystemUser = true;
            uid = 1000;
            group = "synapse";
          };
          users.groups.synapse = {
            gid = 1000;
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          environment.etc."synapse-nokiy-net/docker-compose.yaml".source = synapse + "/docker-compose.yaml";

          systemd.services.synapse = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/synapse-nokiy-net/docker-compose.yaml up";
            serviceConfig = {
              Restart = "always";
              RestartSec = "30s";
            };
          };
        };
    };
  };
}
