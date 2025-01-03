{ config, ... }:
{
  services.nginx = {
    enable = true;
    statusPage = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;
    recommendedZstdSettings = true;

    appendHttpConfig = ''
      add_header X-NOKIY-SERVER "${config.networking.hostName}";
    '';
  };
  users.users.nginx.extraGroups = [ "acme" ];

  sops.secrets."cloudflare/api_token" = { };
  sops.templates."cloudflare_dns.env" = {
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/api_token"}
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "glad.plan2474@fastmail.com";
      group = "acme";
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.templates."cloudflare_dns.env".path;
    };

    certs = {
      "nokiy.net" = {
        domain = "*.nokiy.net";
        extraDomainNames = [ "nokiy.net" ];
      };
      "internal.nokiy.net" = {
        domain = "*.internal.nokiy.net";
        extraDomainNames = [ "internal.nokiy.net" ];
      };
    };
  };
}
