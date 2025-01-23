{ config, ... }:

{
  sops.secrets."open-webui/config" = { };

  sops.templates."open-webui/env" = {
    content = ''

    '';
  };

  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    openFirewall = false;
    port = 30120;
    stateDir = "/home/open-webui";
    environment = {
      ENV = "prod";
      WEBUI_NAME = "Open Chat";
      ENABLE_SIGNUP = false;
      ENABLE_REALTIME_CHAT_SAVE = true;
    };
    environmentFile = config.sops.templates."open-webui/env".path;
  };
}
