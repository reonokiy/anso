{
  config,
  lib,
  cfg,
  ...
}:

{
  virtualisation.oci-containers.containers."${cfg.service.name}-worker" = {
    image = cfg.server.image;
    environmentFiles = [ config.sops.templates."${cfg.service.name}.env".path ];
    volumes = [
      "/data/${cfg.service.name}/server/media:/media:rw"
      "/data/${cfg.service.name}/server/certs:/certs:rw"
      "/data/${cfg.service.name}/server/templates:/templates:rw"
    ];
    dependsOn = [
      "${cfg.service.name}-postgres"
      "${cfg.service.name}-valkey"
    ];
    cmd = [ "worker" ];
    log-driver = "journald";
    extraOptions = [
      "--network=${cfg.service.name}"
      "-u=${toString cfg.user.uid}:${toString cfg.group.gid}"
    ];
  };

  systemd.services."podman-${cfg.service.name}-worker" = {
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
