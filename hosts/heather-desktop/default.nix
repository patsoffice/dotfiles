{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "heather-desktop";

  # Required by ZFS — generate with: head -c 8 /etc/machine-id
  networking.hostId = "2075ccdf";

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # ZFS maintenance
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "weekly";
  services.zfs.trim.enable = true;

  # ── Windows VM (libvirt/QEMU/KVM) ────────────────────────────────
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true; # TPM 2.0 emulation (Windows 11 compat)
    };
  };

  # Save/restore VM state across host reboots
  systemd.services.libvirt-save-vms = {
    description = "Save running libvirt VMs on shutdown";
    before = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.libvirt}/bin/virsh list --name | xargs -rn1 ${pkgs.libvirt}/bin/virsh managedsave";
    };
  };

  # ── Samba ───────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "INT.CHEZLAWRENCE.COM";
        "server string" = "%h server (Samba, NixOS)";
        "map to guest" = "Bad User";

        # Protocol versions
        "client min protocol" = "SMB2_02";
        "server min protocol" = "SMB2_02";
        "server max protocol" = "SMB3";
      };
      images = {
        path = "/var/lib/libvirt/images";
        "read only" = "no";
        "browseable" = "yes";
        "valid users" = "pjl";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager # includes virt-install CLI
    virtio-win # Windows virtio drivers ISO
  ];

  users.users.pjl.extraGroups = [ "libvirtd" ];

  system.stateVersion = "25.11";
}
