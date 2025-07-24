{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wget
    curl
    aria2
    git
    git-lfs
  ];
}
