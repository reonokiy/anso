{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ rustic ];

  users.users.rustic = {
    isSystemUser = true;
    group = "rustic";
  };
  users.groups.rustic = { };

  sops.secrets."rustic/b2/application_key_id" = { };
  sops.secrets."rustic/b2/application_key" = { };
  sops.secrets."rustic/password" = {
    mode = "0400";
    owner = "rustic";
  };

  sops.templates."rustic.toml" = {
    mode = "0400";
    owner = "rustic";
    group = "rustic";
    path = "/etc/rustic/rustic.toml";
    content = ''
      [repository]
      repository = "opendal:b2"
      password-file = "${config.sops.secrets."rustic/password".path}"

      [repository.options]
      application_key_id = "${
        config.sops.placeholder."rustic/b2/application_key_id"
      }"
      application_key = "${config.sops.placeholder."rustic/b2/application_key"}"
      bucket = "anso-rustic-backup"
      bucket_id = "fd8154d2b8b85a4b914d0312"
      root = "/"

      [forget]
      keep-daily = 7
      keep-weekly = 2
      keep-monthly = 6
      keep-yearly = 3

      [backup]
      host = "buno"
      group-by = "host,label"

      [[backup.snapshots]]
      label = "synapse"
      sources = ["/data/synapse"]
      globs = ["!data/synapse/server/media_store"]

      [[backup.snapshots]]
      label = "authentik"
      sources = [ "/data/authentik" ]
      globs = ["!data/authentik/valkey"]

      [backup.snapshots.hooks]
      run-before = ["systemctl stop authentik.target"]
      run-finally = ["systemctl start authentik.target"]

      [[backup.snapshots]]
      label = "postgres"
      sources = [ "/data/postgres" ]
      globs = ["!data/postgres/backup"]

      [backup.snapshots.hooks]
      run-before = ["systemctl stop postgresql.service"]
      run-finally = [
        "systemctl start postgresql.service",
        "systemctl start forgejo.service",
        "systemctl start matrix-synapse.service"
      ]

      [[backup.snapshots]]
      label = "postgres-backup"
      sources = [ "/data/postgres/backup" ]

      [[backup.snapshots]]
      label = "forgejo"
      sources = [ "/data/forgejo" ]
      globs = ["!data/forgejo/backup"]

      [[backup.snapshots]]
      label = "forgejo-backup"
      sources = [ "/data/forgejo/backup" ]

      [[backup.snapshots]]
      label = "grafana"
      sources = [ "/data/grafana" ]

      [[backup.snapshots]]
      label = "kanidm"
      sources = [ "/data/kanidm" ]

      [backup.snapshots.hooks]
      run-before = ["systemctl stop podman-kanidm.service"]
      run-finally = ["systemctl start podman-kanidm.service"]

      [[backup.snapshots]]
      label = "gotosocial"
      sources = [ "/data/gotosocial" ]

      [backup.snapshots.hooks]
      run-before = ["systemctl stop podman-gotosocial.service"]
      run-finally = ["systemctl start podman-gotosocial.service"]
    '';
  };

  systemd.timers."rustic-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:50:00 Asia/Shanghai";
      Persistent = true;
      Unit = "rustic-backup.service";
    };
  };

  systemd.services."rustic-backup" = {
    script = ''
      set -eu
      ${pkgs.rustic}/bin/rustic backup
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
