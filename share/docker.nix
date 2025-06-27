{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
