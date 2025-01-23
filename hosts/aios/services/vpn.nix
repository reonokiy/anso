{ config, ... }:

{
  sops.secrets."wg/vpn0/privateKey" = { };
  networking.wg-quick.interfaces.vpn0 = {
    autoStart = true;
    address = "10.200.0.1/24";
    privateKeyFile = config.sops.secrets."wg/vpn0/privateKey".path;
  };
}
