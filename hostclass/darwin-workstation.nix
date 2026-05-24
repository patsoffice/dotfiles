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
  # NOTE: OpenSSH 10.2+ rejects included config files that are world-readable
  # or not owned by the user. We write this directly (not via Nix store symlink)
  # so the file is owned by the user with mode 0600.
  home.activation.sshConfigLocal = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    rm -f "$HOME/.ssh/config.local"
    cat > "$HOME/.ssh/config.local" << EOF
    Host *
    	IdentityAgent "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    	IdentitiesOnly no
    EOF
    chmod 0600 "$HOME/.ssh/config.local"
  '';

  # ── Git: use 1Password for SSH commit signing ──────────────────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
  '';
}
