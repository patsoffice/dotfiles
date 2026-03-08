{ pkgs, config, ... }:

{
  # Servers use standard SSH keys, no 1Password agent

  # ── Git: use ssh-keygen for signing ────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = ${pkgs.openssh}/bin/ssh-keygen
  '';
}
