{ config, ... }:

{
  sops.secrets."mautrix-telegram/as_token" = { };
  sops.secrets."mautrix-telegram/hs_token" = { };
  sops.secrets."mautrix-telegram/telegram/api_id" = { };
  sops.secrets."mautrix-telegram/telegram/api_hash" = { };
  sops.secrets."mautrix-telegram/telegram/bot_token" = { };
  sops.secrets."mautrix-telegram/postgres/password" = { };

  sops.templates."mautrix-telegram.env" =
    let
      databaseStr = "postgres://mautrix-telegram:${
        config.sops.secrets."mautrix-telegram/postgres/password"
      }@localhost/mautrix_telegram";
    in
    {
      content = ''
        MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placholders."mautrix-telegram/as_token"}
        MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placholders."mautrix-telegram/hs_token"}
        MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placholders."mautrix-telegram/telegram/api_id"}
        MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placholders."mautrix-telegram/telegram/api_hash"}
        MAUTRIX_TELEGRAM_TELEGRAM_BOT_TOKEN=${config.sops.placholders."mautrix-telegram/telegram/bot_token"}
        MAUTRIX_TELEGRAM_APPSERVICE_DATABASE=${databaseStr}
      '';
    };

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.templates."mautrix-telegram.env".path;
    settings = {
      homeserver = {
        address = "https://synapse.nokiy.net";
        domain = "nokiy.net";
        verify_ssl = true;
        software = "standard";
      };
      appservice = {
        address = "http://localhost:29317";
        tls_cert = false;
        tls_key = false;
        hostname = "127.0.0.1";
        port = 29317;
        database = "postgres://username:password@localhost/mautrix_telegram";
        public = {
          enabled = true;
          prefix = "/public";
          external = "https://mautrix-telegram.internal.nokiy.net/public";
        };
        provisioning.enabled = false;
        id = "telegram";
        bot_username = "telegram";
        bot_display_name = "Telegram Bridge";
        bot_avatar = "mxc://nokiy.net/telegram";
        ephemeral_events = true;
      };
      metrics.enabled = false;
      manhole.enabled = false;
      bridge = {
        username_template = "telegram_{userid}";
        alias_template = "telegram_{groupname}";
        displayname_template = "{displayname} (Telegram)";
        displayname_preference = [
          "full name"
          "username"
          "phone number"
        ];
        displayname_max_length = 100;
        allow_avatar_remove = true;
        allow_contact_info = true;
        max_initial_member_sync = 100;
        max_member_count = -1;
        sync_channel_members = false;
        skip_deleted_members = true;
        startup_sync = true;
      };
      permissions = {
        "*" = "relaybot";
        "nokiy.net" = "full";
        "@reonokiy:nokiy.net" = "admin";
      };
    };
  };
}
