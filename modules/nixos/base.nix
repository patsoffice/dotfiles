{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS hosts track the default LTS kernel (known ZFS-compatible); latest otherwise.
  # Hosts that need a specific release pin boot.kernelPackages themselves.
  boot.kernelPackages =
    if config.boot.zfs.enabled then pkgs.linuxPackages else pkgs.linuxPackages_latest;

  # Refuse to import a ZFS root pool last used by another system (26.11 default).
  boot.zfs.forceImportRoot = lib.mkIf config.boot.zfs.enabled false;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Enable nix-ld for running dynamically linked executables (VS Code extensions, etc.)
  programs.nix-ld.enable = true;

  # Enable zsh as a valid login shell
  programs.zsh.enable = true;

  # Define the primary user account.
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
    neovim
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-substituters = [ "https://patsoffice.cachix.org" ];
    trusted-public-keys = [ "patsoffice.cachix.org-1:C1fBDvGbwf7jjrcbCTT6epSnlq7IrZyYN/5H3pb+GtQ=" ];
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
      "claude-code"
      "corefonts"
      "discord"
      "google-chrome"
      "lens-desktop"
      "nvidia-settings"
      "nvidia-x11"
      "obsidian"
      "plexamp"
      "prusa-slicer"
      "steam"
      "steam-unwrapped"
      "unityhub"
      "unrar"
      "vscode"
    ];
}
