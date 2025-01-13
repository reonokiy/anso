{ config, ... }:

let
  port = 30070;
in
{
  sops.secrets."oauth2_proxy/client_id" = { };
  sops.secrets."oauth2_proxy/client_secret" = { };
  sops.secrets."oauth2_proxy/cookie_secret" = { };

  sops.templates."oauth2_proxy/config.env" = {
    content = ''
      OAUTH2_PROXY_PROVIDER_DISPLAY_NAME="Nokiy Auth"
      OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder."oauth2_proxy/cookie_secret"}
      OAUTH2_PROXY_CLIENT_ID=${config.sops.placeholder."oauth2_proxy/client_id"}
      OAUTH2_PROXY_CLIENT_SECRET=${config.sops.placeholder."oauth2_proxy/client_secret"}
    '';
  };
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    scope = "openid email profile";
    httpAddress = "127.0.0.1:${toString port}";
    oidcIssuerUrl = "https://auth.nokiy.net/application/o/oauth2-proxy/";
    redirectURL = "https://oauth2-proxy.nokiy.net/oauth2/callback";
    reverseProxy = true;
    email.domains = [ "*" ];
    keyFile = config.sops.templates."oauth2_proxy/config.env".path;
  };

  services.nginx.virtualHosts."oauth2-proxy.nokiy.net" = {
    enableACME = false;
    useACMEHost = "nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
