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
    # 1Password GUI is installed system-wide via programs._1password-gui in
    # modules/nixos/workstation.nix (needed for its polkit unlock action), so
    # it's intentionally not listed here.
    blender
    brave
    freecad
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
    obsidian
    openscad
    thunderbird
    plexamp
    prusa-slicer
    signal-desktop
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
