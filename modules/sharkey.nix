{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.sharkey;
in

{
  options.services.anso.sharkey = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    service = {
      name = mkOption {
        type = types.str;
        default = "sharkey";
      };
    };
    postgres = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/library/postgres:16.6-bookworm";
      };
      db = mkOption {
        type = types.str;
        default = "sharkey";
      };
      user = mkOption {
        type = types.str;
        default = "sharkey";
      };
      passwordSecret = mkOption {
        type = types.str;
        default = "sharkey/postgres/password";
      };
    };
    valkey = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/valkey/valkey:8.0.1-bookworm";
      };
    };
    meilisearch = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/getmeili/meilisearch:v1.3.4";
      };
      masterKeySecret = mkOption {
        type = types.str;
        default = "sharkey/meilisearch/master_key";
      };
    };
    server = {
      image = mkOption {
        type = types.str;
        default = "registry.activitypub.software/transfem-org/sharkey:2024.11.2";
      };
      port = mkOption {
        type = types.int;
        default = 30300;
      };
      url = mkOption {
        type = types.str;
        default = "http://localhost/";
      };
    };
    user = {
      name = mkOption {
        type = types.str;
        default = "sharkey";
      };
      uid = mkOption {
        type = types.int;
        default = 30300;
      };
    };
    group = {
      name = mkOption {
        type = types.str;
        default = "sharkey";
      };
      gid = mkOption {
        type = types.int;
        default = 30300;
      };
    };
  };

  config = mkIf cfg.enable {
    # user and group
    users.users.${cfg.user.name} = {
      isSystemUser = true;
      uid = cfg.user.uid;
      group = cfg.group.name;
    };
    users.groups.${cfg.group.name} = {
      gid = cfg.group.gid;
    };

    # Target
    systemd.targets."${cfg.service.name}" = {
      unitConfig = {
        Description = "Sharkey Service";
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
    systemd.tmpfiles.settings."${cfg.service.name}-postgres" = {
      "/data/${cfg.service.name}/postgres" = {
        d = {
          mode = "0740";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
    };
    sops.templates."${cfg.service.name}/postgres.env" = {
      content = ''
        POSTGRES_DB=${cfg.postgres.db}
        POSTGRES_USER=${cfg.postgres.user}
        POSTGRES_PASSWORD=${config.sops.placeholder."${cfg.postgres.passwordSecret}"}
      '';
      mode = "0440";
      owner = cfg.user.name;
      group = cfg.group.name;
    };
    virtualisation.oci-containers.containers."${cfg.service.name}-postgres" = {
      image = cfg.postgres.image;
      environmentFiles = [ config.sops.templates."${cfg.service.name}/postgres.env".path ];
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
    systemd.tmpfiles.settings."${cfg.service.name}-valkey" = {
      "/data/${cfg.service.name}/valkey" = {
        d = {
          mode = "0740";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
    };
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

    # MeiliSearch
    systemd.tmpfiles.settings."${cfg.service.name}-meilisearch" = {
      "/data/${cfg.service.name}/meilisearch" = {
        d = {
          mode = "0740";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
    };
    sops.templates."${cfg.service.name}/meilisearch.env" = {
      content = ''
        MEILI_NO_ANALYTICS=true
        MEILI_ENV=production
        MEILI_MASTER_KEY=${config.sops.placeholder."${cfg.meilisearch.masterKeySecret}"}
      '';
      mode = "0440";
      owner = cfg.user.name;
      group = cfg.group.name;
    };
    virtualisation.oci-containers.containers."${cfg.service.name}-meilisearch" = {
      image = cfg.meilisearch.image;
      environmentFiles = [
        config.sops.templates."${cfg.service.name}/meilisearch.env".path
      ];
      volumes = [
        "/data/${cfg.service.name}/meilisearch:/meili_data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=meilisearch"
        "--network=${cfg.service.name}"
        "-u=${toString cfg.user.uid}:${toString cfg.group.gid}"
      ];
    };
    systemd.services."podman-${cfg.service.name}-meilisearch" = {
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

    # Sharkey
    systemd.tmpfiles.settings."${cfg.service.name}-server" = {
      "/data/${cfg.service.name}/files" = {
        d = {
          mode = "0740";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
      "/data/${cfg.service.name}/config" = {
        d = {
          mode = "0740";
          user = cfg.user.name;
          group = cfg.group.name;
        };
      };
    };
    sops.templates."${cfg.service.name}/server.env" = {
      content = ''
        MISSKEY_URL=${cfg.server.url}
        POSTGRES_PASSWORD=${config.sops.placeholder.${cfg.postgres.passwordSecret}}
        POSTGRES_USER=${cfg.postgres.user}
        POSTGRES_DB=${cfg.postgres.db}
      '';
      mode = "0440";
      owner = cfg.user.name;
      group = cfg.group.name;
    };
    virtualisation.oci-containers.containers."${cfg.service.name}-server" = {
      image = cfg.server.image;
      environmentFiles = [ config.sops.templates."${cfg.service.name}/server.env".path ];
      volumes = [
        "/data/${cfg.service.name}/files:/sharkey/files:rw"
        "/data/${cfg.service.name}/config:/sharkey/.config:ro"
      ];
      log-driver = "journald";
      ports = [
        "127.0.0.1:${toString cfg.server.port}:3000"
      ];
      dependsOn = [
        "${cfg.service.name}-postgres"
        "${cfg.service.name}-valkey"
        "${cfg.service.name}-meilisearch"
      ];
      extraOptions = [
        "--network-alias=sharkey"
        "--network=${cfg.service.name}"
        "-u=${toString cfg.user.uid}:${toString cfg.group.gid}"
      ];
    };
    systemd.services."podman-${cfg.service.name}-server" = {
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
  };
}
