{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.git-nokiy-net;
  forgejo = inputs.compose + "/forgejo";
in

{
  options.services.anso.git-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."git.nokiy.net" = {
      domain = "git.nokiy.net";
    };

    services.nginx.virtualHosts."git" = {
      enableACME = false;
      useACMEHost = "git.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.git.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Authorization $http_authorization;
          proxy_pass_header Authorization;
        '';
      };
    };

    containers.git = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.6";
      localAddress = "10.43.0.6";
      hostAddress6 = "fd00::10.42.0.6";
      localAddress6 = "fd00::10.43.0.6";
      bindMounts = {
        "data" = {
          hostPath = "/data/git-nokiy-net";
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
          system.stateVersion = "24.11";
          networking.useHostResolvConf = true;
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
          environment.etc."git-nokiy-net/docker-compose.yaml".source = forgejo + "/docker-compose.yaml";
          boot.tmp.cleanOnBoot = true;

          systemd.services."git-nokiy-net" = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/git-nokiy-net/docker-compose.yaml up";
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
