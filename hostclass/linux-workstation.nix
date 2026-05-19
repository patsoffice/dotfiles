{ pkgs, config, ... }:

{
  # Use 1Password SSH agent
  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
  };

  # Also export to systemd --user so GUI apps (VSCode, etc.) launched outside
  # an interactive shell inherit SSH_AUTH_SOCK. environment.d files do not
  # expand systemd unit specifiers like %h, so bake the path in at Nix-eval
  # time instead.
  xdg.configFile."environment.d/10-ssh-auth-sock.conf".text = ''
    SSH_AUTH_SOCK=${config.home.homeDirectory}/.1password/agent.sock
  '';

  # Start 1Password at login so the SSH agent socket is available immediately
  systemd.user.services."1password-ssh-agent" = {
    Unit = {
      Description = "1Password SSH Agent";
      After = [ "graphical-session.target" ];
      StartLimitBurst = 3;
      StartLimitIntervalSec = 30;
    };
    Service = {
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Restart = "on-failure";
      RestartSec = 5;
      Type = "exec";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # ── Git: use ssh-keygen for signing (no 1Password on Linux) ────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = ${pkgs.openssh}/bin/ssh-keygen
  '';

  # ── SSH: override 1Password IdentityAgent ──────────────────────
  # The shared SSH config sets IdentityAgent to the macOS 1Password socket.
  # On Linux, use the standard SSH agent so agent forwarding works.
  # NOTE: OpenSSH 10.2+ rejects included config files that are world-readable
  # or not owned by the user. We write this directly (not via Nix store symlink)
  # so the file is owned by the user with mode 0600.
  home.activation.sshConfigLocal = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    rm -f "$HOME/.ssh/config.local"
    install -m 0600 /dev/stdin "$HOME/.ssh/config.local" << 'EOF'
    Host *
    	IdentityAgent ~/.1password/agent.sock
    	IdentitiesOnly no
    EOF
  '';
}
