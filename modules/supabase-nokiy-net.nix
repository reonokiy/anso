{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.supabase-nokiy-net;
in

{
  options.services.anso.supabase-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    system.stateVersion = "25.05";
    networking.nameservers = [ "1.1.1.1" ];
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
      allowedUDPPorts = [ 80 ];
    };

    containers.supabase = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.42.0.5";
      localAddress = "10.43.0.5";
      hostAddress6 = "fd00::10.42.0.5";
      localAddress6 = "fd00::10.43.0.5";
      bindMounts = {
        "data" = {
          hostPath = "/data/supabase-nokiy-net";
          mountPoint = "/data";
          isReadOnly = false;
        };
      };
      config =
        { lib, ... }:
        {
          virtualisation.docker.enable = true;
          virtualisation.oci-containers.backend = "docker";
          environment.systemPackages = with pkgs; [
            htop
            docker-compose
            supabase-cli
          ];
        };
    };

  };
}
