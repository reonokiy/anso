{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.netbird-nokiy-net;
in

{
  options.services.anso.netbird-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."netbird.nokiy.net" = {
      domain = "netbird.nokiy.net";
    };

    services.nginx.virtualHosts."netbird.nokiy.net" = {
      enableACME = false;
      useACMEHost = "netbird.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.netbird-nokiy-net.localAddress}:80";
        proxyWebsockets = true;
      };
      locations."/api" = {
        proxyPass = "http://${config.containers.netbird-nokiy-net.localAddress}:8011";
        proxyWebsockets = true;
      };
      locations."/management.ManagementService" = {
        extraConfig = ''
          # This is necessary so that grpc connections do not get closed early
          # see https://stackoverflow.com/a/67805465
          client_body_timeout 1d;

          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

          grpc_pass grpc://${config.containers.netbird-nokiy-net.localAddress}:8011;
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

        grpc_pass grpc://${config.containers.netbird-nokiy-net.localAddress}:8012;
        grpc_read_timeout 1d;
        grpc_send_timeout 1d;
        grpc_socket_keepalive on;
      '';
    };

    containers.netbird-nokiy-net = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.42.0.4";
      localAddress = "10.43.0.4";
      hostAddress6 = "fd00::10.42.0.4";
      localAddress6 = "fd00::10.43.0.4";
      # bindMounts = {
      #   "data" = {
      #     hostPath = "/data/netbird-nokiy-net";
      #     mountPoint = "/data";
      #     isReadOnly = false;
      #   };
      # };
      config =
        { lib, ... }:
        {
          system.stateVersion = "24.11";
          networking.useHostResolvConf = true;
          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ 80 ];
            allowedUDPPorts = [ 80 ];
          };

          services.netbird.server = {
            enable = true;
            domain = "netbird.nokiy.net";
            coturn.enable = false;
            dashboard = {
              enable = true;
              domain = "netbird.nokiy.net";
              managementServer = "https://netbird.nokiy.net";
              settings = {
                AUTH_AUTHORITY = "https://netbird.nokiy.net";
                AUTH_AUDIENCE = "netbird";
                AUTH_CLIENT_ID = "netbird";
                AUTH_SUPPORTED_SCOPES = "openid email profile";
                # NETBIRD_TOKEN_SOURCE = "oidc";
                USE_AUTH0 = false;
              };
            };
            management = {
              enable = true;
              domain = "netbird.nokiy.net";
              dnsDomain = "bird.nokiy.net";
              port = 8011;
              turnPort = 3478;
              metricsPort = 9090;
              turnDomain = "turn.nokiy.net";
              disableSingleAccountMode = true;
              oidcConfigEndpoint = "https://auth.nokiy.net/application/o/netbird/.well-known/openid-configuration";
              settings = {
              };
            };
            signal = {
              enable = true;
              domain = "netbird.nokiy.net";
              port = 8012;
              metricsPort = 9091;
            };
          };
        };
    };
  };
}
