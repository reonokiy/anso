{
  services.tailscale = {
    enable = true;
    interfaceName = "tailscale0";
    openFirewall = true;
    disableTaildrop = true;
    useRoutingFeatures = "both";
  };
}
