{
  config,
  lib,
  pkgs,
  ...
}:
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

    commonHttpConfig =
      let
        realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
        fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
        cfipv4 = fileToList (
          pkgs.fetchurl {
            url = "https://www.cloudflare.com/ips-v4";
            sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
          }
        );
        cfipv6 = fileToList (
          pkgs.fetchurl {
            url = "https://www.cloudflare.com/ips-v6";
            sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
          }
        );
      in
      ''
        ${realIpsFromList cfipv4}
        ${realIpsFromList cfipv6}
        real_ip_header CF-Connecting-IP;
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
