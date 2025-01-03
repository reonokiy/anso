{
  config,
  lib,
  pkgs,
  cfg,
  ...
}:

{
  systemd.tmpfiles.settings."${cfg.service.name}-server" = {
    "/data/${cfg.service.name}/server/media" = {
      d = {
        mode = "0740";
        user = cfg.user.name;
        group = cfg.group.name;
      };
    };
    "/data/${cfg.service.name}/server/templates" = {
      d = {
        mode = "0740";
        user = cfg.user.name;
        group = cfg.group.name;
      };
    };
    "/data/${cfg.service.name}/server/certs" = {
      d = {
        mode = "0740";
        user = cfg.user.name;
        group = cfg.group.name;
      };
    };
  };

  sops.templates."${cfg.service.name}.env" = {
    content = ''
      AUTHENTIK_REDIS__HOST=valkey
      AUTHENTIK_POSTGRESQL__HOST=postgres
      AUTHENTIK_POSTGRESQL__NAME=${cfg.postgres.db}
      AUTHENTIK_POSTGRESQL__USER=${cfg.postgres.user}
      AUTHENTIK_POSTGRESQL__PASSWORD=${config.sops.placeholder."${cfg.postgres.passwordSecret}"}
      ${cfg.server.env}
    '';
    mode = "0440";
    owner = cfg.user.name;
    group = cfg.group.name;
  };

  virtualisation.oci-containers.containers."${cfg.service.name}-server" = {
    image = cfg.server.image;
    environmentFiles = [ config.sops.templates."${cfg.service.name}.env".path ];
    volumes = [
      "/data/${cfg.service.name}/server/media:/media:rw"
      "/data/${cfg.service.name}/server/certs:/certs:rw"
      "/data/${cfg.service.name}/server/templates:/templates:rw"
    ];
    ports = [
      "127.0.0.1:${toString cfg.server.httpPort}:9000"
      "127.0.0.1:${toString cfg.server.httpsPort}:9443"
    ];
    dependsOn = [
      "${cfg.service.name}-postgres"
      "${cfg.service.name}-valkey"
    ];
    cmd = [ "server" ];
    log-driver = "journald";
    extraOptions = [
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

  systemd.targets."${cfg.service.name}" = {
    unitConfig = {
      Description = "Authentik Service";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
