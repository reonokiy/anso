{ inputs, ... }:

{
  sops.defaultSopsFile = "${inputs.secrets}/aios.yaml";
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
