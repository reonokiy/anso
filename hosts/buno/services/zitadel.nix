{ config, ... }:

let
  port = 30120;
in
{
  sops.secrets."zitadel/master_key" = {
    mode = "0400";
    owner = "zitadel";
    group = "zitadel";
  };
  users.users.zitadel.extraGroups = [ "acme" ];
  services.zitadel = {
    enable = true;
    user = "zitadel";
    group = "zitadel";
    tlsMode = "enabled";
    masterKeyFile = config.sops.secrets."zitadel/master_key".path;
    openFirewall = false;
    settings = {
      Port = port;
      TLS.enabled = true;
      TLS.KeyPath = "${config.security.acme.certs."sso.nokiy.net".directory}/key.pem";
      TLS.CertPath = "${config.security.acme.certs."sso.nokiy.net".directory}/full.pem";
      ExternalDomain = "sso.nokiy.net";
      ExternalPort = 443;
      ExternalSecure = true;
      Database.postgres = {
        Host = "/var/run/postgresql/";
        Port = 5432;
        Database = "zitadel";
        User = {
          Username = "zitadel";
          SSL.Mode = "disable";
        };
        Admin = {
          Username = "zitadel";
          SSL.Mode = "disable";
          ExistingDatabase = "zitadel";
        };
      };
      steps.FirstInstance = {
        InstanceName = "sso.nokiy.net";
        Org = {
          Name = "Default";
          Human = {
            UserName = "reonokiy";
            FirstName = "reo";
            LastName = "nokiy";
            Email = {
              Address = "reonokiy@gmail.com";
              Verified = true;
            };
            Password = "reo_#@Password123!";
            PasswordChangeRequired = true;
          };
        };
        LoginPolicy.AllowRegister = false;
      };
    };
  };

  security.acme.certs."sso.nokiy.net" = {
    domain = "sso.nokiy.net";
  };

  services.nginx.virtualHosts."sso.nokiy.net" = {
    enableACME = false;
    useACMEHost = "sso.nokiy.net";
    forceSSL = true;
    http2 = true;
    locations."/" = {
      extraConfig = ''
        grpc_pass grpcs://127.0.0.1:${toString port};
        grpc_set_header Host $host;
      '';
    };
  };

  # networking.hosts."127.0.0.1" = [ "sso.nokiy.net" ];
}
