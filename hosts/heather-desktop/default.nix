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

  # Enable Intel IOMMU for VFIO / GVT-g passthrough to VMs.
  # iommu=pt leaves non-passthrough devices at native performance.
  # i915.enable_gvt=1 turns on GVT-g so kvmgt can carve vGPUs out of UHD 630.
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "i915.enable_gvt=1"
  ];

  # Load the GVT-g mediator at boot; pulls in vfio/mdev/kvm via modprobe.
  boot.kernelModules = [ "kvmgt" ];

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

  # ── GVT-g vGPU (Intel UHD 630) ───────────────────────────────────
  # Creates a persistent mediated device out of the iGPU so a libvirt VM
  # can attach it via <hostdev type='mdev' model='vfio-pci'>. UUID is
  # fixed so the VM XML can reference it stably.
  systemd.services.gvt-g-vgpu = {
    description = "Create GVT-g vGPU for Windows VM";
    wantedBy = [ "multi-user.target" ];
    before = [ "libvirtd.service" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "gvt-g-create" ''
        UUID=3b855572-293c-45ce-835c-38a563de2707
        CREATE=/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create
        if [ ! -e /sys/bus/mdev/devices/$UUID ]; then
          echo "$UUID" > "$CREATE"
        fi
      '';
      ExecStop = pkgs.writeShellScript "gvt-g-destroy" ''
        UUID=3b855572-293c-45ce-835c-38a563de2707
        if [ -e /sys/bus/mdev/devices/$UUID ]; then
          echo 1 > /sys/bus/mdev/devices/$UUID/remove
        fi
      '';
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
    libvirt # virsh CLI
    pciutils # lspci
    qemu_kvm # qemu-img for disk format conversion
    virt-manager # includes virt-install CLI
    virtio-win # Windows virtio drivers ISO
  ];

  # VNC access to VMs from LAN
  networking.firewall.allowedTCPPorts = [ 5900 ];

  users.users.pjl.extraGroups = [ "libvirtd" ];

  # Sync primary ESP to fallback after every nixos-rebuild switch
  system.activationScripts.sync-boot-fallback = ''
    ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback/
  '';

  system.stateVersion = "25.11";
}
