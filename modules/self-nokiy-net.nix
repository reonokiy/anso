{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.anso.self-nokiy-net;
  self = inputs.compose + "/self";
in

{
  options.services.anso.self-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    containers.selfn = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.9";
      localAddress = "10.43.0.9";
      hostAddress6 = "fd00::10.42.0.9";
      localAddress6 = "fd00::10.43.0.9";
      bindMounts = {
        "data" = {
          hostPath = "/data/self-nokiy-net";
          mountPoint = "/data";
          isReadOnly = false;
        };
      };
      ephemeral = true;
      extraFlags = [
        "--system-call-filter=@keyring"
        "--system-call-filter=bpf"
        "--system-call-filter=@network-io"
        "--system-call-filter=@basic-io"
        "--system-call-filter=@io-event"
        "--system-call-filter=@ipc"
        "--system-call-filter=@process"
        "--system-call-filter=@signal"
        "--system-call-filter=@timer"
        "--system-call-filter=@file-system"
      ];
      config =
        { lib, pkgs, ... }:
        {
          system.stateVersion = "25.05";
          networking.nameservers = [ "1.1.1.1" ];
          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ ];
            allowedUDPPorts = [ ];
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          environment.etc."self-nokiy-net/docker-compose.yaml".source = self + "/docker-compose.yaml";

          systemd.services."self" = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            environment = {
              DATA_DIR = "/data";
            };
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/self-nokiy-net/docker-compose.yaml up";
            serviceConfig = {
              Restart = "always";
              RestartSec = "30s";
            };
          };
        };
    };
  };
}
