{
  config,
  pkgs,
  lib,
  ...
}:

let
  port = 30110;
  image = "dock.mau.dev/mautrix/telegram:v0.15.2";
  postgresImage = "mirror.gcr.io/library/postgres:16.6-bookworm";
in
{
  sops.secrets."mautrix-telegram/appservice/as_token" = { };
  sops.secrets."mautrix-telegram/appservice/hs_token" = { };
  sops.secrets."mautrix-telegram/appservice/sender_localpart" = { };
  sops.secrets."mautrix-telegram/telegram/api_id" = { };
  sops.secrets."mautrix-telegram/telegram/api_hash" = { };
  sops.secrets."mautrix-telegram/postgres/password" = { };

  users.users.mautrix-telegram = {
    isSystemUser = true;
    uid = 30110;
    group = "mautrix-telegram";
  };
  users.groups.mautrix-telegram = {
    gid = 30110;
    members = [ "matrix-synapse" ];
  };

  systemd.tmpfiles.settings."mautrix-telegram-data" = {
    "/data/mautrix-telegram/data" = {
      d = {
        mode = "0750";
        user = "mautrix-telegram";
        group = "mautrix-telegram";
      };
    };
    "/data/mautrix-telegram/postgres" = {
      d = {
        mode = "0750";
        user = "mautrix-telegram";
        group = "mautrix-telegram";
      };
    };
  };

  sops.templates."mautrix-telegram/config.yaml" = {
    owner = "mautrix-telegram";
    group = "mautrix-telegram";
    mode = "0440";
    content = ''
      homeserver:
        address: https://synapse.nokiy.net
        domain: nokiy.net
        verify_ssl: true
        software: standard
      telegram:
        api_id: ${config.sops.placeholder."mautrix-telegram/telegram/api_id"}
        api_hash: ${config.sops.placeholder."mautrix-telegram/telegram/api_hash"}
      appservice:
        database: postgres://mautrix-telegram:${
          config.sops.placeholder."mautrix-telegram/postgres/password"
        }@postgres/mautrix-telegram
        address: http://localhost:${toString port}
        tls_cert: false
        tls_key: false
        hostname: 127.0.0.1
        port: ${toString port}
        public:
          enabled: false
          prefix: /public
          external: https://mautrix-telegram.internal.nokiy.net/public
        provisioning:
          enabled: false
        id: mautrix-telegram
        bot_username: telegram
        bot_displayname: Telegram Bot
        bot_avatar: mxc://nokiy.net/telegram
        ephemeral_events: true
        as_token: ${config.sops.placeholder."mautrix-telegram/appservice/as_token"}
        hs_token: ${config.sops.placeholder."mautrix-telegram/appservice/hs_token"}
      metrics:
        enabled: false
      manhole:
        enabled: false
      bridge:
        username_template: "telegram_{userid}"
        alias_template: "telegram_{groupname}"
        displayname_template: "{displayname} (Telegram)"
        displayname_preference:
          - full name
          - username
          - phone number
        displayname_max_length: 100
        allow_avatar_remove: true
        allow_contact_info: true
        max_initial_member_sync: 100
        max_member_count: -1
        sync_channel_members: false
        skip_deleted_members: true
        startup_sync: true
        permissions:
          "*": relaybot
          "nokiy.net": full
          "@reonokiy:nokiy.net": admin
    '';
  };

  services.matrix-synapse.settings.app_service_config_files = [
    "/data/mautrix-telegram/data/registration.yaml"
  ];

  sops.templates."mautrix-telegram/postgres.env" = {
    content = ''
      POSTGRES_DB=mautrix-telegram
      POSTGRES_USER=mautrix-telegram
      POSTGRES_PASSWORD=${config.sops.placeholder."mautrix-telegram/postgres/password"}
    '';
    mode = "0440";
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  virtualisation.oci-containers.containers."mautrix-telegram-postgres" = {
    image = postgresImage;
    environmentFiles = [ config.sops.templates."mautrix-telegram/postgres.env".path ];
    volumes = [
      "/data/mautrix-telegram/postgres:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=pg_isready -U mautrix-telegram"
      "--health-interval=10s"
      "--health-retries=5"
      "--health-timeout=5s"
      "--network-alias=postgres"
      "--network=mautrix-telegram"
      "-u=${toString config.users.users.mautrix-telegram.uid}:${toString config.users.groups.mautrix-telegram.gid}"
    ];
  };

  virtualisation.oci-containers.containers."mautrix-telegram" = {
    image = image;
    volumes = [
      "/data/mautrix-telegram/data:/data:rw"
    ];
    ports = [
      "127.0.0.1:${toString port}:${toString port}"
    ];
    dependsOn = [
      "mautrix-telegram-postgres"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network=mautrix-telegram"
      "--uidmap=1337:${toString config.users.users.mautrix-telegram.uid}:1"
      "--gidmap=1337:${toString config.users.groups.mautrix-telegram.gid}:1"
      "--uidmap=0:100000:1000"
      "--gidmap=0:100000:1000"
      "--no-hosts"
    ];
  };

  systemd.services."podman-network-mautrix-telegram" = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create mautrix-telegram";
      ExecStop = "${pkgs.podman}/bin/podman network rm -f mautrix-telegram";
    };
    partOf = [ "mautrix-telegram.target" ];
    wantedBy = [ "mautrix-telegram.target" ];
  };

  systemd.services."podman-mautrix-telegram-postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-mautrix-telegram.service"
    ];
    requires = [
      "podman-network-mautrix-telegram.service"
    ];
    partOf = [
      "mautrix-telegram.target"
    ];
    wantedBy = [
      "mautrix-telegram.target"
    ];
  };

  systemd.services."podman-mautrix-telegram" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-mautrix-telegram.service"
    ];
    requires = [
      "podman-network-mautrix-telegram.service"
    ];
    partOf = [
      "mautrix-telegram.target"
    ];
    wantedBy = [
      "mautrix-telegram.target"
    ];
  };

  systemd.targets."mautrix-telegram" = {
    unitConfig = {
      Description = "Mautrix Telegram Service";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
