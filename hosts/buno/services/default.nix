{
  imports = [
    ./alloy.nix
    ./authentik.nix
    ./coturn.nix
    ./forgejo.nix
    ./grafana.nix
    ./loki.nix
    ./mautrix-telegram.nix
    ./mimir.nix
    # ./nocodb.nix
    ./ntfy.nix
    # ./oauth2-proxy.nix
    ./postgres.nix
    ./rustic.nix
    ./synapse.nix
    ./vault.nix
    # ./zitadel.nix

    ./legacy/gotosocial.nix
    ./legacy/kanidm.nix
  ];
}
