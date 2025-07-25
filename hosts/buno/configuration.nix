{ lib, ... }:

{
  imports = [
    ../../modules
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "24.11";
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

  boot.kernel.sysctl = {
    # Fix "Failed to allocate directory watch: Too many open files"
    # or "Insufficent watch descriptors available."
    "fs.inotify.max_user_instances" = 8192;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "vault-bin" ];
  zramSwap.memoryPercent = 400;

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

  services.anso.elk-nokiy-net = {
    enable = false;
    image = "ghcr.io/elk-zone/elk:v0.16.0";
  };

  services.anso.affine-nokiy-net = {
    enable = false;
  };

  services.anso.supabase-nokiy-net = {
    enable = false;
  };

  services.anso.auth-nokiy-net.enable = true;
  # services.anso.analytics-nokiy-net.enable = true;
  # services.anso.self-nokiy-net.enable = true;
  # services.anso.infisical-nokiy-net.enable = true;
  # services.anso.observe-nokiy-net.enable = true;
  services.anso.git-nokiy-net.enable = true;
  # services.anso.perverse-social-nokiy-net.enable = true;
  # services.anso.bird-nokiy-net.enable = true;
  services.anso.social-nokiy-net.enable = true;
  services.anso.synapse-nokiy-net.enable = true;
}
