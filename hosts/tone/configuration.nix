let
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHUXigvKgHHaOQcE+xr8uZPZuj2JSRk0dFEEzDsaZBy";
in
{
  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "25.05";
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
          ssh_public_key
        ];
        hostKeys = [ /etc/secrets/initrd/ssh_host_ed25519_key ];
      };
    };
  };

  users.users = {
    root.openssh.authorizedKeys.keys = [
      ssh_public_key
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
}
