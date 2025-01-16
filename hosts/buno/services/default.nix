{
  imports = [
    ./alloy.nix
    ./authentik.nix
    ./coturn.nix
    ./forgejo.nix
    ./grafana.nix
    ./loki.nix
    ./mimir.nix
    ./ntfy.nix
    # ./oauth2-proxy.nix
    ./postgres.nix
    ./rustic.nix
    ./synapse.nix
    ./vault.nix

    ./legacy/gotosocial.nix
    ./legacy/kanidm.nix
  ];
}
