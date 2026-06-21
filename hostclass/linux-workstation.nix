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

  # GTK GSettings schemas for the graphical session. The niri session runs Qt
  # apps with the gtk3 platform theme (QT_QPA_PLATFORMTHEME=gtk3), so opening a
  # native GTK file chooser — e.g. FreeCAD's Save As — instantiates
  # org.gtk.Settings.FileChooser via GSettings. The session's XDG_DATA_DIRS does
  # not include the gtk3/gsettings-desktop-schemas schema dirs, so g_settings_new()
  # treats the schema as missing and abort()s (SIGABRT). Prepend the schema dirs
  # here so systemd-launched GUI apps can find them. Same environment.d rationale
  # as the SSH_AUTH_SOCK file above: GUI apps launched outside an interactive
  # shell don't source the login profile.
  xdg.configFile."environment.d/20-gsettings-schemas.conf".text = ''
    XDG_DATA_DIRS=${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:''${XDG_DATA_DIRS}
  '';

  # Polkit authentication agent for the niri session. Full desktops (GNOME/KDE)
  # start one automatically, but niri does not — without it, any polkit action
  # that needs interactive auth (1Password's "Unlock using system
  # authentication", fprintd-enroll, disk mounts, etc.) is denied because there
  # is nothing to present the password/fingerprint prompt. The agent runs the
  # PAM conversation for the polkit-1 service, which includes pam_fprintd, so
  # the prompt accepts the enrolled fingerprint.
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      Type = "exec";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
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
