{ inputs, config, ... }:

{
  sops.secrets."fly0/private_key" = { };
  sops.secrets."enso0/private_key" = { };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "buno";
    enableIPv6 = true;
    usePredictableInterfaceNames = true;
    interfaces.enp7s0 = {
      name = "eth0";
      useDHCP = true;
    };
    interfaces.enp9s0 = {
      name = "eth1";
      useDHCP = false;
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [
      "eth1"
      "enso0"
    ];
  };

  sops.secrets."enso0/private_key" = { };
  sops.secrets."enso0/preshared_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/aios/public_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/aios/endpoint/public_ipv4" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/cove/public_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/cove/endpoint/public_ipv4" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.templates."enso0.conf" = {
    content = ''
      [Interface]
      Address = 10.41.0.2/16,2001:cafe:41:2::1/48
      ListenPort = 51820
      DNS = 1.1.1.1,8.8.8.8
      PrivateKey = ${config.sops.placeholder."enso0/private_key"}

      [Peer]
      PublicKey = ${config.sops.placeholder."enso0/aios/public_key"}
      PresharedKey = ${config.sops.placeholder."enso0/preshared_key"}
      AllowedIPs = 10.41.0.1/32,2001:cafe:41:1::1/128,10.41.0.0/16,2001:cafe:41::/48
      Endpoint = ${config.sops.placeholder."enso0/aios/endpoint/public_ipv4"}
      PersistentKeepalive = 25

      [Peer]
      PublicKey = ${config.sops.placeholder."enso0/cove/public_key"}
      PresharedKey = ${config.sops.placeholder."enso0/preshared_key"}
      AllowedIPs = 10.41.0.3/32,2001:cafe:41:3::1/128,10.41.0.0/16,2001:cafe:41::/48
      Endpoint = ${config.sops.placeholder."enso0/cove/endpoint/public_ipv4"}
      PersistentKeepalive = 25
    '';
  };

  networking.wg-quick.interfaces.enso0 = {
    autostart = true;
    configFile = config.sops.templates."enso0.conf".path;
  };

  networking.firewall.enable = true;
  networking.firewall.interfaces.eth0 = {
    allowedTCPPorts = [ ];
    allowedUDPPorts = [
      51820 # WireGuard
    ];
  };
  networking.firewall.interfaces.enso0 = {
    allowedTCPPorts = [
      2379 # etcd
      2380 # etcd
      6443 # api-server
      10250 # metrics-server
    ];
  };
}
