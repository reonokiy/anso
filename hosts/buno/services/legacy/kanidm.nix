let
  kanidmImage = "mirror.gcr.io/kanidm/server:1.3.3";
  kandiConfig = builtins.readFile ./kanidm/config.toml;
  uid = 984;
  gid = 979;
in
{
  users.users.kanidm = {
    isSystemUser = true;
    group = "kanidm";
  };
  users.groups.kanidm = {
    members = [
      "nginx"
      "acme"
    ];
  };

  systemd.tmpfiles.settings."kanidm-data" = {
    "/data/kanidm" = {
      d = {
        mode = "0771";
        user = "kanidm";
        group = "kanidm";
      };
    };
    "/data/kanidm/db" = {
      d = {
        mode = "0771";
        user = "kanidm";
        group = "kanidm";
      };
    };
    "/data/kanidm/backups" = {
      d = {
        mode = "0771";
        user = "kanidm";
        group = "kanidm";
      };
    };
    "/data/kanidm/server.toml" = {
      f = {
        mode = "0440";
        user = "kanidm";
        group = "kanidm";
        argument = kandiConfig;
      };
    };
  };

  virtualisation.oci-containers.containers.kanidm = {
    image = kanidmImage;
    ports = [ "127.0.0.1:30100:8443" ];
    volumes = [
      "/data/kanidm/server.toml:/data/server.toml"
      "/data/kanidm/db:/data/db"
      "/data/kanidm/backups:/data/kanidm/backups"
      "/var/lib/acme/idm.yi0.org:/data/certs"
    ];
    extraOptions = [
      "--memory=256m"
      "--memory-swap=512m"
      "-u=${toString uid}:${toString gid}"
    ];
  };

  security.acme.certs."idm.yi0.org" = {
    domain = "idm.yi0.org";
    group = "kanidm";
  };

  services.nginx.virtualHosts."idm.yi0.org" = {
    enableACME = false;
    useACMEHost = "idm.yi0.org";
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://127.0.0.1:30100";
      proxyWebsockets = true;
    };
  };

  networking.hosts."127.0.0.1" = [ "idm.yi0.org" ];
  networking.hosts."100.100.10.2" = [ "idm.yi0.org" ];
}
