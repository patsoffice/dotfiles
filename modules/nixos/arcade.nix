{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Arcade/kiosk system configuration
  # GUI-capable but minimal — no desktop environment, printing, or flatpak
  # Wayland-native — no X11

  # Sway (Wayland compositor)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Auto-login to a TTY, then start Sway automatically
  services.getty.autologinUser = "pjl";

  # Audio support for game sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # GPU drivers
  hardware.graphics.enable = true;
}
