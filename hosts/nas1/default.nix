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

  # ── Network (DHCP) ─────────────────────────────────────────────────
  networking.useDHCP = lib.mkForce true;

  # Required by ZFS — generate with: head -c 8 /etc/machine-id
  networking.hostId = "917c009c";

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # Use ZFS 2.4 pinned to the 6.12 LTS kernel
  boot.zfs.package = pkgs.zfs_2_4;
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

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
  #
  # Once the 8th drive is available:
  #   zpool replace tank /tmp/placeholder /dev/disk/by-id/NEW_HDD

  fileSystems."/tank" = {
    device = "tank";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };


  # ── Samba ───────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "INT.CHEZLAWRENCE.COM";
        "server string" = "%h server (Samba, NixOS)";
        "multicast dns register" = "no";

        # Apple / macOS interop
        "fruit:aapl" = "yes";
        "fruit:nfs_aces" = "yes";
        "fruit:copyfile" = "no";
        "fruit:model" = "MacSamba";

        # POSIX ACLs & inherited permissions
        "map acl inherit" = "yes";
        "inherit permissions" = "yes";

        # Protocol versions
        "client min protocol" = "SMB2_02";
        "server min protocol" = "SMB2_02";
        "server max protocol" = "SMB3";

        # Logging
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";
        logging = "file";
      };
    };
  };

  # ── NFS ────────────────────────────────────────────────────────────
  services.nfs.server = {
    enable = true;
    exports = ''
      /tank/backups/apps *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/backups/VolsyncKopia *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/backups/syncthing *(rw,acl,sync,no_subtree_check,sec=sys)
    '';
  };
  services.nfs.settings = {
    nfsd = {
      udp = false;
      tcp = true;
      vers3 = false;
      vers4 = true;
      "vers4.0" = true;
      "vers4.1" = true;
      "vers4.2" = true;
    };
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];

  # ── Prometheus exporters ───────────────────────────────────────
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
  };

  services.prometheus.exporters.smartctl = {
    enable = true;
    openFirewall = true;
  };

  # Sync primary ESP to fallback after every nixos-rebuild switch
  system.activationScripts.sync-boot-fallback = ''
    ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback/
  '';

  system.stateVersion = "25.11";
}
