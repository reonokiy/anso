{ pkgs, lib, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  environment.systemPackages = with pkgs; [
    curl
    htop
  ];

  zramSwap = {
    enable = lib.mkDefault true;
    memoryPercent = lib.mkDefault 100;
  };
}
