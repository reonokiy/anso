{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.analytics-nokiy-net;
  umami = inputs.compose + "/umami";
in

{
  options.services.anso.analytics-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."analytics.nokiy.net" = {
      domain = "analytics.nokiy.net";
    };

    services.nginx.virtualHosts."analytics.nokiy.net" = {
      enableACME = false;
      useACMEHost = "analytics.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.analytics.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Authorization $http_authorization;
          proxy_pass_header Authorization;
        '';
      };
    };
    containers.analytics = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.10";
      localAddress = "10.43.0.10";
      hostAddress6 = "fd00::10.42.0.10";
      localAddress6 = "fd00::10.43.0.10";
      bindMounts = {
        "data" = {
          hostPath = "/data/analytics-nokiy-net";
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
            allowedTCPPorts = [ 80 ];
            allowedUDPPorts = [ 80 ];
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          environment.etc."analytics-nokiy-net/docker-compose.yaml".source = umami + "/docker-compose.yaml";

          systemd.services."analytics" = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/analytics-nokiy-net/docker-compose.yaml up";
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
