{ pkgs, config, ... }:

{
  home.username = "pjl";
  home.homeDirectory = "/home/pjl";
  home.stateVersion = "25.11";

  my.dotfilesPath = "${config.home.homeDirectory}/ws/dotfiles/configs";

  # Use 1Password SSH agent
  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
  };

  # Linux-specific packages
  home.packages = with pkgs; [
  ];

  # ── Git: use ssh-keygen for signing (no 1Password on Linux) ────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = ${pkgs.openssh}/bin/ssh-keygen
  '';

  # ── SSH: override 1Password IdentityAgent ──────────────────────
  # The shared SSH config sets IdentityAgent to the macOS 1Password socket.
  # On Linux, use the standard SSH agent so agent forwarding works.
  home.file.".ssh/config.local".text = ''
    Host *
    	IdentityAgent ~/.1password/agent.sock
    	IdentitiesOnly no
  '';
}
