{
  config,
  pkgs,
  ...
}:

let
  # Lens Desktop (Kubernetes IDE) tracking the latest upstream AppImage instead
  # of the older nixpkgs pin. See ./lens.nix for the version/hash and how to bump.
  lens-latest = pkgs.callPackage ./lens.nix { };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "pjl-desktop";

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  # Ensure swapfile has CoW disabled (required for btrfs).
  # We depend on the specific /swap mount point rather than local-fs.target to
  # avoid an ordering cycle: local-fs.target pulls in run-wrappers.mount which
  # needs swap.target, creating a circular dependency that can delay
  # /run/wrappers and break PAM authentication (unix_chkpwd not found).
  systemd.services.create-swapfile = {
    description = "Create swapfile with nocow";
    wantedBy = [ "swap-swapfile.swap" ];
    before = [ "swap-swapfile.swap" ];
    after = [ "swap.mount" ];
    requires = [ "swap.mount" ];
    unitConfig.DefaultDependencies = false;
    script = ''
      if [ ! -f /swap/swapfile ]; then
        ${pkgs.coreutils}/bin/truncate -s 0 /swap/swapfile
        ${pkgs.e2fsprogs}/bin/chattr +C /swap/swapfile
      fi
    '';
    serviceConfig.Type = "oneshot";
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 8192;
    }
  ];

  services.btrfs.autoScrub.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  environment.systemPackages = [
    pkgs.heroic
    lens-latest # Kubernetes IDE (latest upstream AppImage; see let-binding above)
    pkgs.pam_u2f # pamu2fcfg — enroll a FIDO2 credential into the PAM mapping
    pkgs.libfido2 # fido2-token — inspect/manage the security key
  ];

  # ── FIDO2 biometric security key (AuthenTrend ATKey.Pro) ─────────────
  # This is a FIDO2/U2F authenticator with an on-device fingerprint sensor,
  # NOT a libfprint sensor — fprintd cannot see it. The fingerprint is matched
  # on the key; Linux only sees a FIDO2 device. We use it for login + sudo via
  # pam_u2f. control = "sufficient" means a successful touch authenticates on
  # its own, and a missing/unmapped key falls through to the password prompt.
  #
  # Enrollment is per-user and interactive (the credential is created on the
  # device), so it can't be declared here. After a rebuild, run once:
  #   mkdir -p ~/.config/Yubico
  #   pamu2fcfg -V > ~/.config/Yubico/u2f_keys   # -V requires the fingerprint (UV)
  # Append additional keys with `pamu2fcfg -V -n >> ~/.config/Yubico/u2f_keys`.
  security.pam.u2f = {
    control = "sufficient";
    settings = {
      cue = true; # print "touch your security key" prompt
      openasuser = true; # read ~/.config/Yubico/u2f_keys as the invoking user (needed for sudo)
    };
  };
  security.pam.services.sudo.u2f.enable = true;
  security.pam.services.login.u2f.enable = true; # tty login
  security.pam.services.greetd.u2f.enable = true; # graphical greeter

  # Grant the logged-in user (and pamu2fcfg / browser WebAuthn) access to the
  # device. PAM running as root for login/sudo works without this, but
  # enrollment and web use run unprivileged.
  services.udev.extraRules = ''
    # AuthenTrend ATKey.Pro biometric FIDO2 security key
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31bb", ATTRS{idProduct}=="0622", TAG+="uaccess"
  '';

  system.stateVersion = "25.11";
}
