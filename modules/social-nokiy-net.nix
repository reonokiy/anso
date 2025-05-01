{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.social-nokiy-net;
in

{
  options.services.anso.social-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."social-nokiy-net/oidc/client_id" = { };
    sops.secrets."social-nokiy-net/oidc/client_secret" = { };
    sops.secrets."social-nokiy-net/b2/access_key" = { };
    sops.secrets."social-nokiy-net/b2/secret_key" = { };

    sops.templates."social-nokiy-net.env" = {
      content = ''
        GTS_OIDC_CLIENT_ID=${config.sops.placeholder."social-nokiy-net/oidc/client_id"}
        GTS_OIDC_CLIENT_SECRET=${config.sops.placeholder."social-nokiy-net/oidc/client_secret"}
        GTS_STORAGE_S3_ACCESS_KEY=${config.sops.placeholder."social-nokiy-net/b2/access_key"}
        GTS_STORAGE_S3_SECRET_KEY=${config.sops.placeholder."social-nokiy-net/b2/secret_key"}
      '';
    };

    systemd.tmpfiles.settings."social-nokiy-net" = {
      "/data/social-nokiy-net" = {
        d = {
          mode = "0771";
          user = "service";
          group = "service";
        };
      };
    };
    
    security.acme.certs."social.nokiy.net" = {
      domain = "social.nokiy.net";
    };

    services.nginx.virtualHosts."social.nokiy.net" = {
      enableACME = false;
      useACMEHost = "social.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.social-nokiy-net.localAddress}:80";
        proxyWebsockets = true;
      };
    };

    containers.social-nokiy-net = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.42.0.3";
      localAddress = "10.43.0.3";
      hostAddress6 = "fd00::10.42.0.3";
      localAddress6 = "fd00::10.43.0.3";
      bindMounts = {
        "social-nokiy-net.env" = {
          hostPath = config.sops.templates."social-nokiy-net.env".path;
          mountPoint = "/tmp/secrets/social-nokiy-net.env";
          isReadOnly = true;
        };
        "data" = {
          hostPath = "/data/social-nokiy-net";
          mountPoint = "/data";
          isReadOnly = false;
        };
      };
      config = {lib, ...}: {
        system.stateVersion = "24.11";
        networking.useHostResolvConf = true;
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 80 ];
          allowedUDPPorts = [ 80 ];
        };

        users.users.gotosocial = {
          uid = lib.mkForce 10000;
          group = "gotosocial";
        };

        users.groups.gotosocial ={
          gid = lib.mkForce 10000;
        };

        services.gotosocial = {
          enable = true;
          openFirewall = true;
          setupPostgresqlDB = false;
          environmentFile = "/tmp/secrets/social-nokiy-net.env";
          settings = {
            host = "social.nokiy.net";
            port = 80;
            bind-address = "0.0.0.0";
            trusted-proxies = [ "10.0.0.10" "10.0.0.11" "fd00::10" "fd00::11" ];
            instance-languages = [ "zh-Hans-CN" "en"];
            accounts-allow-custom-css = true;
            db-address = "/data/sqlite.db";
            storage-backend = "s3";
            storage-s3-endpoint = "s3.eu-central-003.backblazeb2.com";
            storage-s3-bucket = "social-nokiy-net";
            storage-s3-proxy = true;
            oidc-enabled = true;
            oidc-idp-name = "Nokiy Auth";
            oidc-issuer = "https://auth.nokiy.net/application/o/gotosocial/";
            oidc-link-existing = true;
            oidc-allowed-groups = [ "gotosocial-admin" "gotosocial-user" ];
            oidc-admin-groups = [ "gotosocial-admin" ];
          };
        };
      };
    };
  };
}
