{
  virtualisation.oci-containers = {
    backend = "podman";
  };

  virtualisation = {
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  users.users.service = {
    uid = 10000;
    group = "service";
    isSystemUser = true;
    isNormalUser = false;
  };
  users.groups.service = {
    gid = 10000;
  };
}
