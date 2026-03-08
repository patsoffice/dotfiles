{ pkgs, config, ... }:

{
  # Use 1Password SSH agent
  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
  };

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
  home.file.".ssh/config.local".text = ''
    Host *
    	IdentityAgent ~/.1password/agent.sock
    	IdentitiesOnly no
  '';
}
