let
  httpPort = 30020;
in

{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.nokiy.net";
      listen-http = "127.0.0.1:${toString httpPort}";
      behind-proxy = true;
    };
  };

  services.nginx.virtualHosts."ntfy.nokiy.net" = {
    enableACME = false;
    useACMEHost = "ntfy.nokiy.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      proxyWebsockets = true;
    };
  };

  networking.hosts."127.0.0.1" = [ "ntfy.nokiy.net" ];
}
