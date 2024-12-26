{ config, ... }:

{
  sops.secrets."fly0/private_key" = { };

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

  networking.wg-quick.interfaces.fly0 = {
    autostart = true;
    privateKeyFile = config.sops.secrets."fly0/private_key".path;
    address = [ "fdaa:9:7373:a7b:163a:0:a:2/120" ];
    dns = [ "fdaa:9:7373::3" ];
    peers = [
      {
        publicKey = "DBn8uXwmcc4A06//C0T3bX9gjNp0eh/EzS4MDjnSKhc=";
        allowedIPs = [ "fdaa:9:7373::/48" ];
        endpoint = "fra1.gateway.6pn.dev:51820";
        persistentKeepalive = 15;
      }
    ];
  };
}
