{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  # Declare the primary user so home-manager and homebrew can resolve the user
  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  # Enable zsh as a valid login shell
  programs.zsh.enable = true;

  # Determinate Systems manages the Nix daemon; disable nix-darwin's management
  nix.enable = false;

  system.stateVersion = 6;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
      "claude-code"
      "discord"
      "plexamp"
      "prusa-slicer"
      "vscode"
    ];
}
