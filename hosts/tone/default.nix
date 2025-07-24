{
  imports = [
    ./configuration.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./software.nix
    ./tailscale.nix
    ./microvm.nix
    ../../share
    ../../share/docker.nix
  ];
}
