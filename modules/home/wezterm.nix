{ config, ... }:

{
  # WezTerm
  home.file.".wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/wezterm/.wezterm.lua";
}
