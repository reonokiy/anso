{ config, ... }:

let
  httpPort = 30060;
  bucketName = "anso-loki";
  s3Endpoint = "s3.eu-central-003.backblazeb2.com";
in
{
  sops.secrets."loki/s3/access_key" = {
    mode = "0440";
    owner = "loki";
    group = "loki";
  };
  sops.secrets."loki/s3/secret_key" = {
    mode = "0440";
    owner = "loki";
    group = "loki";
  };
  sops.templates."loki/config.yaml" = {
    mode = "0440";
    owner = "loki";
    group = "loki";
    content = ''
      auth_enabled: true

      server:
        http_listen_address: 127.0.0.1
        http_listen_port: ${toString httpPort}

      common:
        instance_addr: 127.0.0.1
        path_prefix: /tmp/loki
        replication_factor: 1
        ring:
          kvstore:
            store: inmemory
        storage:
          aws:
            bucketnames: ${bucketName}
            s3forcepathstyle: true
            endpoint: https://${s3Endpoint}
            access_key_id: ${config.sops.placeholder."loki/s3/access_key"}
            secret_access_key: ${config.sops.placeholder."loki/s3/secret_key"}

      storage_config: 
        tsdb_shipper:
          active_index_directory: /tmp/loki/index
          cache_location: /tmp/loki/index_cache
          cache_ttl: 24h

      schema_config:
        configs:
          - from: 2024-01-01
            store: tsdb
            object_store: aws
            schema: v13
            index:
              prefix: index_
              period: 24h

      limits_config:
        max_query_lookback: 744h
        retention_period: 744h

      compactor:
        working_directory: /tmp/loki/compactor
        compaction_interval: 5m

      analytics:
        reporting_enabled: false
    '';
  };

  services.loki = {
    enable = true;
    configFile = config.sops.templates."loki/config.yaml".path;
  };

  services.nginx.virtualHosts."loki.internal.nokiy.net" = {
    enableACME = false;
    useACMEHost = "internal.nokiy.net";
    listen = [
      {
        addr = "100.100.10.2";
        port = 443;
        ssl = true;
      }
    ];
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      extraConfig = ''
        auth_request     /outpost.goauthentik.io/auth/nginx;
        error_page       401 = @goauthentik_proxy_signin;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        add_header       Set-Cookie $auth_cookie;

        auth_request_set $authentik_username $upstream_http_x_authentik_username;
        auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
        auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
        auth_request_set $authentik_email $upstream_http_x_authentik_email;
        auth_request_set $authentik_name $upstream_http_x_authentik_name;
        auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

        proxy_set_header X-authentik-username $authentik_username;
        proxy_set_header X-authentik-groups $authentik_groups;
        proxy_set_header X-authentik-entitlements $authentik_entitlements;
        proxy_set_header X-authentik-email $authentik_email;
        proxy_set_header X-authentik-name $authentik_name;
        proxy_set_header X-authentik-uid $authentik_uid;
        proxy_set_header X-Scope-OrgID $lgtm_org_id;
      '';
    };
    locations."/outpost.goauthentik.io" = {
      proxyPass = "http://localhost:30000/outpost.goauthentik.io";
      extraConfig = ''
        proxy_set_header        X-Forwarded-Host $host; # https://github.com/goauthentik/authentik/issues/2594#issuecomment-1650792385
        proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
        add_header              Set-Cookie $auth_cookie;
        auth_request_set        $auth_cookie $upstream_http_set_cookie;
        proxy_pass_request_body off;
        proxy_set_header        Content-Length "";
      '';
    };
    locations."@goauthentik_proxy_signin" = {
      extraConfig = ''
        internal;
        add_header Set-Cookie $auth_cookie;
        return 302 /outpost.goauthentik.io/start?rd=$request_uri;
      '';
    };
  };

  networking.hosts."100.100.10.2" = [ "loki.internal.nokiy.net" ];
}
