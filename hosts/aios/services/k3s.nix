{ config, machine, ... }:

{
  sops.secrets."k3s/token" = { };

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.sops.secrets."k3s/token".path;
    extraFlags = [
      "--cluster-cidr=10.42.0.0/16"
      "--service-cidr=10.43.0.0/16"
      "--node-ip=100.100.10.1"
      "--node-external-ip=${machine.interfaces.eth0.ipv4.address}"
      "--tls-san=100.100.10.1"
      "--disable=traefik"
    ];
  };

  networking.nat.internalInterfaces = [ "cni+" "flannel.+" ];
  networking.firewall.trustedInterfaces = [ "cni+" "flannel.+" ];
}
