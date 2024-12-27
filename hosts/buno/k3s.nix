{ inputs, config, ... }:

{
  sops.secrets."token" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."agent-token" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."domain" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."db/name" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."db/host" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."db/username" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };
  sops.secrets."db/password" = {
    sopsFile = "${inputs.secrets}/k3s.yaml";
  };

  sops.templates."k3s.yaml" = {
    content = ''
      debug: true
      cluster-init: false
      server: https://${config.sops.placeholder."domain"}:6443
      token: ${config.sops.placeholder."token"}
      agent-token: ${config.sops.placeholder."agent-token"}
      datastore-endpoint: postgres://${config.sops.placeholder."db/username"}:${
        config.sops.placeholder."db/password"
      }@${config.sops.placeholder."db/host"}/${config.sops.placeholder."db/name"}

      bind-address:
        - 0.0.0.0
      https-listen-port: 6443
      advertise-address: 
        - 10.41.0.2
        # - 2001:cafe:41:2::1
      tls-san:
        - ${config.sops.placeholder."domain"}
      tls-san-security: true
      node-ip:
        - 10.41.0.2
        # - 2001:cafe:41:2::1
      cluster-cidr:
        - 10.42.0.0/16
        # - 2001:cafe:42::/56
      service-cidr:
        - 10.43.0.0/16
        # - 2001:cafe:43::/112
      service-node-port-range:
        - 30000-32767
      cluster-dns:
        - 10.43.0.100
        # - 2001:cafe:43::100
      cluster-domain: ${config.sops.placeholder."domain"}
      secrets-encryption: true
      flannel-backend: none
      disable-network-policy: true
    '';
  };

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = false;
    configPath = config.sops.templates."k3s.yaml".path;
  };

  boot.kernelParams = [
    "vm.panic_on_oom=0"
    "vm.overcommit_memory=1"
    "kernel.panic=10"
    "kernel.panic_on_oops=1"
  ];
}
