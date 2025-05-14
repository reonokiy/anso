{
  imports = [
    ./alloy.nix
    ./authentik.nix
    ./coturn.nix
    # ./forgejo.nix
    ./grafana.nix
    ./loki.nix
    ./mautrix-telegram.nix
    ./mimir.nix
    # ./nocodb.nix
    ./ntfy.nix
    # ./oauth2-proxy.nix
    ./postgres.nix
    # ./pocket-id.nix
    ./rustic.nix
    ./social-nokiy-net.nix
    ./synapse.nix
    ./vault.nix
    # ./zitadel.nix

    ./legacy/gotosocial.nix
    ./legacy/kanidm.nix
  ];
}
