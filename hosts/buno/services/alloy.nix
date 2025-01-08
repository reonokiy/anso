{ config, ... }:

let
  lokiPort = 30060;
in
{
  users.users.alloy = {
    isSystemUser = true;
    group = "alloy";
  };
  users.groups.alloy = { };

  sops.templates."alloy/config.yaml" = {
    mode = "0440";
    owner = "alloy";
    group = "alloy";
    content = ''
      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.source.journal "read"  {
        forward_to    = [loki.write.endpoint.receiver]
        relabel_rules = loki.relabel.journal.rules
        labels        = {component = "loki.source.journal"}
      }

      loki.write "endpoint" {
        endpoint {
          url ="http://127.0.0.1:${toString lokiPort}/loki/api/v1/push"
        }
      }
    '';
  };
  services.alloy = {
    enable = true;
    configPath = config.sops.templates."alloy/config.yaml".path;
  };
  systemd.services.alloy.serviceConfig = {
    User = "alloy";
  };
}
