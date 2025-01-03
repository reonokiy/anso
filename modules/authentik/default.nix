{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.anso.authentik;
in
{
  options.services.anso.authentik = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    service = {
      name = mkOption {
        type = types.str;
        default = "authentik";
      };
    };
    postgres = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/library/postgres:16.6-bookworm";
      };
      db = mkOption {
        type = types.str;
        default = "authentik";
      };
      user = mkOption {
        type = types.str;
        default = "authentik";
      };
      passwordSecret = mkOption {
        type = types.str;
        default = "authentik/postgres/password";
      };
    };
    valkey = {
      image = mkOption {
        type = types.str;
        default = "mirror.gcr.io/valkey/valkey:8.0.1-bookworm";
      };
    };
    server = {
      image = mkOption {
        type = types.str;
        default = "ghcr.io/goauthentik/server:2024.12.1";
      };
      env = mkOption {
        type = types.str;
        default = "";
      };
      httpPort = mkOption {
        type = types.int;
        default = 30000;
      };
      httpsPort = mkOption {
        type = types.int;
        default = 30001;
      };
    };
    user = {
      name = mkOption {
        type = types.str;
        default = "authentik";
      };
      uid = mkOption {
        type = types.int;
        default = 30000;
      };
    };
    group = {
      name = mkOption {
        type = types.str;
        default = "authentik";
      };
      gid = mkOption {
        type = types.int;
        default = 30001;
      };
    };
  };

  imports = [
    (import ./postgres.nix {
      inherit
        config
        lib
        pkgs
        cfg
        ;
    })
    (import ./server.nix {
      inherit
        config
        lib
        pkgs
        cfg
        ;
    })
    (import ./users.nix {
      inherit
        config
        lib
        pkgs
        cfg
        ;
    })
    (import ./valkey.nix {
      inherit
        config
        lib
        pkgs
        cfg
        ;
    })
    (import ./worker.nix {
      inherit
        config
        lib
        pkgs
        cfg
        ;
    })
  ];
}
