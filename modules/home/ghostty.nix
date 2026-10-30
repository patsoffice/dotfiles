{ config, ... }:

{
  # Ghostty — settings live in the repo so they stay in sync across
  # machines. Mutable symlink so edits from the app land back in the
  # dotfiles without a rebuild, same as the other dotfiles.
  xdg.configFile."ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/ghostty/config";
}
