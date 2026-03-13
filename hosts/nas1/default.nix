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

  networking.hostName = "nas1";

  # ── Static IP ──────────────────────────────────────────────────────
  networking.useDHCP = false;
  networking.interfaces.enp5s0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.0";
        prefixLength = 21;
      }
    ];
  };
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [
    "192.168.0.100"
    "192.168.0.101"
  ];

  # Required by ZFS — generate with: head -c 8 /etc/machine-id
  networking.hostId = "85c7ece1";

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # Use the latest ZFS-compatible kernel instead of linuxPackages_latest from base.nix
  boot.kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;

  # ZFS maintenance
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "weekly";
  services.zfs.trim.enable = true;

  # ── tank pool (HDD raidz2) ──────────────────────────────────────────
  # Not managed by disko. Created manually with 7 drives + sparse file
  # placeholder for the 8th (pool runs degraded until drive is added).
  #
  #   truncate -s 18T /tmp/placeholder
  #   zpool create -f -o ashift=12 \
  #     -O compression=zstd -O atime=off -O mountpoint=none \
  #     tank raidz2 \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68AFPN0_4BKR03RZ \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68CKWN0_T0G2PE0F \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68CKWN0_T0G2NXJF \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68CKWN0_T0G2PKLF \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68AFPN0_4YHY1WYH \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68AFPN0_4YHY3L8H \
  #     /dev/disk/by-id/ata-WDC_WD181KFGX-68AFPN0_4YHY7X3H \
  #     /tmp/placeholder
  #   zpool offline tank /tmp/placeholder
  #   rm /tmp/placeholder
  #   zfs create -o mountpoint=legacy tank/data
  #
  # Once the 8th drive is available:
  #   zpool replace tank /tmp/placeholder /dev/disk/by-id/NEW_HDD

  fileSystems."/tank/data" = {
    device = "tank/data";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # Sync primary ESP to fallback after every nixos-rebuild switch
  system.activationScripts.sync-boot-fallback = ''
    ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback/
  '';

  system.stateVersion = "25.11";
}
