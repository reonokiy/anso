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

      prometheus.exporter.unix "buno" { 
          enabled_collectors = ["cpu"]
      }

      prometheus.scrape "buno_scraper" {
        scrape_interval = "1s"
        scrape_timeout = "1s"
        targets    = prometheus.exporter.unix.buno.targets
        forward_to = [prometheus.relabel.set_instance_to_hostname.receiver]
      }

      prometheus.relabel "set_instance_to_hostname" {
        forward_to = [prometheus.remote_write.default.receiver]
        
        rule {
          action        = "replace"
          source_labels = ["instance"]
          replacement = constants.hostname
          target_label = "instance"
        }
      }

      prometheus.remote_write "default" {
        endpoint {
          url = "http://localhost:30080/api/v1/write" //Prometheus
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
