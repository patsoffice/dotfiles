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

  # Disable GNOME Keyring SSH agent (use 1Password instead)
  services.gnome.gnome-keyring.enable = lib.mkForce false;
}
