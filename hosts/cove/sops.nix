{ inputs, ... }:

{
  sops.defaultSopsFile = "${inputs.secrets}/cove.yaml";
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
