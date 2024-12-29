{
  inputs,
  config,
  pkgs,
  ...
}:

{
  sops.secrets."token" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."agent-token" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };

  sops.templates."rke2.yaml" = {
    content = ''
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
    nodeIP = "10.41.0.3,2001:cafe:41:3::1";
    tokenFile = config.sops.secrets."token".path;
    agentTokenFile = config.sops.secrets."agent-token".path;
    configPath = config.sops.templates."rke2.yaml".path;
  };

  networking.firewall.interfaces.enso0 = {
    allowedTCPPortRanges = [
      {
        from = 0;
        to = 65535;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 0;
        to = 65535;
      }
    ];
  };

  boot.kernelParams = [
    "vm.panic_on_oom=0"
    "vm.overcommit_memory=1"
    "kernel.panic=10"
    "kernel.panic_on_oops=1"
  ];
}
