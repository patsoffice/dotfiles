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

    taps = [
      "homebrew/cask-fonts"
      "homebrew/services"
      "patsoffice/tools"
    ];

    brews = [
      "atuin"
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
      "coolterm"
      "discord"
      "disk-inventory-x"
      "docker-desktop"
      "easyeda"
      "epic-games"
      "font-hack-nerd-font"
      "freecad"
      "gimp"
      "godot"
      "hammerspoon"
      "inkscape"
      "iterm2"
      "lens"
      "libreoffice"
      "librepcb"
      "maccy"
      "obsidian"
      "odrive"
      "openscad@snapshot"
      "plex"
      "plexamp"
      "prusaslicer"
      "slack"
      "steam"
      "tailscale-app"
      "unity"
      "unity-hub"
      "vimr"
      "visual-studio-code"
      "wifiman"
      "zoom"
    ];
  };
}
