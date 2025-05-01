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
    hostName = "buno";
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
    enableIPv6 = true;
    externalInterface = machine.interfaces.eth0.name;
    internalInterfaces = [
      machine.interfaces.eth1.name
      "podman+"
      "ve-+" # NixOS Containers
    ];
  };

  networking.firewall.enable = true;
  networking.firewall.interfaces."podman+".allowedUDPPorts = [
    53
    5353
  ];
  networking.firewall.trustedInterfaces = [
    "podman+"
    "ve-+" # NixOS Containers
  ];
  networking.firewall.interfaces."${machine.interfaces.eth0.name}" =
    let
      range = with config.services.coturn; [
        {
          from = min-port;
          to = max-port;
        }
      ];
    in
    {
      allowedTCPPorts = [
        80
        443
        3478
        5349
      ];
      allowedUDPPorts = [
        # 51820 # WireGuard
        3478
        5349
      ];
      allowedUDPPortRanges = range;
    };
}
