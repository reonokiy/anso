{
  imports = [
    ../../../modules/globalping.nix
  ];

  services.anso.globalping = {
    enable = true;
    image = "mirror.gcr.io/globalping/globalping-probe:0.35.4";
  };
}
