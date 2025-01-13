{ config, ... }:

{
  sops.secrets."grafana/oauth/client_id" = {
    mode = "0440";
    owner = "grafana";
  };
  sops.secrets."grafana/oauth/client_secret" = {
    mode = "0440";
    owner = "grafana";
  };

  users.users.grafana.extraGroups = [ "smtp" ];
  users.users.nginx.extraGroups = [ "grafana" ];

  systemd.tmpfiles.settings."grafana-data" = {
    "/data/grafana/data" = {
      d = {
        mode = "0740";
        user = "grafana";
        group = "grafana";
      };
    };
  };
  systemd.tmpfiles.settings."grafana-run" = {
    "/run/grafana" = {
      d = {
        mode = "0770";
        user = "grafana";
        group = "grafana";
      };
    };
  };

  services.grafana = {
    enable = true;
    dataDir = "/data/grafana/data";
    settings = {
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = "grafana";
        user = "grafana";
      };
      stmp = {
        fromAddr = "grafana@noreply.nokiy.net";
        host = "smtp.tem.scw.cloud:587";
        startTLS_policy = "OpportunisticStartTLS";
        user = "$__file{${config.sops.secrets."smtp/username".path}}";
        password = "$__file{${config.sops.secrets."smtp/password".path}}";
      };
      server = {
        root_url = "https://grafana.internal.nokiy.net";
        protocol = "socket";
        socket = "/run/grafana/grafana.sock";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "Nokiy Auth";
        allow_sign_up = true;
        auto_login = true;
        scopes = "openid profile email";
        use_pkce = true;
        use_refresh_token = true;
        client_id = "$__file{${config.sops.secrets."grafana/oauth/client_id".path}}";
        client_secret = "$__file{${config.sops.secrets."grafana/oauth/client_secret".path}}";
        auth_url = "https://auth.nokiy.net/application/o/authorize/";
        api_url = "https://auth.nokiy.net/application/o/userinfo/";
        token_url = "https://auth.nokiy.net/application/o/token/";
        signout_redirect_url = "https://auth.nokiy.net/application/o/granafa/end-session/";
        role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
        allow_assign_grafana_admin = true;
      };
    };
  };

  services.nginx.virtualHosts."grafana.internal.nokiy.net" = {
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
      proxyPass = "http://unix:/run/grafana/grafana.sock";
      proxyWebsockets = true;
    };
  };

  networking.hosts."127.0.0.1" = [ "grafana.nokiy.net" ];
  networking.hosts."100.100.10.2" = [ "grafana.internal.nokiy.net" ];
}
