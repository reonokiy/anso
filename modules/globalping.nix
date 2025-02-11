{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.anso.globalping;
in
{
  options.services.anso.globalping = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    image = mkOption {
      type = types.str;
      default = "globalping/globalping-probe";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.globalping = {
      image = cfg.image;
      extraOptions = [
        "--network=host"
        "--cap-add=NET_RAW"
      ];
    };
  };
}
