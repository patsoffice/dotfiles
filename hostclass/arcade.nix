{ pkgs, config, ... }:

{
  # Arcade machines use standard SSH keys, no 1Password agent

  # ── Git: use ssh-keygen for signing ────
  home.file.".gitconfig.local".text = ''
    [gpg "ssh"]
    	program = ${pkgs.openssh}/bin/ssh-keygen
  '';

  # Auto-start Sway on TTY1 login
  # shell.nix bypasses programs.zsh, so write .zprofile directly
  home.file.".zprofile".text = ''
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
      exec sway --unsupported-gpu
    fi
  '';

  wayland.windowManager.sway = {
    enable = true;
    extraOptions = [ "--unsupported-gpu" ];
    config = {
      modifier = "Mod4";
      terminal = "wezterm";
    };
  };
}
