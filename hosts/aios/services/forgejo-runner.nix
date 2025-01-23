{ config, pkgs, ... }:

{
  sops.secrets."forgejo/runner/default/token" = { };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.aios-default = {
      enable = true;
      name = "aios-default";
      tokenFile = config.sops.secrets."forgejo/runner/default/token".path;
      url = "https://code.forgejo.org/";
      labels = [
        "node-22:docker://node:22-bookworm"
        "nixos-latest:docker://nixos/nix"
      ];
      settings = { };
    };
  };
}
