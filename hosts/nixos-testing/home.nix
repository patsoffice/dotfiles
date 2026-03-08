{
  pkgs,
  config,
  lib,
  ...
}:

{
  # NOTE: This file is not currently imported in flake.nix
  # It can be used for VM-specific overrides if needed

  home.homeDirectory = lib.mkForce "/home/pjl";
  my.dotfilesPath = "${config.home.homeDirectory}/ws/dotfiles/configs";

  # NixOS VM-specific packages
  home.packages = with pkgs; [
  ];

  # ── Git: use ssh-keygen for signing (works with forwarded 1Password agent) ──
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = ${pkgs.openssh}/bin/ssh-keygen

    [commit]
    	gpgsign = true
  '';

  # ── SSH: use forwarded agent from 1Password ────────────────────
  home.file.".ssh/config.local".text = ''
    # VM override — use forwarded 1Password SSH agent via SSH_AUTH_SOCK
    Host *
    	IdentityAgent $SSH_AUTH_SOCK
    	IdentitiesOnly no
  '';
}
