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
      machine.interfaces.eth1.name
      "podman+"
    ];
  };

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [
    "podman+"
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
