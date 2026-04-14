{ lib, pkgs, ... }:

{
  # Pinball cabinet Hyprland configuration (experimental).
  # The arcade hostclass enables Sway via home-manager; override here.
  wayland.windowManager.sway.enable = lib.mkForce false;

  # VPinFE spawns VPinballX_BGFX with its own LD_LIBRARY_PATH polluted
  # by the PyInstaller bundle's _internal/ dir, which makes VPinballX
  # silently fail to find its runtime libs. This wrapper clears the
  # polluted env vars and captures stderr to a log before exec'ing
  # the real binary.
  #
  # Uses dash because bash's /bin/sh startup loads libreadline, and
  # VPinFE's polluted LD_LIBRARY_PATH makes it pick an incompatible
  # version. Dash doesn't link readline.
  #
  # Point vpinfe.ini's vpxbinpath at ~/bin/vpinballx-wrapper.
  home.file."bin/vpinballx-wrapper" = {
    executable = true;
    text = ''
      #!${pkgs.dash}/bin/dash
      LOGDIR="$HOME/.cache/vpinballx-wrapper"
      mkdir -p "$LOGDIR"
      LOG="$LOGDIR/$(date +%Y%m%dT%H%M%S).log"
      {
        echo "=== vpinballx-wrapper $(date -Iseconds) ==="
        echo "=== args ==="
        i=1
        for a in "$@"; do echo "$i: $a"; i=$((i+1)); done
        echo "=== env (before cleanup) ==="
        env | sort
        echo "=== launching VPinballX ==="
      } > "$LOG" 2>&1

      unset LD_LIBRARY_PATH LD_PRELOAD PYTHONHOME PYTHONPATH

      exec /home/pjl/ws/vpinball/build/VPinballX_BGFX "$@" >> "$LOG" 2>&1
    '';
  };

  # Auto-start Hyprland on TTY1 login (overrides the arcade hostclass
  # .zprofile that starts Sway).
  home.file.".zprofile".text = lib.mkForce ''
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
      # Ensure the LG TV (playfield) is powered on before starting the
      # compositor. If the TV is off, the HDMI-A-1 output won't configure
      # and the playfield window will be invisible. Skip if lgtvremote
      # has not been paired yet (no devices.json).
      if [ -f "$HOME/.config/lgtvremote/devices.json" ]; then
        for i in 1 2 3 4 5 6 7 8 9 10; do
          if lgtv power-status 2>/dev/null | grep -q '"power": *"on"'; then
            break
          fi
          lgtv on 2>/dev/null || true
          sleep 2
        done
      fi
      exec Hyprland
    fi
  '';

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      debug.disable_logs = false;

      # Hide the cursor when idle — this is a cabinet, not a desktop.
      cursor = {
        inactive_timeout = 5;
        hide_on_key_press = true;
      };

      # NVIDIA-friendly env vars.
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];

      # Display layout, left to right: HDMI-A-1 (4K playfield), DP-1
      # (backglass), DP-2 (DMD).
      monitor = [
        "HDMI-A-1,3840x2160@119.88,0x0,1"
        "DP-1,1920x1080@60,3840x0,1"
        "DP-2,1920x1080@60,5760x0,1"
      ];

      # Pin workspaces to outputs:
      #   ws1 → HDMI-A-1 (playfield)
      #   ws2 → DP-1    (backglass)
      #   ws3 → DP-2    (DMD)
      workspace = [
        "1, monitor:HDMI-A-1, default:true"
        "2, monitor:DP-1"
        "3, monitor:DP-2"
      ];

      # Launch swaybg as the desktop background (Hyprland itself
      # doesn't paint one), then launch vpinfe.
      exec-once = [
        "${pkgs.swaybg}/bin/swaybg -i ${./assets/pinball-neon.jpg} -m fit"
        "${pkgs.vpinfe}/bin/vpinfe"
      ];

      # Minimal keybinds — the cabinet is keyboardless in normal use,
      # but these let us recover during bring-up.
      "$mod" = "SUPER";
      bind = [
        "$mod, Return, exec, ${pkgs.wezterm}/bin/wezterm"
        "$mod, Q, killactive,"
        "$mod SHIFT, E, exit,"
      ];

      # No focus-follows-mouse so mouse drift between displays can't
      # steal focus from the playfield.
      input = {
        follow_mouse = 0;
      };

      # DudesCab keyboard HID grab makes SDL unable to read the joystick
      # interface. Disable Hyprland's input handling for it so events
      # pass through to /dev/input/js0.
      device = [
        {
          name = "l'atelier-d'arnoz-dudescab";
          enabled = false;
        }
      ];

      # Route VPinFE front-end and VPinballX in-game windows to their
      # target workspaces (each pinned to one output) and fullscreen them.
      # Hyprland 0.54.2 syntax: actions take explicit values, matchers
      # use `match:FIELD REGEX` (space, not colon, no `^(...)$` anchors).
      windowrule = [
        "workspace 1 silent, match:title VPinFE Table"
        "fullscreen true, match:title VPinFE Table"
        "workspace 2 silent, match:title VPinFE BG"
        "fullscreen true, match:title VPinFE BG"
        "workspace 3 silent, match:title VPinFE DMD"
        "fullscreen true, match:title VPinFE DMD"

        "workspace 1 silent, match:title Visual Pinball Player"
        "fullscreen true, match:title Visual Pinball Player"
        "workspace 2 silent, match:title Visual Pinball Backglass"
        "fullscreen true, match:title Visual Pinball Backglass"
        "workspace 3 silent, match:title Visual Pinball Score View"
        "fullscreen true, match:title Visual Pinball Score View"
      ];
    };
  };
}
