{
  config,
  pkgs,
  ...
}:

let
  port = 30050;
  domain = "vault.nokiy.net";
in
{
  sops.secrets."vault/s3/access_key" = { };
  sops.secrets."vault/s3/secret_key" = { };
  sops.secrets."vault/s3/bucket" = { };
  sops.secrets."vault/s3/region" = { };

  sops.templates."vault/storage.hcl" = {
    mode = "0440";
    owner = "vault";
    content = ''
      storage "s3" {
        bucket = "${config.sops.placeholder."vault/s3/bucket"}"
        region = "${config.sops.placeholder."vault/s3/region"}"
        access_key = "${config.sops.placeholder."vault/s3/access_key"}"
        secret_key = "${config.sops.placeholder."vault/s3/secret_key"}"
      }
    '';
  };

  users.users.vault.extraGroups = [ "acme" ];
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "127.0.0.1:${toString port}";
    storageBackend = "s3";
    tlsCertFile = "${config.security.acme.certs.${domain}.directory}/full.pem";
    tlsKeyFile = "${config.security.acme.certs.${domain}.directory}/key.pem";
    listenerExtraConfig = ''
      tls_min_version = "tls12"
    '';
    extraConfig = ''
      api_addr = "https://vault.nokiy.net"
      ui = true
      disable_mlock = true
    '';
    extraSettingsPaths = [
      config.sops.templates."vault/storage.hcl".path
    ];
  };

  services.nginx.virtualHosts."vault.nokiy.net" = {
    enableACME = false;
    useACMEHost = "vault.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
