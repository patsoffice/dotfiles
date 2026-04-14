{ lib, pkgs, ... }:

{
  # Pinball cabinet Sway configuration (experimental — re-testing Sway
  # now that VPinFE uses system google-chrome via the slim release,
  # which should avoid the Chromium/Wayland xdg_surface race that
  # drove the original switch to Hyprland).

  wayland.windowManager.sway.extraOptions = [ "--unsupported-gpu" ];

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

  # Auto-start Sway on TTY1 login.
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
      exec sway --unsupported-gpu
    fi
  '';

  wayland.windowManager.sway.config = {
    # No status bar — this is a cabinet, not a desktop.
    bars = [ ];

    # Prevent mouse drift between displays from stealing focus from the
    # playfield.
    focus.followMouse = false;

    # Dude's Cab exposes a keyboard HID interface that Sway grabs by
    # default, preventing SDL/VPinball from reading its joystick
    # interface directly. Disabling the input here lets SDL see the
    # controller via /dev/input/js0.
    input = {
      "11914:4207:L'atelier_d'Arnoz_DudesCab" = {
        events = "disabled";
      };
    };

    # Display layout, left to right: HDMI-A-1 (4K playfield), DP-1
    # (backglass), DP-2 (DMD). Explicit positioning keeps output
    # ordering deterministic regardless of which display initializes
    # first.
    output = {
      "HDMI-A-1" = {
        mode = "3840x2160@119.880Hz";
        position = "0 0";
      };
      "DP-1" = {
        mode = "1920x1080@60Hz";
        position = "3840 0";
      };
      "DP-2" = {
        mode = "1920x1080@60Hz";
        position = "5760 0";
      };
    };

    # Pin workspaces to outputs:
    #   ws1 → HDMI-A-1 (playfield)
    #   ws2 → DP-1    (backglass)
    #   ws3 → DP-2    (DMD)
    workspaceOutputAssign = [
      { workspace = "1"; output = "HDMI-A-1"; }
      { workspace = "2"; output = "DP-1"; }
      { workspace = "3"; output = "DP-2"; }
    ];

    # Route VPinFE front-end and VPinballX in-game windows to their
    # target workspaces at creation time. The original Sway breakage
    # was caused by vpinfe's bundled FOSS chromium racing on
    # xdg_surface.configure during cross-output reparenting. With the
    # slim VPinFE release, VPinFE now spawns system google-chrome,
    # which may handle this more gracefully.
    assigns = {
      "1" = [
        { title = "^VPinFE Table$"; }
        { title = "^Visual Pinball Player$"; }
      ];
      "2" = [
        { title = "^VPinFE BG$"; }
        { title = "^Visual Pinball Backglass$"; }
      ];
      "3" = [
        { title = "^VPinFE DMD$"; }
        { title = "^Visual Pinball Score View$"; }
      ];
    };

    # Force focus to the playfield window when it appears.
    window.commands = [
      { criteria = { title = "^VPinFE Table$"; }; command = "focus"; }
      { criteria = { title = "^Visual Pinball Player$"; }; command = "focus"; }
    ];

    # Launch vpinfe automatically at startup. Note: on Sway the three
    # chromium kiosk windows vpinfe spawns hit a crashpad init race and
    # one dies with SIGTRAP on most launches (warm or cold). `strace`
    # and `taskset -c 0` appear to mask it sporadically but neither is
    # reliable in practice. If the race is killing you, switch to the
    # Hyprland branch where it doesn't fire. See docs/SWAY_README.md.
    startup = [
      { command = "${pkgs.vpinfe}/bin/vpinfe"; }
    ];
  };
}
