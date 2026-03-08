{ pkgs, config, ... }:

{
  # Use 1Password SSH agent (macOS path)
  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # ── Git: use 1Password for SSH commit signing ──────────────────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
  '';
}
