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
  # Not managed by disko (disko doesn't support ZFS 'missing' keyword).
  # Create manually during install:
  #
  #   zpool create -o ashift=12 \
  #     -O compression=zstd -O atime=off -O mountpoint=none \
  #     tank raidz2 \
  #     /dev/disk/by-id/FIXME_HDD1 \
  #     /dev/disk/by-id/FIXME_HDD2 \
  #     /dev/disk/by-id/FIXME_HDD3 \
  #     /dev/disk/by-id/FIXME_HDD4 \
  #     /dev/disk/by-id/FIXME_HDD5 \
  #     /dev/disk/by-id/FIXME_HDD6 \
  #     /dev/disk/by-id/FIXME_HDD7 \
  #     missing
  #
  #   zfs create -o mountpoint=legacy tank/data
  #
  # Once the 8th drive is available:
  #   zpool replace tank missing /dev/disk/by-id/FIXME_HDD8

  fileSystems."/tank/data" = {
    device = "tank/data";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  system.stateVersion = "25.11";
}
