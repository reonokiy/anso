build-on-remote := "false"
generate-hardware-config := "false"
initrd-ssh-key := "true"

default:
    @just --choose

install host target luks age:
    #!/usr/bin/env python3
    import os
    import tempfile
    build_on_remote = True if "{{build-on-remote}}" == "true" else False
    generate_hardware_config = True if "{{generate-hardware-config}}" == "true" else False
    initrd_ssh_key = True if "{{initrd-ssh-key}}" == "true" else False
    build_on_remote_command = "--build-on-remote"
    generate_hardware_config_command = "--generate-hardware-config nixos-generate-config ./hosts/{{host}}/hardware-configuration.nix"
    
    print(f"[install] Generating initrd ssh keys...")
    tmp_dir = tempfile.mkdtemp()
    tmp_ssh_dir = os.path.join(tmp_dir, "etc/secrets/initrd")
    tmp_ssh_key_file = os.path.join(tmp_ssh_dir, "ssh_host_ed25519_key")
    os.makedirs(tmp_ssh_dir, exist_ok=True)
    initrd_ssh_key_command = f"--extra-files {tmp_dir}"
    os.system(f"ssh-keygen -t ed25519 -f {tmp_ssh_key_file} -N ''")
    print("[install] SSH key fingerprint: ")
    os.system(f"ssh-keygen -lf {tmp_ssh_key_file}")
    os.chmod(tmp_ssh_key_file, 0o600)
    print(f"[install] SSH key dir: {tmp_ssh_dir}")
    tmp_age_key_dir = os.path.join(tmp_dir, "var/lib/sops-nix")
    tmp_age_key_file = os.path.join(tmp_age_key_dir, "key.txt")
    os.makedirs(tmp_age_key_dir, exist_ok=True)
    with open(tmp_age_key_file, "w") as f:
        f.write("{{age}}")
    print(f"[install] Age key: {tmp_age_key_file}")

    print("[install] Preparing luks disk key...")
    tmp_dir1 = tempfile.mkdtemp()
    disk_key_file = os.path.join(tmp_dir1, "disk.key")
    with open(disk_key_file, "w") as f:
        f.write("{{luks}}")
    disk_encryption_key_command = f"--disk-encryption-keys /tmp/disk.key {disk_key_file}"
    print(f"[install] Disk key: {disk_key_file}")

    final_command = " \\\n".join((
        "nixos-anywhere",
        "--flake .#{{host}}",
        "--target-host {{target}}",
        build_on_remote_command if build_on_remote else "",
        generate_hardware_config_command if generate_hardware_config else "",
        initrd_ssh_key_command if initrd_ssh_key else "",
        disk_encryption_key_command
    ))
    print(f"[install] Final command: \n{final_command}")
    
    print("\n continue? [y/n]")
    answer = input()
    if answer == "y":
        os.system(final_command)
    elif answer == "n":
        print("[install] Aborting...")
    
    # cleanup
    os.system(f"rm -rf {tmp_dir}")
    os.system(f"rm -rf {tmp_dir1}")

wg-gen:
    #!/usr/bin/env bash
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)
    echo "Public key:  $public_key"
    echo "Private key: $private_key"
