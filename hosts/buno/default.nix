{
  imports = [
    ./configuration.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./mosh.nix
    ./networking.nix
    ./nginx.nix
    ./sops.nix
    ./tailscale.nix
    ../../share
    ./services
  ];
}
