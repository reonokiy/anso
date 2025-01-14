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
    extraUpFlags = [
      "--advertise-routes=10.41.0.0/16,10.42.0.0/16,10.43.0.0/16"
    ];
  };
}
