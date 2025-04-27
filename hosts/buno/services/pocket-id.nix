{ inputs, pkgs-unstable, ... }:

{
  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/security/pocket-id.nix")
  ];

  services.pocket-id = {
    enable = true;
    package = pkgs-unstable.pocket-id;
    dataDir = "/data/pocket-id";
    settings = {
      PUBLIC_APP_URL = "https://id.nokiy.net";
      INTERNAL_BACKEND_URL = "http://127.0.0.1:30141";
      TRUST_PROXY = true;
      PORT = 30140;
      BACKEND_PORT = 30141;
      HOST = "127.0.0.1";
    };
  };

  security.acme.certs."id.nokiy.net" = {
    domain = "id.nokiy.net";
  };

  services.nginx.virtualHosts."id.nokiy.net" = {
    enableACME = false;
    useACMEHost = "id.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:30140";
      proxyWebsockets = true;
      # extraConfig = ''
      #   proxy_set_header Authorization $http_authorization;
      #   proxy_pass_header Authorization;
      # '';
    };
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:30141";
    };
    locations."/.well-known/" = {
      proxyPass = "http://127.0.0.1:30141";
    };
  };
}

