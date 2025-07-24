{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.cloud-nokiy-net;
in

{
  options.services.anso.cloud-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."cloud-nokiy-net/admin/password" = {
      mode = "0600";
      owner = "service";
      group = "service";
    };

    systemd.tmpfiles.settings."cloud-nokiy-net" = {
      "/data/cloud-nokiy-net" = {
        d = {
          mode = "0771";
          user = "service";
          group = "service";
        };
      };
      "/data/cloud-nokiy-net/nextcloud" = {
        d = {
          mode = "0750";
          user = "service";
          group = "service";
        };
      };
      "/data/cloud-nokiy-net/postgres" = {
        d = {
          mode = "0750";
          user = "postgres";
          group = "postgres";
        };
      };
      "/data/cloud-nokiy-net/postgres/17" = {
        d = {
          mode = "0750";
          user = "postgres";
          group = "postgres";
        };
      };
      "/data/cloud-nokiy-net/postgres/backup" = {
        d = {
          mode = "0750";
          user = "postgres";
          group = "postgres";
        };
      };
    };

    security.acme.certs."cloud.nokiy.net" = {
      domain = "cloud.nokiy.net";
    };

    services.nginx.virtualHosts."cloud.nokiy.net" = {
      enableACME = false;
      useACMEHost = "cloud.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${config.containers.cloud-nokiy-net.localAddress}:80";
        proxyWebsockets = true;
      };
    };

    containers.cloud-nokiy-net = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.42.0.2";
      localAddress = "10.43.0.2";
      hostAddress6 = "fd00::10.42.0.2";
      localAddress6 = "fd00::10.43.0.2";
      bindMounts = {
        "nextcloud-admin-pass" = {
          hostPath = config.sops.secrets."cloud-nokiy-net/admin/password".path;
          mountPoint = "/tmp/secrets/nextcloud-admin-password";
          isReadOnly = true;
        };
        "data" = {
          hostPath = "/data/cloud-nokiy-net";
          mountPoint = "/data";
          isReadOnly = false;
        };
      };
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

          users.users.nextcloud = {
            uid = lib.mkForce 10000;
            group = "nextcloud";
            isSystemUser = true;
          };
          users.groups.nextcloud = {
            gid = lib.mkForce 10000;
          };
          users.users.postgres = {
            uid = lib.mkForce 10001;
            group = "postgres";
            isSystemUser = true;
          };
          users.groups.postgres.gid = lib.mkForce 10001;

          services.nextcloud = {
            enable = true;
            package = pkgs.nextcloud31;
            home = "/data/nextcloud";
            hostName = "cloud.nokiy.net";
            configureRedis = true;
            config = {
              dbtype = "pgsql";
              dbhost = "/run/postgresql";
              dbuser = "nextcloud";
              dbname = "nextcloud";
              adminuser = "reonokiy";
              adminpassFile = "/tmp/secrets/nextcloud-admin-password";
              # objectstore.s3 = {
              #   enabled = true;
              #   autocreate = true;
              #   useSsl = true;
              #   bucket = "cloud-nokiy-net";
              #   hostname = "s3.eu-central-003.backblazeb2.com";
              #   key = "003f00010000000000000000";
              #   secretFile = "/tmp/secrets/nextcloud/s3-secret-key";
              #   sseCKeyFile = "/tmp/secrets/nextcloud/s3-sse-c-key";
              # };
            };
          };

          services.postgresql = {
            enable = true;
            package = pkgs.postgresql_17;
            enableTCPIP = false;
            dataDir = "/data/postgres/17";
            ensureDatabases = [
              "nextcloud"
            ];
            ensureUsers = [
              {
                name = "nextcloud";
                ensureDBOwnership = true;
              }
            ];
          };

          services.postgresqlBackup = {
            enable = true;
            compression = "zstd";
            databases = [ "nextcloud" ];
            location = "/data/postgres/backup";
            startAt = "*-*-* 04:30:00 Asia/Shanghai";
          };
        };
    };
  };
}
