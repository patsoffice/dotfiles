{ config, ... }:

{
  # ZSH configuration
  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/zsh/.zshrc";
  home.file.".zsh".source = config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/zsh/.zsh";

  # Direnv config (nix-direnv integration)
  xdg.configFile."direnv".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/direnv";

  # Atuin config. Only config.toml is linked — atuin keeps history.db and its
  # sync key in the same directory and those must stay machine-local.
  xdg.configFile."atuin/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/atuin/config.toml";

}
