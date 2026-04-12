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

  # Bluetooth
  hardware.bluetooth.enable = true;

  # VPinFE Manager UI
  networking.firewall.allowedTCPPorts = [ 8001 ];

  # DudesCab controller — allow input group access to hidraw devices
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="106f", GROUP="input", MODE="0660"
  '';

  # Host-specific packages (not shared with other arcade machines)
  nixpkgs.overlays = [
    (final: prev: {
      lgtvremote-cli = final.callPackage ../../packages/lgtvremote-cli.nix { };
      vpinfe = final.callPackage ../../packages/vpinfe.nix { };
    })
  ];
  environment.systemPackages = [
    pkgs.lgtvremote-cli
    pkgs.vpinfe
  ];

  systemd.services.lgtv-power = {
    description = "LG TV power on/off";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      if [ -f /home/pjl/.config/lgtvremote/devices.json ]; then
        ${pkgs.lgtvremote-cli}/bin/lgtv on
      fi
    '';
    preStop = ''
      if [ -f /home/pjl/.config/lgtvremote/devices.json ]; then
        ${pkgs.lgtvremote-cli}/bin/lgtv off
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "pjl";
      Environment = "HOME=/home/pjl";
    };
  };

  system.stateVersion = "25.11";
}
