{ config, pkgs, ... }:
{
  systemd.tmpfiles.settings."postgres-data" = {
    "/data/postgres/17" = {
      d = {
        mode = "0740";
        user = "postgres";
        group = "postgres";
      };
    };
    "/data/postgres/backup" = {
      d = {
        mode = "0740";
        user = "postgres";
        group = "postgres";
      };
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    enableTCPIP = false;
    dataDir = "/data/postgres/17";
    ensureDatabases = [
      "matrix-synapse"
      "forgejo"
    ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
  };
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    databases = config.services.postgresql.ensureDatabases;
    location = "/data/postgres/backup";
    startAt = "*-*-* 04:30:00 Asia/Shanghai";
  };
}
