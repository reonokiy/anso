{
  imports = [
    ./services
    ./configuration.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nginx.nix
    ./sops.nix
    ./tailscale.nix
    ../../share
  ];
}
