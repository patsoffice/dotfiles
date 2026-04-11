{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.hack
    p7zip
    unrar
    unzip
    wezterm
  ];
}
