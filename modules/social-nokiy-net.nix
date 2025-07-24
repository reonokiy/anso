{
  config,
  lib,
  pkgs,
  machine,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.social-nokiy-net;
  read_token = machine.social-nokiy-net.token;
  gotosocial = inputs.compose + "/gotosocial";
in

{
  options.services.anso.social-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."social.nokiy.net" = {
      domain = "social.nokiy.net";
    };

    services.nginx.virtualHosts."social.nokiy.net" = {
      enableACME = false;
      useACMEHost = "social.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.social.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_hide_header Content-Security-Policy;
          # add_header Content-Security-Policy "default-src 'self'; object-src 'none'; img-src 'self' blob:; media-src 'self'; script-src-elem 'self' https://analytics.nokiy.net; connect-src 'self' https://analytics.nokiy.net;" always;
          proxy_set_header Accept-Encoding "";
          sub_filter_types text/html;
          sub_filter '</head>' '<script defer src="https://analytics.nokiy.net/script.js" data-website-id="b871202c-3434-4fec-9898-e808bd832244"></script></head>';
          sub_filter_once on;
        '';
      };
      locations."/api/v1/timelines/public" = {
        proxyPass = "http://${config.containers.social.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          set $new_auth_header $http_authorization;
          if ($http_authorization = "") {
              set $new_auth_header "Bearer ${read_token}";
          }
          proxy_set_header Authorization $new_auth_header;
        '';
      };
      locations."/api/v1/streaming" = {
        proxyPass = "http://${config.containers.social.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          set $new_auth_header $http_authorization;
          if ($http_authorization = "") {
              set $new_auth_header "Bearer ${read_token}";
          }
          proxy_set_header Authorization $new_auth_header;
        '';
      };
      locations."/api/v1/status" = {
        proxyPass = "http://${config.containers.social.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          set $new_auth_header $http_authorization;
          if ($http_authorization = "") {
              set $new_auth_header "Bearer ${read_token}";
          }
          proxy_set_header Authorization $new_auth_header;
        '';
      };
      locations."/api/v1/search" = {
        proxyPass = "http://${config.containers.social.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          set $new_auth_header $http_authorization;
          if ($http_authorization = "") {
              set $new_auth_header "Bearer ${read_token}";
          }
          proxy_set_header Authorization $new_auth_header;
        '';
      };
      locations."/api/v1/accounts" = {
        proxyPass = "http://${config.containers.social.localAddress}:80";
        proxyWebsockets = true;
        extraConfig = ''
          set $new_auth_header $http_authorization;
          if ($http_authorization = "") {
              set $new_auth_header "Bearer ${read_token}";
          }
          proxy_set_header Authorization $new_auth_header;
        '';
      };
    };

    containers.social = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.3";
      localAddress = "10.43.0.3";
      hostAddress6 = "fd00::10.42.0.3";
      localAddress6 = "fd00::10.43.0.3";
      bindMounts = {
        "data" = {
          hostPath = "/data/social-nokiy-net";
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
          environment.etc."social-nokiy-net/docker-compose.yaml".source = gotosocial + "/docker-compose.yaml";

          systemd.services.social = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/social-nokiy-net/docker-compose.yaml up";
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
