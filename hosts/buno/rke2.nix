{
  inputs,
  config,
  pkgs,
  ...
}:

{
  sops.secrets."token" = {
    sopsFile = "${inputs.secrets}/rke2.yaml";
  };

  sops.templates."rke2.yaml" = {
    content = ''
      token: ${config.sops.placeholder."token"}
      # must sync between servers
      cluster-dns: 10.43.0.10
      cluster-cidr: 10.42.0.0/16,2001:cafe:42::/56
      service-cidr: 10.43.0.0/16,2001:cafe:43::/112
      # listener
      tls-san:
        - enso.internal.nokiy.net
      embedded-registry: true
    '';
  };

  environment.etc."rancher/rke2/registries.yaml" = {
    text = ''
      mirrors:
        "docker.io":
          endpoint:
            - "https://mirror.gcr.io"
    '';
  };

  services.rke2 = {
    enable = true;
    cni = "cilium";
    role = "server";
    selinux = true;
    serverAddr = "https://10.41.0.3:9345";
    nodeIP = "10.41.0.2,2001:cafe:41:2::1";
    configPath = config.sops.templates."rke2.yaml".path;
  };

  boot.kernelParams = [
    "vm.panic_on_oom=0"
    "vm.overcommit_memory=1"
    "kernel.panic=10"
    "kernel.panic_on_oops=1"
  ];

  boot.kernelModules = [
    "ip6_tables"
    "ip6table_mangle"
    "ip6table_raw"
    "ip6table_filter"
  ];

  # fix longhorn
  # thanks https://github.com/longhorn/longhorn/issues/2166
  environment.defaultPackages = with pkgs; [ openiscsi ];
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
}
