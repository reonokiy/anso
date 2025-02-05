{ inputs, ... }:

{
  sops.defaultSopsFile = "${inputs.secrets}/buno.yaml";
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  users.users.smtp.isSystemUser = true;
  users.users.smtp.group = "smtp";
  users.groups.smtp = { };

  sops.secrets."smtp/username" = {
    mode = "0440";
    owner = "smtp";
    group = "smtp";
  };
  sops.secrets."smtp/password" = {
    mode = "0440";
    owner = "smtp";
    group = "smtp";
  };
}
