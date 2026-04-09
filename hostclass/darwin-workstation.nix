{ pkgs, config, ... }:

{
  imports = [
    ../modules/home/hammerspoon.nix
  ];

  # Use 1Password SSH agent (macOS path)
  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # ── SSH: set 1Password IdentityAgent for macOS ─────────────────
  home.file.".ssh/config.local".text = ''
    Host *
    	IdentityAgent "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    	IdentitiesOnly no
  '';

  # ── Git: use 1Password for SSH commit signing ──────────────────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
  '';
}
