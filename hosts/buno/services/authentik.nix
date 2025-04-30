{ config, machine, ... }:

let
  httpPort = 30000;
  httpsPort = 30001;
in
{
  imports = [
    ../../../modules/authentik
  ];

  sops.secrets."authentik/postgres/password" = { };
  sops.secrets."authentik/secret_key" = { };

  services.anso.authentik = {
    enable = true;
    postgres.passwordSecret = "authentik/postgres/password";
    server.env = ''
      AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secret_key"}
      AUTHENTIK_ERROR_REPORTING__ENABLED=true
      # SMTP Host Emails are sent to
      AUTHENTIK_EMAIL__HOST=smtp.tem.scw.cloud
      AUTHENTIK_EMAIL__PORT=587
      # Optionally authenticate (don't add quotation marks to your password)
      AUTHENTIK_EMAIL__USERNAME=${config.sops.placeholder."smtp/username"}
      AUTHENTIK_EMAIL__PASSWORD=${config.sops.placeholder."smtp/password"}
      AUTHENTIK_EMAIL__USE_TLS=true
      AUTHENTIK_EMAIL__FROM=authentik@noreply.nokiy.net
    '';
    server.httpPort = httpPort;
    server.httpsPort = httpsPort;
  };

  services.nginx.virtualHosts."auth.internal.nokiy.net" = {
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

  services.nginx.virtualHosts."auth.nokiy.net" = {
    enableACME = false;
    useACMEHost = "auth.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      proxyWebsockets = true;
    };
  };
}
