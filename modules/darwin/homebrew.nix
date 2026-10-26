{
  config,
  lib,
  pkgs,
  ...
}:

{
  homebrew = {
    enable = true;

    greedyCasks = true;

    onActivation = {
      # "none" = don't remove anything not listed here
      # Change to "uninstall" once you've captured everything
      cleanup = "none";
      autoUpdate = true;
      upgrade = true;
      extraFlags = [ ];
    };

    # homebrew/cask-fonts was deprecated and emptied (font casks moved
    # into homebrew/cask), so tapping it now fails the whole bundle.
    taps = [
      "homebrew/services"
    ];

    brews = [
      # atuin now comes from nixpkgs (packages-core.nix) so macOS and Linux
      # run the same version and the same Ctrl-R widget.
      "dnstracer"
      "docker"
      "docker-credential-helper"
      "gnu-sed"
      "gnu-tar"
      "lazygit"
      "luarocks"
      "markdownlint-cli"
      "minijinja-cli"
      "mise"
      "oha"
      "openvpn"
      "pgloader"
      "postgresql@17"
      "rustup"
      "syncthing"
      "terraform"
      "wireguard-tools"
    ];

    casks = [
      "1password"
      "android-platform-tools"
      "arduino-ide"
      "atomic-wallet"
      "autodesk-fusion"
      "balenaetcher"
      "bambu-studio"
      "blender"
      "brave-browser"
      "carbon-copy-cloner"
      "claude"
      "claude-code"
      "discord"
      "docker-desktop"
      "epic-games"
      "font-hack-nerd-font"
      "freecad"
      "gimp"
      "godot"
      "hammerspoon"
      "inkscape"
      "iterm2"
      "kicad"
      "lens"
      "libreoffice"
      "librepcb"
      "maccy"
      "obsidian"
      "openscad@snapshot"
      "plex"
      "plexamp"
      "prusaslicer"
      "slack"
      "steam"
      "tailscale-app"
      "vimr"
      "visual-studio-code"
      "wifiman"
      "zed"
      "zoom"
    ];
  };
}
