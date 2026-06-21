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
  ];

  # ── Fingerprint reader (DigitalPersona U.are.U 4500) ─────────────────
  # A genuine libfprint sensor (USB 05ba:0007), handled by the uru4000 driver.
  # fprintd runs as a system service, owns the device, and matches prints on
  # the host. Enabling it makes fprintAuth default-on for every PAM service, so
  # sudo, tty login, and the greetd graphical greeter all try the reader first
  # and fall back to the password if it fails or no finger is enrolled.
  #
  # Enrollment is per-user and interactive, so it can't be declared here. After
  # a rebuild, run once (press the same finger several times when prompted):
  #   fprintd-enroll            # enroll the right index finger by default
  #   fprintd-verify            # confirm it matches
  # Enroll another finger with: fprintd-enroll -f left-index-finger
  services.fprintd.enable = true;

  # fprintd's enroll action defaults to polkit `auth_self_keep`, which needs a
  # graphical polkit authentication agent to prompt for the password. The niri
  # session doesn't run one, so `fprintd-enroll` fails with "Not Authorized".
  # Let an active local session enroll without a prompt — the user already
  # authenticated to obtain the session. (The verify action, used by PAM for
  # sudo/login, already permits active sessions, so it needs no rule.)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "net.reactivated.fprint.device.enroll" &&
          subject.local && subject.active) {
        return polkit.Result.YES;
      }
    });
  '';

  system.stateVersion = "25.11";
}
