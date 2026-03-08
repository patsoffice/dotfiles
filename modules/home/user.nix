{
  config,
  pkgs,
  lib,
  ...
}:

let
  homePrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
in
{
  home.username = config.my.user.name;
  home.homeDirectory = "${homePrefix}/${config.my.user.name}";
  home.stateVersion = config.my.user.stateVersion;
  my.dotfilesPath = lib.mkDefault "${config.home.homeDirectory}/ws/dotfiles/configs";
}
