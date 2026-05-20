{ config, pkgs, ... }:

{
  # Niri compositor config — copied into the store so it's available before
  # the greeter starts (mkOutOfStoreSymlink would be too late).
  xdg.configFile."niri/config.kdl".source = ../.. + "/configs/niri/config.kdl";
  xdg.configFile."niri/scripts".source = ../.. + "/configs/niri/scripts";

  services.flatpak = {
    enable = true;
    packages = [
    ];
  };

  home.packages = with pkgs; [
    # ── Compositor ─────────────────────────────────────────────────────
    dms-shell
    fuzzel
    niri
    quickshell
    wtype

    # ── Applications ───────────────────────────────────────────────────
    _1password-gui
    firefox-devedition
    keybase-gui
    thunderbird
    plexamp
    prusa-slicer
    vesktop

    # ── Clipboard ─────────────────────────────────────────────────────
    xclip
    xsel

    # ── Fonts ──────────────────────────────────────────────────────────
    nerd-fonts.hack
  ];
}
