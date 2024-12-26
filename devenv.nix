{
  inputs,
  pkgs,
  ...
}:

{
  packages = [
    inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
    inputs.nixos-anywhere.packages.${pkgs.system}.default
    pkgs.just
    pkgs.python3
    pkgs.openssh
    pkgs.sops
  ];

  git-hooks.hooks = {
    nixfmt-rfc-style.enable = true;
  };
}
