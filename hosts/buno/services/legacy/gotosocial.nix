{
  config,
  lib,
  pkgs,
  sops-nix,
  ts,
  ...
}:

let
  gotosocialImage = "mirror.gcr.io/superseriousbusiness/gotosocial:0.17.3";
  gotosocialThemeRainbowLight = builtins.readFile ./gotosocial/rainbow-light.css;
  uid = 985;
  gid = 980;
in
{
  sops.secrets."gotosocial/storage/access_key" = { };
  sops.secrets."gotosocial/storage/secret_key" = { };
  # sops.secrets."gotosocial/smtp/password" = { };
  sops.secrets."gotosocial/oidc/client_secret" = { };

  users.users.gotosocial = {
    isSystemUser = true;
    group = "gotosocial";
  };
  users.groups.gotosocial = { };

  sops.templates."gotosocial.env" = {
    owner = "gotosocial";
    group = "gotosocial";
    mode = "0600";
    content = ''
      GTS_ACCOUNTS_ALLOW_CUSTOM_CSS=true
      GTS_DB_TYPE=sqlite
      GTS_DB_ADDRESS=/gotosocial/db/sqlite.db
      GTS_HOST=gts.ree.ink
      GTS_INSTANCE_LANGUAGES=zh,en
      GTS_PORT=8080
      GTS_STORAGE_BACKEND=s3
      GTS_STORAGE_S3_BUCKET=gts-of-reeink
      GTS_STORAGE_S3_ENDPOINT=s3.eu-central-003.backblazeb2.com
      GTS_STORAGE_S3_ACCESS_KEY=${config.sops.placeholder."gotosocial/storage/access_key"}
      GTS_STORAGE_S3_SECRET_KEY=${config.sops.placeholder."gotosocial/storage/secret_key"}
      GTS_OIDC_ENABLED=true
      GTS_OIDC_IDP_NAME="YI0 SSO"
      GTS_OIDC_ISSUER=https://idm.yi0.org/oauth2/openid/gotosocial
      GTS_OIDC_CLIENT_ID=gotosocial
      GTS_OIDC_CLIENT_SECRET=${config.sops.placeholder."gotosocial/oidc/client_secret"}
      GTS_OIDC_SCOPES=openid,email,profile,groups
      GTS_OIDC_LINK_EXISTING=false
      GTS_OIDC_ALLOWED_GROUPS=gotosocial-user@idm.yi0.org,gotosocial-admin@idm.yi0.org
      GTS_OIDC_ADMIN_GROUPS=gotosocial-admin@idm.yi0.org
    '';
  };

  systemd.tmpfiles.settings."gotosocial-data" = {
    "/data/gotosocial" = {
      d = {
        group = "services";
        mode = "0771";
        user = "gotosocial";
      };
    };
    "/data/gotosocial/db" = {
      d = {
        group = "services";
        mode = "0771";
        user = "gotosocial";
      };
    };
    "/data/gotosocial/theme" = {
      d = {
        group = "services";
        mode = "0771";
        user = "gotosocial";
      };
    };
    "/data/gotosocial/theme/rainbow-light.css" = {
      f = {
        argument = gotosocialThemeRainbowLight;
        user = "gotosocial";
        group = "gotosocial";
        mode = "0640";
      };
    };
  };

  virtualisation.oci-containers.containers.gotosocial = {
    image = gotosocialImage;
    ports = [ "127.0.0.1:30090:8080" ];
    environmentFiles = [ config.sops.templates."gotosocial.env".path ];
    volumes = [
      "/data/gotosocial/db:/gotosocial/db"
      "/data/gotosocial/theme/rainbow-light.css:/gotosocial/web/assets/themes/rainbow-light.css"
    ];
    extraOptions = [
      "--memory=512m"
      "--memory-swap=1024m"
      "-u=${toString uid}:${toString gid}"
    ];
  };

  services.nginx.virtualHosts."gts.ree.ink" = {
    enableACME = false;
    useACMEHost = "gts.ree.ink";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:30090";
      proxyWebsockets = true;
    };
  };

  networking.hosts."127.0.0.1" = [ "gts.ree.ink" ];
  networking.hosts."100.100.10.2" = [ "gts.ree.ink" ];
}
