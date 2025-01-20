{ config, ... }:

let
  httpPort = 30080;
  grpcPort = 30081;
in
{
  sops.secrets."mimir/s3/blocks/access_key" = { };
  sops.secrets."mimir/s3/blocks/secret_key" = { };
  sops.secrets."mimir/s3/alertmanager/access_key" = { };
  sops.secrets."mimir/s3/alertmanager/secret_key" = { };
  sops.secrets."mimir/s3/ruler/access_key" = { };
  sops.secrets."mimir/s3/ruler/secret_key" = { };

  users.users.mimir = {
    isSystemUser = true;
    group = "mimir";
  };
  users.groups.mimir = { };
  systemd.services.mimir.serviceConfig.User = "mimir";

  sops.templates."mimir/config.yaml" = {
    mode = "0400";
    owner = "mimir";
    group = "mimir";
    content = ''
      multitenancy_enabled: false

      common:
        storage:
          backend: s3
          s3:
            region: eu-central-003
            endpoint: s3.eu-central-003.backblazeb2.com

      blocks_storage:
        s3:
          bucket_name: anso-mimir-blocks
          access_key_id: ${config.sops.placeholder."mimir/s3/blocks/access_key"}
          secret_access_key: ${config.sops.placeholder."mimir/s3/blocks/secret_key"}

      alertmanager_storage:
        s3:
          bucket_name: anso-mimir-alertmanager
          access_key_id: ${config.sops.placeholder."mimir/s3/alertmanager/access_key"}
          secret_access_key: ${config.sops.placeholder."mimir/s3/alertmanager/secret_key"}

      ruler_storage:
        s3:
          bucket_name: anso-mimir-ruler
          access_key_id: ${config.sops.placeholder."mimir/s3/ruler/access_key"}
          secret_access_key: ${config.sops.placeholder."mimir/s3/ruler/secret_key"}

      compactor:
        sharding_ring:
          kvstore:
            store: memberlist

      distributor:
        ring:
          instance_addr: 127.0.0.1
          kvstore:
            store: memberlist

      ingester:
        ring:
          instance_addr: 127.0.0.1
          kvstore:
            store: memberlist
          replication_factor: 1

      server:
        http_listen_address: 127.0.0.1
        http_listen_port: ${toString httpPort}
        grpc_listen_address: 127.0.0.1
        grpc_listen_port: ${toString grpcPort}
        log_level: info

      store_gateway:
        sharding_ring:
          replication_factor: 1

      limits:
        compactor_blocks_retention_period: 1y

      usage_stats:
        enabled: false
    '';
  };

  services.mimir = {
    enable = true;
    configFile = config.sops.templates."mimir/config.yaml".path;
  };

  services.nginx.virtualHosts."mimir.internal.nokiy.net" = {
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
        # proxy_set_header X-Scope-OrgID $lgtm_org_id;
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

  networking.hosts."100.100.10.2" = [ "mimir.internal.nokiy.net" ];
}
