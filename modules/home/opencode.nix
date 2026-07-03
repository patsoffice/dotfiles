{ config, ... }:

{
  # opencode — agentic terminal coding tool, configured for the chezlawrence
  # ollama server. Mutable symlink so edits to the JSON take effect without a
  # rebuild, same as the other dotfiles.
  xdg.configFile."opencode/opencode.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/opencode/opencode.json";
}
