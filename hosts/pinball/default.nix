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

  networking.hostName = "pinball";

  # Required by ZFS — generate with: head -c 8 /etc/machine-id
  networking.hostId = "17bf28f3";

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # Pin kernel to a ZFS-compatible LTS release (base.nix sets linuxPackages_latest)
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

  # ZFS maintenance
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "weekly";
  services.zfs.trim.enable = true;

  system.stateVersion = "25.11";
}
