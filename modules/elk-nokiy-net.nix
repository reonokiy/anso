{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.anso.elk-nokiy-net;
in

{
  options.services.anso.elk-nokiy-net = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    image = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs."elk.nokiy.net" = {
      domain = "elk.nokiy.net";
    };

    services.nginx.virtualHosts."elk.nokiy.net" = {
      enableACME = false;
      useACMEHost = "elk.nokiy.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:15314";
        proxyWebsockets = true;
      };
    };

    virtualisation.oci-containers.containers."elk-nokiy-net" = {
      image = cfg.image;
      log-driver = "journald";
      environment = {
        NUXT_STORAGE_DRIVER = "fs";
        NUXT_PUBLIC_DEFAULT_SERVER = "social.nokiy.net";
        NUXT_PUBLIC_SINGLE_INSTANCE = "true";
      };
      ports = [
        "127.0.0.1:15314:5314"
      ];
    };
  };
}
