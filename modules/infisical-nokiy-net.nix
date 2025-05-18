{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.infisical-nokiy-net;
  infisical = inputs.compose + "/infisical";
in

{
  options.services.anso.infisical-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."infisical.nokiy.net" = {
      domain = "infisical.nokiy.net";
    };

    services.nginx.virtualHosts."infisical.nokiy.net" = {
      enableACME = false;
      useACMEHost = "infisical.nokiy.net";
      forceSSL = true;
      listen = [
        {
          addr = "100.100.10.2";
          port = 443;
          ssl = true;
        }
      ];
      locations."/" = {
        proxyPass = "http://${config.containers.infisical.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Authorization $http_authorization;
          proxy_pass_header Authorization;
        '';
      };
    };

    containers.infisical = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.8";
      localAddress = "10.43.0.8";
      hostAddress6 = "fd00::10.42.0.8";
      localAddress6 = "fd00::10.43.0.8";
      bindMounts = {
        "data" = {
          hostPath = "/data/infisical-nokiy-net";
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
              80
            ];
            allowedUDPPorts = [
              80
            ];
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          environment.etc."infisical-nokiy-net/docker-compose.yaml".source =
            infisical + "/docker-compose.yaml";

          systemd.services."infisical" = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
              SITE_URL = "https://infisical.nokiy.net";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/infisical-nokiy-net/docker-compose.yaml up";
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
