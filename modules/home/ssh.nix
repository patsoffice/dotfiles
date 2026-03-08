{ config, ... }:

{
  # SSH config
  home.file.".ssh/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/ssh/config";
}
