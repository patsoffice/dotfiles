{ config, pkgs, ... }:

{
  # Niri compositor config
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/niri/config.kdl";
  xdg.configFile."niri/scripts".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/niri/scripts";

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
    geary
    plexamp
    prusa-slicer

    # ── Clipboard ─────────────────────────────────────────────────────
    xclip
    xsel

    # ── Fonts ──────────────────────────────────────────────────────────
    nerd-fonts.hack
  ];
}
