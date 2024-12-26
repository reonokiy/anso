{
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
    internalInterfaces = [ "eth1" ];
  };
}
