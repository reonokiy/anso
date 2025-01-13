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
      multitenancy_enabled: true

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
}
