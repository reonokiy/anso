{
  inputs,
  config,
  machine,
  ...
}:

{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "cove";
    enableIPv6 = true;
    useNetworkd = true;
    usePredictableInterfaceNames = true;
  };

  systemd.network.networks."10-wan" = {
    name = machine.interfaces.eth0.name;
    DHCP = "ipv4";
    address = machine.interfaces.eth0.ipv6.address;
    gateway = machine.interfaces.eth0.ipv6.gateway;
  };

  systemd.network.networks."11-lan" = {
    name = machine.interfaces.eth1.name;
    DHCP = "ipv4";
  };

  # systemd.network.networks."20-enso" = {
  #   name = "enso0";
  #   address = [
  #     "10.41.0.3/16"
  #     "2001:cafe:41:3::1/48"
  #   ];
  # };

  networking.nat = {
    enable = true;
    externalInterface = machine.interfaces.eth0.name;
    internalInterfaces = [
      machine.interfaces.eth1.name
      # "enso0"
    ];
  };

  # sops.secrets."enso0/private_key" = { };
  # sops.secrets."enso0/preshared_key" = {
  #   sopsFile = "${inputs.secrets}/wireguard.yaml";
  # };
  # sops.secrets."enso0/aios/public_key" = {
  #   sopsFile = "${inputs.secrets}/wireguard.yaml";
  # };
  # sops.secrets."enso0/aios/endpoint/public_ipv4" = {
  #   sopsFile = "${inputs.secrets}/wireguard.yaml";
  # };
  # sops.secrets."enso0/buno/public_key" = {
  #   sopsFile = "${inputs.secrets}/wireguard.yaml";
  # };
  # sops.secrets."enso0/buno/endpoint/public_ipv4" = {
  #   sopsFile = "${inputs.secrets}/wireguard.yaml";
  # };
  # sops.templates."enso0.conf" = {
  #   content = ''
  #     [Interface]
  #     Address = 10.41.0.3/16,2001:cafe:41:3::1/48
  #     ListenPort = 51820
  #     DNS = 1.1.1.1,8.8.8.8
  #     PrivateKey = ${config.sops.placeholder."enso0/private_key"}

  #     [Peer]
  #     PublicKey = ${config.sops.placeholder."enso0/aios/public_key"}
  #     PresharedKey = ${config.sops.placeholder."enso0/preshared_key"}
  #     AllowedIPs = 10.41.0.1/32,2001:cafe:41:1::1/128,10.41.0.0/16,2001:cafe:41::/48
  #     Endpoint = ${config.sops.placeholder."enso0/aios/endpoint/public_ipv4"}
  #     PersistentKeepalive = 25

  #     [Peer]
  #     PublicKey = ${config.sops.placeholder."enso0/buno/public_key"}
  #     PresharedKey = ${config.sops.placeholder."enso0/preshared_key"}
  #     AllowedIPs = 10.41.0.2/32,2001:cafe:41:2::1/128,10.41.0.0/16,2001:cafe:41::/48
  #     Endpoint = ${config.sops.placeholder."enso0/buno/endpoint/public_ipv4"}
  #     PersistentKeepalive = 25
  #   '';
  # };

  # networking.wg-quick.interfaces.enso0 = {
  #   autostart = true;
  #   configFile = config.sops.templates."enso0.conf".path;
  # };

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [
    "enso+"
    "cilium+"
    "lxc+"
  ];
  networking.firewall.interfaces.${machine.interfaces.eth0.name} = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      51820 # WireGuard
    ];
  };
}
