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
    defaultGateway6 = {
      address = "fe80::1";
      interface = machine.interfaces.eth0.name;
    };
    usePredictableInterfaceNames = true;
    interfaces.${machine.interfaces.eth0.name}.ipv6 = {
      addresses = [
        {
          address = machine.interfaces.eth0.ipv6.address;
          prefixLength = 64;

        }
      ];
      routes = [
        {
          address = "fe80::1";
          prefixLength = 128;
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
