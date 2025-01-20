{
  config,
  machine,
  pkgs,
  ...
}:

let
  httpPort = 30010;
  maxBodySize = "200M";
  clientConfig."m.homeserver".base_url = "https://synapse.nokiy.net";
  clientConfig."m.identity_server".base_url = "https://vector.im";
  serverConfig."m.server" = "synapse.nokiy.net:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  sops.secrets."synapse/postgres/password" = { };
  sops.secrets."synapse/oidc/client_id" = { };
  sops.secrets."synapse/oidc/client_secret" = { };
  sops.secrets."synapse/sso/client_id" = { };
  sops.secrets."synapse/sso/client_secret" = { };
  sops.secrets."synapse/s3/access_key" = { };
  sops.secrets."synapse/s3/secret_key" = { };
  sops.secrets."synapse/turn/secret" = {
    mode = "0440";
    owner = "turnserver";
    group = "matrix-synapse";
  };
  sops.templates."synapse.yaml" = {
    content = ''
      ## Server Part
      server_name: nokiy.net
      web_client_location: https://element.nokiy.net
      public_baseurl: https://synapse.nokiy.net/
      serve_server_wellknown: true
      ip_range_blacklist:
        - '127.0.0.0/8'
        - '10.0.0.0/8'
        - '172.16.0.0/12'
        - '192.168.0.0/16'
        - '100.64.0.0/10'
        - '192.0.0.0/24'
        - '169.254.0.0/16'
        - '192.88.99.0/24'
        - '198.18.0.0/15'
        - '192.0.2.0/24'
        - '198.51.100.0/24'
        - '203.0.113.0/24'
        - '224.0.0.0/4'
        - '::1/128'
        - 'fe80::/10'
        - 'fc00::/7'
        - '2001:db8::/32'
        - 'ff00::/8'
        - 'fec0::/10'
      listeners:
        - port: ${toString httpPort}
          bind_addresses: 
            - 127.0.0.1
          type: http
          tls: false
          x_forwarded: true
          resources:
            - names: [client, federation]
              compress: false

      ## Database Part
      # database:
      #   name: psycopg2
      #   txn_limit: 10000
      #   args:
      #     user: matrix-synapse
      #     password: ${config.sops.placeholder."synapse/postgres/password"}
      #     dbname: matrix-synapse
      #     host: localhost
      #     port: 5432
      #     cp_min: 5
      #     cp_max: 10

      media_store_path: DATADIR/media_store
      signing_key_path: "CONFDIR/SERVERNAME.signing.key"
      trusted_key_servers:
        - server_name: "matrix.org"

      ## Homeserver Blocking
      admin_contact: 'mailto:admin+synapse@nokiy.net'

      ## TLS
      federation_verify_certificates: true
      federation_client_minimum_tls_version: "1.2"

      ## SSO Part
      oidc_providers:
        - idp_id: nokiy_auth
          idp_name: Nokiy Auth
          discover: true
          issuer: "https://auth.nokiy.net/application/o/synapse/"
          client_id: ${config.sops.placeholder."synapse/oidc/client_id"} 
          client_secret: ${config.sops.placeholder."synapse/oidc/client_secret"}
          scopes:
            - "openid"
            - "profile"
            - "email"
          user_mapping_provider:
            config:
              localpart_template: "{{ user.preferred_username }}"
              display_name_template: "{{ user.preferred_username|capitalize }}"

      ## Storage Backend
      media_storage_providers:
      - module: s3_storage_provider.S3StorageProviderBackend
        store_local: True
        store_remote: True
        store_synchronous: True
        config:
          bucket: nokiy-synapse-media
          endpoint_url: https://s3.eu-central-003.backblazeb2.com
          access_key_id: ${config.sops.placeholder."synapse/s3/access_key"}
          secret_access_key: ${config.sops.placeholder."synapse/s3/secret_key"}
      dynamic_thumbnails: true
      thumbnail_sizes:
        - width: 32
          height: 32
          method: crop
        - width: 96
          height: 96
          method: crop
        - width: 320
          height: 240
          method: scale
        - width: 640
          height: 480
          method: scale
        - width: 800  
          height: 600
          method: scale
      media_retention:
        local_media_lifetime: 1y
        remote_media_lifetime: 14d
      url_preview_enabled: true
      url_preview_ip_range_blacklist:
        - '127.0.0.0/8'
        - '10.0.0.0/8'
        - '172.16.0.0/12'
        - '192.168.0.0/16'
        - '100.64.0.0/10'
        - '192.0.0.0/24'
        - '169.254.0.0/16'
        - '192.88.99.0/24'
        - '198.18.0.0/15'
        - '192.0.2.0/24'
        - '198.51.100.0/24'
        - '203.0.113.0/24'
        - '224.0.0.0/4'
        - '::1/128'
        - 'fe80::/10'
        - 'fc00::/7'
        - '2001:db8::/32'
        - 'ff00::/8'
        - 'fec0::/10'
      url_preview_accept_language:
        - 'zh-CN'
        - 'en-US;q=0.9'
        - 'en-UK;q=0.8'
        - '*;q=0.7'
      oembed:
        disable_default_providers: false
        additional_providers: []

      ## TURN
      turn_uris:
        - turn:turn.nokiy.net:3478?transport=udp
        - turn:turn.nokiy.net:3478?transport=tcp
      turn_shared_secret: ${config.sops.placeholder."synapse/turn/secret"}
      turn_user_lifetime: 1h

      ## Registration
      enable_registration: false
      enable_set_displayname: true

      ## User Session
      session_lifetime: 30d
      refresh_token_lifetime: 24h

      ## Rooms
      encryption_enabled_by_default_for_room_type: "invite"
      user_directory:
        enabled: true
        search_all_users: true
        prefer_local_users: true
        show_locked_users: true
      server_notices:
        system_mxid_localpart: server
        system_mxid_display_name: "Server Notices"
        system_mxid_avatar_url: "mxc://example.com/oumMVlgDnLYFaPVkExemNVVZ"
        room_name: "Server Notices"
        room_avatar_url: "mxc://example.com/oumMVlgDnLYFaPVkExemNVVZ"
        room_topic: "Room used by your server admin to notice you of important information"
        auto_join: true

      # ## Redis
      # redis:
      #   enabled: true
      #   host: localhost
      #   port: 6379

      signing_key_path: "/data/synapse/server/key/homeserver.signing.key"
      pid_file: "/data/synapse/server/homeserver.pid"
      media_store_path: "/data/synapse/server/media_store"

      max_upload_size: ${maxBodySize}

      push:
        enabled: true
        include_content: false
        group_unread_count_by_room: true
        jitter_delay: "3s"


      # ## to enable QR code verification
      # ## https://github.com/matrix-org/synapse/issues/15918#issuecomment-1631439515
      # login_via_existing_session:
      #   enabled: true
      #   require_ui_auth: true
      #   token_timeout: "1m"
      # modules:
      #   - module: matrix_http_rendezvous_synapse.SynapseRendezvousModule
      #     config:
      #       prefix: /_synapse/client/org.matrix.msc3886/rendezvous
      # experimental_features:
      #   msc3886_enabled: true
      #   msc3886_endpoint: /_synapse/client/org.matrix.msc3886/rendezvous
    '';
    mode = "0440";
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  systemd.tmpfiles.settings."matrix-synapse-data" = {
    "/data/synapse/server" = {
      d = {
        mode = "0740";
        user = "matrix-synapse";
        group = "matrix-synapse";
      };
    };
    "/data/synapse/server/key" = {
      d = {
        mode = "0740";
        user = "matrix-synapse";
        group = "matrix-synapse";
      };
    };
  };

  services.matrix-synapse = {
    enable = true;
    dataDir = "/data/synapse/server";
    configureRedisLocally = true;
    extraConfigFiles = [ config.sops.templates."synapse.yaml".path ];
    withJemalloc = true;
    plugins = with config.services.matrix-synapse.package.plugins; [
      matrix-synapse-s3-storage-provider
      # matrix-synapse-mjolnir-antispam
      # matrix-http-rendezvous-synapse
    ];
    extras = [
      "cache-memory" # Provide statistics about caching memory consumption
      "jwt" # JSON Web Token authentication
      "oidc" # OpenID Connect authentication
      "postgres" # PostgreSQL database backend
      "redis" # Redis support for the replication stream between worker processes
      "sentry" # Error tracking and performance metrics
      "systemd" # Provide the JournalHandler used in the default log_config
      "url-preview" # Support for oEmbed URL previews
      "user-search" # Support internationalized domain names in user-search
    ];
  };

  services.nginx.virtualHosts."synapse.nokiy.net" = {
    enableACME = false;
    useACMEHost = "synapse.nokiy.net";
    forceSSL = true;
    locations."~ ^(/_matrix|/_synapse/client)" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        client_max_body_size ${maxBodySize};
      '';
    };
  };

  services.nginx.virtualHosts."element.nokiy.net" = {
    enableACME = false;
    useACMEHost = "element.nokiy.net";
    forceSSL = true;
    locations."/".root = pkgs.element-web.override {
      conf = {
        default_server_config = clientConfig;
        default_server_name = "nokiy.net";
      };
    };
  };
  services.nginx.virtualHosts."nokiy.net" = {
    enableACME = false;
    useACMEHost = "nokiy.net";
    forceSSL = true;
    locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
    locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
  };

  networking.hosts."127.0.0.1" = [
    "element.nokiy.net"
    "synapse.nokiy.net"
  ];
}
