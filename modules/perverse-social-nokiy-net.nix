{
  config,
  lib,
  pkgs,
  inputs,

  ...
}:

with lib;

let
  cfg = config.services.anso.perverse-social-nokiy-net;
  perverse = inputs.compose + "/perverse";
in

{
  options.services.anso.perverse-social-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    containers.perverse-social-nokiy-net = {
      autoStart = true;
      privateNetwork = true;
      tmpfs = [
        "/var"
      ];
      hostAddress = "10.42.0.5";
      localAddress = "10.43.0.5";
      hostAddress6 = "fd00::10.42.0.5";
      localAddress6 = "fd00::10.43.0.5";
      bindMounts = {
        "data" = {
          hostPath = "/data/perverse-social-nokiy-net";
          mountPoint = "/data";
          isReadOnly = true;
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
          system.stateVersion = "24.11";
          networking.useHostResolvConf = true;
          networking.firewall = {
            enable = true;
          };

          virtualisation.docker.enable = true;
          virtualisation.docker.daemon.settings.registry-mirrors = [ "https://mirror.gcr.io" ];
          environment.systemPackages = with pkgs; [
            docker-compose
          ];
          boot.tmp.cleanOnBoot = true;

          environment.etc."perverse-social-nokiy-net/docker-compose.yml".source =
            perverse + "/docker-compose.yaml";

          systemd.services."perverse-social-nokiy-net" = {
            wantedBy = [ "multi-user.target" ];
            after = [
              "docker.service"
              "docker.socket"
            ];
            script = "${pkgs.docker-compose}/bin/docker-compose -f /etc/perverse-social-nokiy-net/docker-compose.yml --env-file /data/.env up";
            serviceConfig = {
              Restart = "always";
              RestartSec = "30s";
            };
          };
        };
    };
  };
}
