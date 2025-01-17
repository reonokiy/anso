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
    usePredictableInterfaceNames = true;
    interfaces.${machine.interfaces.eth0.name}.ipv6 = {
      addresses = [
        {
          address = machine.interfaces.eth0.ipv6.address;
          prefixLength = 64;
        }
      ];
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = machine.interfaces.eth0.name;
    internalInterfaces = [
      "podman+"
    ];
  };

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [
    "podman+"
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
