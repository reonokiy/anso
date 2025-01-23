let
  port = 30300;
in
{
  imports = [
    ../../../modules/sharkey.nix
  ];

  sops.secrets."sharkey/postgres/password" = { };
  sops.secrets."sharkey/meilisearch/master_key" = { };
  services.anso.sharkey = {
    enable = true;
    postgres.passwordSecret = "sharkey/postgres/password";
    server.url = "https://s.nokiy.net/";
    server.port = port;
  };

  security.acme.certs."s.nokiy.net" = {
    domain = "s.nokiy.net";
  };

  services.nginx.virtualHosts."s.nokiy.net" = {
    enableACME = false;
    useACMEHost = "s.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
