{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable zsh as a valid login shell
  programs.zsh.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
