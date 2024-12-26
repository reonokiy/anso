{
  sops.defaultSopsFile = ../../secrets/buno.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
