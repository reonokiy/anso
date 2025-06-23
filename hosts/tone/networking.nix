{
  inputs,
  config,
  machine,
  ...
}:

let
  hostname = "tone";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = hostname;
    usePredictableInterfaceNames = true;
    enableIPv6 = false;
    # defaultGateway6 = {
    #   address = "fe80::1";
    #   interface = machine.interfaces.eth0.name;
    # };
    # interfaces.${machine.interfaces.eth0.name}.ipv6 = {
    #   addresses = [
    #     {
    #       address = machine.interfaces.eth0.ipv6.address;
    #       prefixLength = 128;
    #     }
    #   ];
    #   routes = [
    #     {
    #       address = "fe80::1";
    #       prefixLength = 128;
    #     }
    #   ];
    # };
  };

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [
    "docker+"
    "podman+"
  ];
  networking.firewall.interfaces."${hostname}" = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      51820 # WireGuard
    ];
  };
}
