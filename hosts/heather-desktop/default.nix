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

  # ── VFIO GPU + USB passthrough ─────────────────────────────────────
  # Bind to vfio-pci so they can be passed through to the Windows VM:
  #   10de:2504 / 10de:228e — RTX 3060 (VGA + HDMI audio), physical DP/HDMI out
  #   1912:0014             — Renesas uPD720201 USB 3.0 card (PCI 04:00.0),
  #                           alone in its IOMMU group; gives the VM real ports.
  # Host keeps the iGPU (UHD 630) and onboard Intel xHCI for the console.
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:2504,10de:228e,1912:0014"
  ];

  # Load vfio-pci in initrd so it claims the 3060 before nouveau can.
  boot.initrd.kernelModules = [ "vfio-pci" ];

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

  # ── LAN bridge for bridged VM networking ─────────────────────────
  # br0 enslaves the onboard NIC so the Windows VM gets a first-class
  # DHCP lease from the LAN router instead of sitting behind libvirt NAT.
  # A real bridge (not macvtap) is required so the host and VM can talk
  # to each other — the VM reaches the Samba image share over the LAN.
  #
  # After rebuild, repoint the VM's NIC at the bridge on the host:
  #   virsh edit heather-pc
  #   <interface type='bridge'>
  #     <source bridge='br0'/>
  #     <model type='virtio'/>
  #   </interface>
  # (drop the existing <source network='default'/> NAT interface block)
  networking.networkmanager.ensureProfiles.profiles = {
    br0 = {
      connection = {
        id = "br0";
        type = "bridge";
        interface-name = "br0";
        autoconnect = true;
      };
      bridge.stp = false;
      # Pin br0 to eno1's hardware MAC so the host keeps its DHCP
      # lease/reservation regardless of port-attach timing.
      bridge.mac-address = "50:EB:F6:81:43:B8";
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
    br0-slave = {
      connection = {
        id = "br0-slave";
        type = "ethernet";
        interface-name = "eno1";
        master = "br0";
        slave-type = "bridge";
        autoconnect = true;
      };
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
