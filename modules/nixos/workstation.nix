{
  config,
  lib,
  pkgs,
  dms,
  username,
  ...
}:

{
  imports = [
    dms.nixosModules.greeter
  ];

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";

    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };

    quickshell.package = pkgs.quickshell;
  };

  # Dedicated PAM service for the DankMaterialShell lock screen's password
  # prompt. Its Pam.qml opens a "dankshell" PamContext and only falls back to
  # the generic "login" stack when this service is absent; defining it lets the
  # lock screen carry its own policy instead of riding login's.
  #
  # fprintAuth is forced off because DMS runs the fingerprint reader in a
  # SEPARATE, concurrent PamContext (its bundled "fprint" service, just
  # pam_fprintd). If this password service also pulled in pam_fprintd — which
  # services.fprintd would otherwise add by default — both contexts would race
  # to claim the one fprintd device at lock time. Keep this one password-only.
  security.pam.services.dankshell.fprintAuth = false;

  # TODO(revisit): vesktop's build pulls in pnpm as a nativeBuildInput, and a
  # nixpkgs bump moved pnpm to 10.29.2, which is flagged insecure (CVE-2026-48995
  # and friends). pnpm is build-time only — it is not in vesktop's runtime
  # closure — so allow it to unblock the rebuild. Drop this once nixpkgs ships a
  # patched pnpm (or vesktop stops needing this version).
  nixpkgs.config.permittedInsecurePackages = [ "pnpm-10.29.2" ];

  hardware.bluetooth.enable = true;

  programs.firefox.enable = true;
  programs.niri.enable = true;

  # 1Password GUI via the NixOS module rather than a home-manager package.
  # Setting polkitPolicyOwners rebuilds the package so it installs the
  # com.1password.1Password polkit action (the default package ships none) and
  # the setgid 1Password-BrowserSupport wrapper. That polkit action — together
  # with the pam_fprintd entry that services.fprintd adds to the polkit-1 PAM
  # service — is what lets "Unlock using system authentication" use the
  # fingerprint reader. A polkit authentication agent must also run in the niri
  # session to present the challenge (see hostclass/linux-workstation.nix);
  # then enable system authentication in 1Password's Settings → Security.
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };

  # LocalSend: cross-platform AirDrop alternative for moving files (e.g. iPhone
  # photos) over the LAN. openFirewall opens TCP+UDP 53317 for discovery and
  # transfers, which the active firewall would otherwise block.
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # niri 26.x spawns xwayland-satellite on demand when an X11 client connects,
  # but it expects the binary on $PATH. Without this, X11 apps (Steam, etc.)
  # cannot open a display under niri.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother";
        location = "Office";
        deviceUri = "ipp://brother-printer.internal/ipp/print";
        model = "everywhere";
        ppdOptions.PageSize = "Letter";
      }
    ];
    ensureDefaultPrinter = "Brother";
  };

  services.flatpak.enable = true;

  # Run the UDisks2 daemon so `udisksctl` (in the core package set) can mount
  # removable media without root; the CLI is just a client and does nothing
  # without the daemon's D-Bus service.
  services.udisks2.enable = true;

  # Keybase daemon + KBFS (~/keybase FUSE mount). keybase-gui (in the Linux GUI
  # package set) needs kbfsfuse present or it refuses to start.
  services.keybase.enable = true;
  services.kbfs.enable = true;

  # Upstream's kbfs.service sets PrivateTmp=true, which puts the unit in a
  # private mount namespace. A FUSE mount made there fails with EPERM and can't
  # propagate to the user session, so ~/keybase stays empty. Drop the namespace
  # so the mount lands in the session's namespace and is visible to the shell
  # and the Keybase GUI.
  systemd.user.services.kbfs.serviceConfig.PrivateTmp = lib.mkForce false;

  # Enable gnome-keyring for secrets service (org.freedesktop.secrets), but
  # launch it without the SSH component so 1Password handles SSH instead.
  services.gnome.gnome-keyring.enable = true;
  systemd.user.services.gnome-keyring = {
    serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --foreground --components=pkcs11,secrets"
    ];
  };

  # Mask gcr-ssh-agent so PAM doesn't export its socket as SSH_AUTH_SOCK and
  # shadow the 1Password agent. The gnome-keyring daemon above already runs
  # without its SSH component; this finishes the job for the gcr-shipped unit.
  systemd.user.services.gcr-ssh-agent.enable = false;
  systemd.user.sockets.gcr-ssh-agent.enable = false;
}
