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

  networking.hostName = "arcade";

  # Required by ZFS — generate with: head -c 8 /etc/machine-id
  networking.hostId = "ad275fdd";

  # ZFS support (base.nix pins a ZFS-compatible LTS kernel automatically)
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # ZFS maintenance
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "weekly";
  services.zfs.trim.enable = true;

  # Dual-boot with Windows on the other NVMe (nvme0n1). systemd-boot (base.nix)
  # installs to this drive's own ESP; Windows keeps its ESP untouched. Pick the
  # OS from the firmware boot menu, or add a Windows entry post-install.

  # Bluetooth for wireless controllers
  hardware.bluetooth.enable = true;

  # Arcade control devices (vendor d209 — Ultimarc/IPAC) — allow input group
  # access so MAME can read them without root.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="d209", MODE="0660", GROUP="input"
  '';

  # umtool: program Ultimarc control boards (IPAC, U-HID, …) from JSON configs.
  environment.systemPackages = [ pkgs.ultimarc-linux ];

  # Inbound SSH: pjl has no password (console autologin only), so authorize the
  # personal key for remote management. Mirrors the public key in
  # modules/home/ssh.nix. Promote to base.nix if wanted fleet-wide.
  users.users.pjl.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqxC/bil4Nnlob47rm5wahder21ha6urx1J7xVfm71F Personal SSH key"
  ];

  # ── WiFi (Realtek RTL8852CE) ───────────────────────────────────────
  # Chip needs redistributable firmware (rtw89). PSK comes from sops so it
  # never lands in the Nix store; NetworkManager substitutes $WIFI_PSK from
  # the rendered env file at profile-apply time.
  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.templates."wifi.env".path ];
    profiles.chez-lawrence = {
      connection = {
        id = "Chez-Lawrence";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        ssid = "Chez-Lawrence";
        mode = "infrastructure";
        # 2 = disable powersave. The RTL8852CE flaps with powersave on.
        powersave = 2;
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$WIFI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # ── Secrets (sops-nix) ─────────────────────────────────────────────
  # Decrypted on first boot with the host key pre-seeded by nixos-anywhere
  # (--extra-files), so WiFi comes up on the very first reboot.
  sops.defaultSopsFile = ../../secrets/arcade.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.wifi_psk = { };
  sops.templates."wifi.env".content = "WIFI_PSK=${config.sops.placeholder.wifi_psk}";

  system.stateVersion = "25.11";
}
