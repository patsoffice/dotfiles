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
      input = {
        "11914:4207:L'atelier_d'Arnoz_DudesCab" = {
          events = "disabled";
        };
      };
      output = {
        "HDMI-A-1" = {
          mode = "3840x2160@119.880Hz";
        };
      };
      window.commands = [
        { criteria = { title = "Visual Pinball Player"; }; command = "move to output HDMI-A-1"; }
        { criteria = { title = "Visual Pinball Player"; }; command = ''exec swaymsg '[title="Visual Pinball Player"] fullscreen enable; [title="Visual Pinball Player"] focus' ''; }
        { criteria = { title = "Visual Pinball Backglass"; }; command = "move to output DP-1"; }
        { criteria = { title = "Visual Pinball Backglass"; }; command = ''exec swaymsg '[title="Visual Pinball Backglass"] fullscreen enable' ''; }
        { criteria = { title = "Visual Pinball Score View"; }; command = "move to output DP-2"; }
        { criteria = { title = "Visual Pinball Score View"; }; command = ''exec swaymsg '[title="Visual Pinball Score View"] fullscreen enable' ''; }
      ];
    };
  };
}
