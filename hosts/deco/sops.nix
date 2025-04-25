{ inputs, ... }:

{
  sops.defaultSopsFile = "${inputs.secrets}/deco.yaml";
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
