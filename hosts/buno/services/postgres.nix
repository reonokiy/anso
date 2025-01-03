{ pkgs, ... }:
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
    ensureDatabases = [ "matrix-synapse" ];
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
    databases = [ "matrix-synapse" ];
    location = "/data/postgresql/backup";
    startAt = "*-*-* 08:15:00";
  };
}
