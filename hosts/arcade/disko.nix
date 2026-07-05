{
  # NixOS is installed ONLY on this drive (Crucial P3 1TB, serial …A482 /
  # nvme1n1). The second NVMe (…9EE3 / nvme0n1) holds Windows and is
  # deliberately NOT referenced here — disko only ever touches devices it is
  # told about, so the Windows install is never in scope.
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-CT1000P3SSD8_234044B1A482";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0177"
                  "dmask=0077"
                ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
          mountpoint = "none";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              atime = "off";
            };
          };
          swap = {
            type = "zfs_volume";
            size = "8G";
            options = {
              compression = "zstd";
              volblocksize = "4096";
            };
            content = {
              type = "swap";
            };
          };
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              refreservation = "10G";
            };
          };
        };
      };
    };
  };
}
