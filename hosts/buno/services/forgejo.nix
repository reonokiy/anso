{ config, ... }:

let
  httpPort = 30040;
in
{
  sops.secrets."forgejo/s3/access_key" = { };
  sops.secrets."forgejo/s3/secret_key" = { };
  # sops.secrets."forgejo/postgres/password" = { };

  systemd.tmpfiles.settings."forgejo-data" = {
    "/data/forgejo/data" = {
      d = {
        mode = "0740";
        user = "forgejo";
        group = "forgejo";
      };
    };
    "/data/forgejo/backup" = {
      d = {
        mode = "0740";
        user = "forgejo";
        group = "forgejo";
      };
    };
    "/data/forgejo/custom" = {
      d = {
        mode = "0740";
        user = "forgejo";
        group = "forgejo";
      };
    };
  };

  services.forgejo = {
    enable = true;
    stateDir = "/data/forgejo/data";
    customDir = "/data/forgejo/custom";
    database = {
      createDatabase = true;
      name = "forgejo";
      type = "postgres";
      # host = "127.0.0.1";
      socket = "/run/postgresql";
      user = "forgejo";
      # passwordFile = config.sops.secrets."forgejo/postgres/password".path;
    };
    dump = {
      enable = true;
      backupDir = "/data/forgejo/backup";
      interval = "22:00";
      type = "tar.zst";
      file = "forgejo-backup";
    };
    lfs.enable = true;
    secrets = {
      storage = {
        MINIO_ACCESS_KEY_ID = config.sops.secrets."forgejo/s3/access_key".path;
        MINIO_SECRET_ACCESS_KEY = config.sops.secrets."forgejo/s3/secret_key".path;
      };
      mailer = {
        USER = config.sops.secrets."smtp/username".path;
        PASSWD = config.sops.secrets."smtp/password".path;
      };
    };
    settings = {
      server = {
        PROTOCOL = "http";
        DOMAIN = "git.nokiy.net";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = httpPort;
        DISABLE_SSH = true;
        LFS_START_SERVER = true;
        ROOT_URL = "https://git.nokiy.net";
      };
      storage = {
        STORAGE_TYPE = "minio";
        SERVE_DIRECT = true;
        MINIO_ENDPOINT = "s3.eu-central-003.backblazeb2.com";
        MINIO_BUCKET = "nokiy-git";
        MINIO_LOCATION = "eu-central-003";
        MINIO_USE_SSL = true;
        MINIO_CHECKSUM_ALGORITHM = "md5"; # fix backblaze b2 error
      };
      cron = {
        ENABLED = true;
        RUN_AT_START = true;
        NOTICE_ON_SUCCESS = true;
      };
      mailer = {
        ENABLED = true;
        SMTP_ADDR = "smtp.tem.scw.cloud";
        SMTP_PORT = 587;
        PROTOCOL = "smtp+starttls";
        # USER = "git@noreply.nokiy.net";
        FROM = "\"Nokiy Git\" <git@noreply.nokiy.net>";
      };
      service = {
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
      };
      oauth2_client = {
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_AUTO_REGISTRATION = true;
        ACCOUNT_LINKING = "auto";
        USERNAME = "nickname";
        OPENID_CONNECT_SCOPES = "openid profile email";
      };
      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = false;
      };
      indexer = {
        REPO_INDEXER_ENABLED = true;
      };
      git.timeout = 36000;
    };
  };

  services.nginx.virtualHosts."git.internal.nokiy.net" = {
    enableACME = false;
    useACMEHost = "internal.nokiy.net";
    forceSSL = true;
    listen = [
      {
        addr = "100.100.10.2";
        port = 443;
        ssl = true;
      }
    ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."git.nokiy.net" = {
    enableACME = false;
    useACMEHost = "git.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      proxyWebsockets = true;
    };
  };
}
