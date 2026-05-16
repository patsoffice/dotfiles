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
  services.printing.enable = true;

  services.flatpak.enable = true;

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
