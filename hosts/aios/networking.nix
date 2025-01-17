{
  machine,
  ...
}:

{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "aios";
    enableIPv6 = true;
    useNetworkd = true;
    usePredictableInterfaceNames = true;
  };

  networking.nat = {
    enable = true;
    externalInterface = machine.interfaces.eth0.name;
    internalInterfaces = [
      machine.interfaces.eth1.name
    ];
  };

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
