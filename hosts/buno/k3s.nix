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

  sops.templates."k3s.env" = {
    content = ''
      K3S_TOKEN=${config.sops.placeholder."token"}
      K3S_AGENT_TOKEN=${config.sops.placeholder."agent-token"}
      K3S_URL=https://enso.internal.nokiy.net:6443
      # AWS_ACCESS_KEY_ID=
      # AWS_SECRET_ACCESS_KEY=
    '';
  };

  services.k3s = {
    enable = true;
    package = pkgs.k3s_1_30;
    role = "server";
    clusterInit = true;
    environmentFile = config.sops.templates."k3s.env".path;
    extraFlags = [
      "--disable-cloud-controller"
      "--disable-helm-controller"
      "--disable=servicelb"
      "--disable-network-policy"
      "--flannel-backend=none"
      "--secrets-encryption"
      "--tls-san=enso.internal.nokiy.net"
      "--tls-san-security=true"
      "--cluster-cidr=10.42.0.0/16,2001:cafe:42::/56"
      "--service-cidr=10.43.0.0/16,2001:cafe:43::/112"
      "--service-node-port-range=30000-32767"
      "--cluster-dns=10.43.0.100,2001:cafe:43::100"
      "--cluster-domain=enso.internal.nokiy.net"
      "--bind-address=0.0.0.0"
      "--https-listen-port=6443"
      "--node-ip=10.41.0.2,2001:cafe:41:2::1"
      "--etcd-expose-metrics=true"
      "--etcd-disable-snapshots=false"
      # "--etcd-s3"
      # "--etcd-s3-endpoint="
      # "--etcd-s3-region="
      # "--etcd-s3-bucket="
      # "--etcd-s3-folder="
    ];
  };

  boot.kernelParams = [
    "vm.panic_on_oom=0"
    "vm.overcommit_memory=1"
    "kernel.panic=10"
    "kernel.panic_on_oops=1"
  ];
}
