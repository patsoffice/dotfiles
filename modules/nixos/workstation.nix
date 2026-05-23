{
  config,
  lib,
  pkgs,
  dms,
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

  hardware.bluetooth.enable = true;

  programs.firefox.enable = true;
  programs.niri.enable = true;

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
