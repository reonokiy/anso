{ config, ... }:

let port = 30130;
in {
  sops.secrets."nocodb/access_key" = { };
  sops.secrets."nocodb/secret_key" = { };
  sops.templates."nocodb.env" = {
    content = ''
      NC_S3_ACCESS_KEY=${config.sops.placeholder."nocodb/access_key"}
      NC_S3_SECRET_KEY=${config.sops.placeholder."nocodb/secret_key"}
    '';
  };

  services.nocodb = {
    enable = true;
    environment = {
      DB_URL = "postgres:///nocodb?host=/run/postgresql";
      PORT = toString port;
      NC_S3_BUCKET_NAME = "noco-nokiy-net";
      NC_S3_REGION = "eu-central-003";
      NC_S3_ENDPOINT = "s3.eu-central-003.backblazeb2.com";
      NC_S3_FORCE_PATH_STYLE = "true";
      NC_PUBLIC_URL = "https://noco.nokiy.net";
      NC_DISABLE_TELE = "true";
    };
    environmentFile = config.sops.templates."nocodb.env".path;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nocodb" ];
    ensureUsers = [{
      name = "nocodb";
      ensureDBOwnership = true;
    }];
  };

  security.acme.certs."noco.nokiy.net" = {
    domain = "noco.nokiy.net";
    extraDomainNames = [ "noco.internal.nokiy.net" ];
  };

  services.nginx.virtualHosts."noco.nokiy.net" = {
    enableACME = false;
    useACMEHost = "noco.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
