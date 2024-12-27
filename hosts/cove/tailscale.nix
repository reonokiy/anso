{ config, ... }:

{
  sops.secrets."tailscale/auth_key" = { };

  services.tailscale = {
    enable = true;
    interfaceName = "tailscale0";
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
    disableTaildrop = true;
    useRoutingFeatures = "both";
  };
}
