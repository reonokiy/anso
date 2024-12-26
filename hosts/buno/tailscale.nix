{
  services.tailscale = {
    enable = true;
    interfaceName = "tailscale0";
    openFirewall = true;
  };
}
