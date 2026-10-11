{ config, ... }:

{
  # Zed — settings live in the repo so the ACP agent entries (muse-acp)
  # stay in sync with the packaged binaries. Mutable symlink so edits from
  # Zed's settings UI land back in the dotfiles without a rebuild, same as
  # the other dotfiles.
  xdg.configFile."zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/zed/settings.json";
}
