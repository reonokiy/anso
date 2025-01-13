{ config, ... }:

let
  port = 30060;
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
      auth_enabled: false

      server:
        http_listen_address: 127.0.0.1
        http_listen_port: ${toString port}

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

  networking.hosts."127.0.0.1" = [ "loki.nokiy.net" ];
}
