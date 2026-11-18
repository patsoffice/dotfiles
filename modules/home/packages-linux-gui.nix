{ config, pkgs, ... }:

{
  # Niri compositor config — copied into the store so it's available before
  # the greeter starts (mkOutOfStoreSymlink would be too late).
  xdg.configFile."niri/config.kdl".source = ../.. + "/configs/niri/config.kdl";
  xdg.configFile."niri/scripts".source = ../.. + "/configs/niri/scripts";

  services.flatpak = {
    enable = true;
    packages = [
      # iMessage client. Not in nixpkgs (only bluebubbles is, and that one
      # still needs a Mac running the BlueBubbles server), so it comes from
      # Flathub instead. nix-flatpak defaults the remote to flathub.
      "app.openbubbles.OpenBubbles"
      # Eden (Nintendo Switch emulator, Yuzu successor). The nixpkgs
      # packaging PR (#406630) was closed unmerged, so it comes from
      # Flathub instead: flatpak install flathub dev.eden_emu.eden
      "dev.eden_emu.eden"
    ];
  };

  # Eden's Flatpak manifest grants no filesystem access, so expose the
  # Emulation library explicitly: ROMs in ~/Emulation/roms/<system>, keys and
  # firmware zips in ~/Emulation/bios. Merge mode (the default) keeps any
  # manually added overrides for other keys.
  services.flatpak.overrides.settings = {
    "dev.eden_emu.eden".Context.filesystems = [
      "${config.home.homeDirectory}/Emulation"
    ];
  };

  # Default handlers, migrated from the imperatively built ~/.config/mimeapps.list
  # so Home Manager owns the file going forward. force overwrites that file on
  # first switch; entries below preserve every association it had. Note the
  # tradeoff: GUI "set as default" changes get reverted on the next switch.
  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "text/html" = [ "brave-browser.desktop" ];
      "application/xhtml+xml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-htm" = [ "firefox-devedition.desktop" ];
      "application/x-extension-html" = [ "firefox-devedition.desktop" ];
      "application/x-extension-shtml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-xhtml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-xht" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "x-scheme-handler/chrome" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
      "x-scheme-handler/discord" = [ "vesktop.desktop" ];
      "x-scheme-handler/abc" = [ "plexamp.desktop" ];
      "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
    };
    associations.added = {
      "text/html" = [ "firefox-devedition.desktop" ];
      "application/xhtml+xml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-htm" = [ "firefox-devedition.desktop" ];
      "application/x-extension-html" = [ "firefox-devedition.desktop" ];
      "application/x-extension-shtml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-xhtml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-xht" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/http" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/https" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/chrome" = [ "firefox-devedition.desktop" ];
    };
  };

  home.packages = with pkgs; [
    # ── Compositor ─────────────────────────────────────────────────────
    dux-shell
    fuzzel
    niri
    quickshell
    wtype

    # ── Applications ───────────────────────────────────────────────────
    # 1Password GUI is installed system-wide via programs._1password-gui in
    # modules/nixos/workstation.nix (needed for its polkit unlock action), so
    # it's intentionally not listed here.
    blender
    brave
    freecad
    ghostty
    gimp
    godot
    inkscape
    # kicad's package.nix takes `stable ? true`, and callPackage fills that
    # argument from the pkgs set — where the overlay in lib/mkHost.nix binds
    # `stable` to the whole nixpkgs-stable package set. Pass the boolean
    # explicitly, or evaluation fails with "expected a Boolean but found a set".
    (kicad.override { stable = true; })
    keybase-gui
    libreoffice
    nautilus # GNOME Files; default inode/directory handler below
    obsidian
    openscad
    pdfcraft
    photocraft
    solidcraft
    thunderbird
    plexamp
    prusa-slicer
    signal-desktop
    simple-scan # scanner backend is in modules/nixos/workstation.nix
    unityhub # nixpkgs ships Unity Hub only; Unity editor installs through it
    vesktop

    # ── Clipboard ─────────────────────────────────────────────────────
    xclip
    xsel

    # ── Files ──────────────────────────────────────────────────────────
    glib # provides `gio`, used to mount SMB shares via gvfs (see workstation.nix)

    # ── Fonts ──────────────────────────────────────────────────────────
    nerd-fonts.hack
  ];
}
