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
  boot.kernelParams = [ "zfs.zfs_arc_max=17179869184" ]; # 16GB ARC limit

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

  boot.zfs.extraPools = [ "tank" ];

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
        "fruit:metadata" = "stream";
        "fruit:posix_rename" = "yes";

        # VFS modules (applied to all shares)
        "vfs objects" = "catia fruit streams_xattr acl_xattr";

        # POSIX ACLs & inherited permissions
        "map acl inherit" = "yes";
        "inherit permissions" = "yes";

        # Protocol versions — SMB3 only
        "client min protocol" = "SMB3";
        "server min protocol" = "SMB3";
        "server max protocol" = "SMB3";

        # Access control
        "guest ok" = "no";

        # Logging
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";
        logging = "file";
      };

      # ── Shares ──────────────────────────────────────────────────────
      apps = {
        comment = "apps share";
        path = "/tank/apps";
        "read only" = "no";
      };

      "pats-imac" = {
        comment = "pats-imac Time Machine";
        path = "/tank/backups/tm/pats-imac";
        "read only" = "no";
        "fruit:time machine" = "yes";
      };

      "pats-macbook-pro-16" = {
        comment = "pats-macbook-pro-16 Time Machine";
        path = "/tank/backups/tm/pats-macbook-pro-16";
        "read only" = "no";
        "fruit:time machine" = "yes";
      };

      downloads = {
        comment = "downloads share";
        path = "/tank/downloads";
        "read only" = "no";
      };

      emulators = {
        comment = "emulators share";
        path = "/tank/emulators";
        "read only" = "no";
      };

      homes = {
        comment = "homes share";
        path = "/tank/home/%U";
        "read only" = "no";
      };

      media = {
        comment = "media share";
        path = "/tank/media";
        "read only" = "yes";
        "write list" = "@users";
      };

      roms = {
        comment = "roms share";
        path = "/tank/roms";
        "read only" = "yes";
        "write list" = "@users";
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
      /tank/downloads *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/books *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/live-tv *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/movies *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/music *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/scans *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/tv *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/media/youtube *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/roms *(rw,acl,sync,no_subtree_check,sec=sys)
      /tank/transcode *(rw,acl,sync,no_subtree_check,sec=sys)
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
  # ── Prometheus exporters ───────────────────────────────────────
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
  };

  services.prometheus.exporters.smartctl = {
    enable = true;
    openFirewall = true;
  };

  # ── Garage (S3-compatible object storage) ─────────────────────────
  services.garage = {
    enable = true;
    package = pkgs.garage;
    settings = {
      metadata_dir = "/tank/garage/meta";
      data_dir = "/tank/garage/data";
      db_engine = "sqlite";
      replication_factor = 1;
      s3_api = {
        s3_region = "garage";
        api_bind_addr = "[::]:3900";
      };
      admin = {
        api_bind_addr = "[::]:3903";
        admin_token_file = config.sops.secrets.garage_admin_token.path;
      };
      rpc_bind_addr = "[::]:3901";
      rpc_secret_file = config.sops.secrets.garage_rpc_secret.path;
    };
  };
  systemd.services.garage.serviceConfig.DynamicUser = lib.mkForce false;
  users.users.garage = {
    isSystemUser = true;
    group = "garage";
  };
  users.groups.garage = { };
  users.users.cub = {
    isNormalUser = true;
    uid = 1001;
    shell = pkgs.zsh;
    extraGroups = [ "users" ];
  };
  users.users.t-man = {
    isNormalUser = true;
    uid = 1002;
    shell = pkgs.zsh;
    extraGroups = [ "users" ];
  };

  networking.firewall.allowedTCPPorts = [ 2049 3900 3903 ];

  # ── Secrets (sops-nix) ─────────────────────────────────────────────
  sops.defaultSopsFile = ../../secrets/nas1.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.aws_access_key_id = { };
  sops.secrets.aws_secret_access_key = { };
  sops.secrets.ses_from_address = { };
  sops.secrets.garage_rpc_secret = { };
  sops.secrets.garage_admin_token = { };

  # ── Mail (msmtp via Amazon SES) ────────────────────────────────────
  environment.systemPackages = [ pkgs.msmtp ];

  sops.templates."msmtprc" = {
    content = ''
      defaults
      auth on
      tls on
      tls_starttls on

      account default
      host email-smtp.us-west-2.amazonaws.com
      port 587
      user ${config.sops.placeholder.aws_access_key_id}
      password ${config.sops.placeholder.aws_secret_access_key}
      from ${config.sops.placeholder.ses_from_address}
    '';
    path = "/etc/msmtprc";
    mode = "0644";
  };

  # Symlink sendmail to msmtp
  systemd.tmpfiles.rules = [
    "L+ /usr/sbin/sendmail - - - - ${pkgs.msmtp}/bin/msmtp"
  ];

  # Sync primary ESP to fallback after every nixos-rebuild switch
  system.activationScripts.sync-boot-fallback = ''
    ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback/
  '';

  system.stateVersion = "25.11";
}
