{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.hack
    usbutils
    p7zip
    unrar
    unzip
    wezterm

    # ── Emulators ──────────────────────────────────────────────────────
    mame
  ];
}
