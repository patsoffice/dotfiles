{ config, ... }:

{
  # Hammerspoon
  home.file.".hammerspoon/init.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/hammerspoon/init.lua";
}
