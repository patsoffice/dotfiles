{
  disko.devices = {
    disk = {
      a = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SPCC_M.2_PCIe_SSD_A20250218N301TB06607";
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
                  "nofail"
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

      b = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SPCC_M.2_PCIe_SSD_A20251021N301KG01319";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-fallback";
                mountOptions = [
                  "fmask=0177"
                  "dmask=0077"
                  "nofail"
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
        mode = "mirror";
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
          vms = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt/images";
            options.mountpoint = "legacy";
          };
          "vms/heather-pc" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt/images/heather-pc";
            options = {
              mountpoint = "legacy";
              recordsize = "64K";
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
