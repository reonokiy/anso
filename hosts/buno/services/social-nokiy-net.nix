{
  imports = [
    ../../../modules/social-nokiy-net.nix
  ];

  services.anso.social-nokiy-net = {
    enable = true;
  };
}
