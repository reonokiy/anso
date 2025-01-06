{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustic-rs
  ];

  sops.templates."rustic.toml" = {
    content = ''
      [repository]
      repository = "opendal:b2"
      password = ${config.sops.placeholder."rustic/b2/password"}

      # B2 specific options
      [repository.options]
      application_key_id = ${config.sops.placeholder."rustic/b2/application_key_id"}
      application_key = ${config.sops.placeholder."rustic/b2/application_key"}
      bucket = "anso-rustic-backup"
      root = "/"

      [forget]
      keep-daily = 14
      keep-weekly = 8

      [[backup.snapshots]]
      label = "synapse"
      sources = ["/data/synapase"]

      [[backup.snapshots]]
      label = "authentik"
      sources = [ "/data/authentik" ]

      [backup.snapshots.hooks]
      run-before = ["systemctl stop authentik.target"]
      run-finally = ["systemctl start authentik.target"]

      [[backup.snapshots]]
      label = "postgres"
      sources = [ "/data/postgres" ]
    '';
  };

  environment.etc."rustic/rustic.toml" = {
    source = config.sops.templates."rustic.toml".path;
  };
}
