{ pkgs, ... }:

{
  system.stateVersion = "24.11";
  time.timeZone = "Europe/Berlin";

  boot.loader.systemd-boot.enable = true;
  boot.kernelParams = [ "ip=dhcp" ];
  boot.initrd = {
    availableKernelModules = [ ];
    systemd.users.root.shell = "/bin/cryptsetup-askpass";
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 22;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHUXigvKgHHaOQcE+xr8uZPZuj2JSRk0dFEEzDsaZBy"
        ];
        hostKeys = [ /etc/secrets/initrd/ssh_host_ed25519_key ];
      };
    };
  };

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHUXigvKgHHaOQcE+xr8uZPZuj2JSRk0dFEEzDsaZBy"
    ];
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
        AllowUsers = [ "root" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [ kubectl helm ];
}
