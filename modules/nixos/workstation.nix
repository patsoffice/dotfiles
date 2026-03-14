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

  programs.firefox.enable = true;
  programs.niri.enable = true;

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
}
