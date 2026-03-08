{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-testing";

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  # Ensure swapfile has CoW disabled (required for btrfs)
  systemd.services.create-swapfile = {
    description = "Create swapfile with nocow";
    wantedBy = [ "swap-swapfile.swap" ];
    before = [ "swap-swapfile.swap" ];
    script = ''
      if [ ! -f /swap/swapfile ]; then
        ${pkgs.coreutils}/bin/truncate -s 0 /swap/swapfile
        ${pkgs.e2fsprogs}/bin/chattr +C /swap/swapfile
      fi
    '';
    serviceConfig.Type = "oneshot";
  };

  services.btrfs.autoScrub.enable = true;

  system.stateVersion = "25.11";
}
