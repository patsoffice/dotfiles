{ config, ... }:

{
  # ZSH configuration
  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/zsh/.zshrc";
  home.file.".zsh".source = config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/zsh/.zsh";

  # Direnv config (nix-direnv integration)
  xdg.configFile."direnv".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/direnv";


}
