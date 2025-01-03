{
  config,
  lib,
  cfg,
  ...
}:

{
  systemd.tmpfiles.settings."${cfg.service.name}-postgres" = {
    "/data/${cfg.service.name}/postgres" = {
      d = {
        mode = "0740";
        user = cfg.user.name;
        group = cfg.group.name;
      };
    };
  };

  sops.templates."${cfg.service.name}-postgres.env" = {
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
    environmentFiles = [ config.sops.templates."${cfg.service.name}-postgres.env".path ];
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
}
