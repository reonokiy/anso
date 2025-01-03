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
    useACMEHost = "nokiy.net";
    forceSSL = true;
    listen = [
      {
        addr = "100.100.10.2";
        port = 443;
        ssl = true;
      }
      {
        addr = machine.interfaces.eth0.ipv4.address;
        port = 443;
        ssl = true;
      }
      {
        addr = "[${machine.interfaces.eth0.ipv6.address}]";
        port = 443;
        ssl = true;
      }
    ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      proxyWebsockets = true;
    };
  };
}
