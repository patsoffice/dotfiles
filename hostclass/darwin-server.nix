{ pkgs, ... }:

{
  # Servers use standard SSH keys, no 1Password agent
  # (mirrors linux-server: no 1Password app on server hosts)

  # ── Git: use ssh-keygen for signing ────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = ${pkgs.openssh}/bin/ssh-keygen
  '';
}
