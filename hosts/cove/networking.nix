{ inputs, config, ... }:

{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "cove";
    enableIPv6 = true;
    usePredictableInterfaceNames = true;
    interfaces.enp1s0 = {
      name = "eth0";
      useDHCP = true;
    };
    interfaces.enp7s0 = {
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
  sops.secrets."enso0/aios/public_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/aios/preshared_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/aios/endpoint/public_ipv4" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/buno/public_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/buno/preshared_key" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.secrets."enso0/buno/endpoint/public_ipv4" = {
    sopsFile = "${inputs.secrets}/wireguard.yaml";
  };
  sops.templates."enso0.conf" = {
    content = ''
      [Interface]
      Address = 10.41.0.3/16,2001:cafe:41:3::1/48
      ListenPort = 51820
      DNS = 1.1.1.1,8.8.8.8
      PrivateKey = ${config.sops.placeholder."enso0/private_key"}

      [Peer]
      PublicKey = ${config.sops.placeholder."enso0/aios/public_key"}
      PresharedKey = ${config.sops.placeholder."enso0/aios/preshared_key"}
      AllowedIPs = 10.41.0.1/32,2001:cafe:41:1::1/64,10.41.0.1/16,2001:cafe:41:1::1/48
      Endpoint = ${config.sops.placeholder."enso0/aios/endpoint/public_ipv4"}
      PersistentKeepalive = 25

      [Peer]
      PublicKey = ${config.sops.placeholder."enso0/buno/public_key"}
      PresharedKey = ${config.sops.placeholder."enso0/buno/preshared_key"}
      AllowedIPs = 10.41.0.2/32,2001:cafe:41:2::1/64,10.41.0.2/16,2001:cafe:41:2::1/48
      Endpoint = ${config.sops.placeholder."enso0/buno/endpoint/public_ipv4"}
      PersistentKeepalive = 25
    '';
  };

  networking.wg-quick.interfaces.enso0 = {
    autostart = true;
    configFile = config.sops.templates."enso0.conf".path;
  };

  networking.firewall.enable = true;
  networking.firewall = {
    allowedTCPPorts = [ ];
    allowedUDPPorts = [
      51820 # WireGuard
    ];
  };
}
