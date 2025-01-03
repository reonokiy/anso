{
  lib,
  cfg,
  ...
}:

{
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
}
