{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.affine-nokiy-net;
in

{
  options.services.anso.affine-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    service = {
      name = mkOption {
        type = types.str;
        default = "affine-nokiy-net";
      };
    };
    postgres = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/library/postgres:17.4-bookworm";
      };
      db = mkOption {
        type = types.str;
        default = "affine";
      };
      user = mkOption {
        type = types.str;
        default = "affine";
      };
      password = mkOption {
        type = types.str;
        default = "affine";
      };
    };
    valkey = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/valkey/valkey:8.1.1-bookworm";
      };
    };
    server = {
      image = mkOption {
        type = types.str;
        default = "ghcr.io/toeverything/affine-graphql:stable-e043ecf";
      };
    };
    user = {
      name = mkOption {
        type = types.str;
        default = "affine";
      };
      uid = mkOption {
        type = types.int;
        default = 30400;
      };
    };
    group = {
      name = mkOption {
        type = types.str;
        default = "affine";
      };
      gid = mkOption {
        type = types.int;
        default = 30400;
      };
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user.name} = {
      isSystemUser = true;
      uid = cfg.user.uid;
      group = cfg.group.name;
    };
    users.groups.${cfg.group.name} = {
      gid = cfg.group.gid;
    };

    systemd.tmpfiles.settings."${cfg.service.name}" = {
      "/data/${cfg.service.name}" = {
        d = {
          mode = "0751";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
      "/data/${cfg.service.name}/postgres" = {
        d = {
          mode = "0751";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
      "/data/${cfg.service.name}/valkey" = {
        d = {
          mode = "0751";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
      "/data/${cfg.service.name}/storage" = {
        d = {
          mode = "0751";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
      "/data/${cfg.service.name}/config" = {
        d = {
          mode = "0751";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
    };

    # Target
    systemd.targets."${cfg.service.name}" = {
      unitConfig = {
        Description = "Affine Service";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Podman Network
    systemd.services."podman-network-${cfg.service.name}" = {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman network create ${cfg.service.name}";
        ExecStop = "${pkgs.podman}/bin/podman network rm -f ${cfg.service.name}";
      };
      partOf = [ "${cfg.service.name}.target" ];
      wantedBy = [ "${cfg.service.name}.target" ];
    };

    # Postgres
    virtualisation.oci-containers.containers."${cfg.service.name}-postgres" = {
      image = cfg.postgres.image;
      environment = {
        POSTGRES_DB = cfg.postgres.db;
        POSTGRES_USER = cfg.postgres.user;
        POSTGRES_PASSWORD = cfg.postgres.password;
      };
      volumes = [
        "/data/${cfg.service.name}/postgres:/var/lib/postgresql/data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=pg_isready -U ${cfg.postgres.db}"
        "--health-interval=10s"
        "--health-retries=5"
        "--health-timeout=5s"
        "--network-alias=postgres"
        "--network=${cfg.service.name}"
        "-u=${toString cfg.user.uid}:${toString cfg.group.gid}"
      ];
    };
    systemd.services."podman-${cfg.service.name}-postgres" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-${cfg.service.name}.service"
      ];
      requires = [
        "podman-network-${cfg.service.name}.service"
      ];
      partOf = [
        "${cfg.service.name}.target"
      ];
      wantedBy = [
        "${cfg.service.name}.target"
      ];
    };

    # Valkey
    virtualisation.oci-containers.containers."${cfg.service.name}-valkey" = {
      image = cfg.valkey.image;
      volumes = [
        "/data/${cfg.service.name}/valkey:/data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=[\"redis-cli\", \"--raw\", \"incr\", \"ping\"]"
        "--health-interval=10s"
        "--health-retries=5"
        "--health-timeout=5s"
        "--network-alias=valkey"
        "--network=${cfg.service.name}"
        "-u=${toString cfg.user.uid}:${toString cfg.group.gid}"
      ];
    };
    systemd.services."podman-${cfg.service.name}-valkey" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-${cfg.service.name}.service"
      ];
      requires = [
        "podman-network-${cfg.service.name}.service"
      ];
      partOf = [
        "${cfg.service.name}.target"
      ];
      wantedBy = [
        "${cfg.service.name}.target"
      ];
    };

    # Affine Server
    sops.templates."${cfg.service.name}/server.env" = {
      content = ''

      '';
      mode = "0440";
      owner = cfg.user.name;
      group = cfg.group.name;
    };
    virtualisation.oci-containers.containers."${cfg.service.name}-server" = {
      image = cfg.server.image;
      # environmentFiles = [ config.sops.templates."${cfg.service.name}/server.env".path ];
      environment = {
        REDIS_SERVER_HOST = "valkey";
        DATABASE_URL = "postgresql://${cfg.postgres.user}:${cfg.postgres.password}@postgres:5432/${cfg.postgres.db}";
        AFFINE_SERVER_EXTERNAL_URL = "https://affine.nokiy.net";
      };
      volumes = [
        "/data/${cfg.service.name}/storage:/root/.affine/storage:rw"
        "/data/${cfg.service.name}/config:/root/.affine/config:rw"
      ];
      cmd = [
        "bash"
        "-c"
        "node ./scripts/self-host-predeploy.js && node --import ./scripts/register.js ./dist/index.js"
      ];
      log-driver = "journald";
      ports = [
        "127.0.0.1:33010:3010"
      ];
      dependsOn = [
        "${cfg.service.name}-postgres"
        "${cfg.service.name}-valkey"
      ];
      extraOptions = [
        "--network-alias=server"
        "--network=${cfg.service.name}"
        "--uidmap=0:${toString cfg.user.uid}:1"
        "--gidmap=0:${toString cfg.group.gid}:1"
      ];
    };
    systemd.services."podman-${cfg.service.name}-server" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      onSuccess = [ "podman-${cfg.service.name}-migration.service" ];
      after = [
        "podman-network-${cfg.service.name}.service"
      ];
      requires = [
        "podman-network-${cfg.service.name}.service"
      ];
      partOf = [
        "${cfg.service.name}.target"
      ];
      wantedBy = [
        "${cfg.service.name}.target"
      ];
    };

    security.acme.certs."affine.nokiy.net" = {
      domain = "affine.nokiy.net";
    };

    services.nginx.virtualHosts."affine.nokiy.net" = {
      enableACME = false;
      useACMEHost = "affine.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:33010";
        proxyWebsockets = true;
      };
    };
  };
}
