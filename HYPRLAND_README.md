# Pinball cabinet on Hyprland

Notes from the bring-up of the `pinball` host running VPinFE + VPinballX on
Hyprland (originally Sway). Captures *why* each config decision exists so the
next person (or me in six months) doesn't re-discover each rabbit hole.

## TL;DR

- Compositor: **Hyprland 0.54.2** (not Sway -- see below).
- Frontend: **VPinFE "slim" release** (not the fat bundle -- see below).
- Browser: **google-chrome** from nixpkgs (NOT bundled chromium -- see below).
- Table launcher: nix-managed wrapper at `~/bin/vpinballx-wrapper` that
  clears `LD_LIBRARY_PATH` before exec'ing `VPinballX_BGFX`.
- Three displays: `HDMI-A-1` (4K playfield), `DP-1` (backglass), `DP-2` (DMD).

Branch: `hyprland-experiment` (once validated, merge to `main`).

## A note on NixOS and prebuilt binaries

Most of the pain below is amplified by NixOS not having a conventional
FHS layout. Prebuilt third-party binaries (PyInstaller bundles,
PyO3-style Python wheels with native libs, Electron apps, game binaries,
anything shipped by upstream as "just works on Linux") all assume a
system with `/lib`, `/lib64`, `/usr/lib`, a working dynamic linker at
`/lib64/ld-linux-x86-64.so.2`, and libraries reachable via default
search paths. NixOS has none of that -- every library lives in its own
`/nix/store/...` prefix, discoverable only via explicit `NIX_LDFLAGS`,
`LD_LIBRARY_PATH`, or an `autoPatchelfHook` pass.

The usual escape hatch is `pkgs.buildFHSEnv`, which creates a
bubblewrap sandbox with a synthetic FHS view (`/usr/lib`, `/bin`, etc.)
populated from nix-store paths. Every prebuilt binary on pinball is
wrapped that way:

- `vpinfe` -- `buildFHSEnv` with VPinballX runtime libs, GTK, fonts,
  google-chrome, dash.
- `VPinballX_BGFX` -- built in one `buildFHSEnv` (see `vpinball-nix`
  `shell.nix`), run in another (`release.nix`).
- `lgtvremote-cli` -- also packaged, though the Python stdlib is enough
  for it.

The FHS-env approach works, but comes with two recurring sharp edges
that you'll see throughout this document:

1. **Library pollution between sandboxes.** When a binary inside one
   FHS env spawns a child, the child inherits `LD_LIBRARY_PATH` from
   the parent. If the parent is a PyInstaller bundle that points
   `LD_LIBRARY_PATH` at its own `_internal/` directory (which is the
   whole point of PyInstaller), the child will try to load incompatible
   libs from there. This is why `vpinfe` couldn't spawn `VPinballX`
   without a `dash`-based wrapper that scrubs the env.
2. **Shell fragility under pollution.** The same library pollution
   makes bash a bad choice for wrapper scripts, because bash links
   `libreadline` at startup and happily finds the wrong version in
   `LD_LIBRARY_PATH` before executing a single line of your script.
   `dash` doesn't link readline, so it's the go-to interpreter for any
   wrapper that has to run inside a polluted env.

None of this would matter on Ubuntu or Arch where `/usr/lib` has
compatible system libs and prebuilt binaries just work. On NixOS, every
prebuilt binary is an adventure.

## Why Hyprland instead of Sway

VPinFE launches three headless Chromium kiosk windows via its Python
frontend. On Sway, this consistently hit a race in Sway's `xdg_surface`
handling:

```text
FATAL:ui/ozone/platform/wayland/host/xdg_surface.cc:64]
Check failed: !bounds.IsEmpty(). ... bounds=0,0 0x0
```

When a new Chromium window is reparented across outputs during creation
(via `assign` or `for_window move to output`), Chromium receives a
transient `0x0` `xdg_surface.configure` and aborts. Which of the three
windows crashes is non-deterministic. Workarounds we tried and that
didn't stick:

1. Sway `for_window move to output` instead of `assign` -- still crashed.
2. Deferred `exec swaymsg fullscreen enable` -- didn't matter; the race
   is in creation, not fullscreen.
3. `floating enable` on VPinFE windows to avoid tile reparenting -- still
   crashed.
4. Drop HDMI-A-1 to 1080p to rule out 4K/120Hz -- no difference.
5. Wrap Chromium in a dash shim that forces `--ozone-platform=x11` so it
   goes through XWayland -- kept Chromium alive but the table window's
   content still didn't render (see next section).

Hyprland handles the three Chromium-Wayland windows cleanly. No
`xdg_surface` crashes, no XWayland hacks required.

## Why the "slim" VPinFE release, not the fat one

The Revolution theme's `splash.html` has a branch for the table window
that plays a video (`splash.mp4` / `splash-rotated.mp4`) instead of an
image. The `splashVideo.play()` promise rejects if the video can't
decode, and the `.then()` aborts *before* registering the 15-second
fallback redirect. Result: table window hangs on the splash forever and
never navigates to the theme's `index_table.html`.

`ffprobe` on the bundled `splash.mp4` confirms:

```text
codec_name=h264
codec_name=aac
```

Both are proprietary codecs. The fat VPinFE release ships a FOSS
Chromium that has them stripped. The **slim** release (no bundled
Chromium) expects a system browser, so we can drop in google-chrome
from nixpkgs -- which ships H.264/AAC. Splash plays, redirect happens,
table window loads its theme index.

See `packages/vpinfe.nix`. The FHS env includes `google-chrome` and
`dash`.

## Why dash everywhere

VPinFE is a PyInstaller bundle. At runtime it sets `LD_LIBRARY_PATH` to
include its own `_internal/` directory (for its bundled Python and C
libs). Any child process inherits that, including shells VPinFE might
invoke or shell shebangs in wrappers we hand it.

The bundle includes a `libreadline.so.8` that's incompatible with the
bash on our FHS env. So `#!/bin/sh` (bash) in any wrapper aborts:

```text
/bin/sh: symbol lookup error: /bin/sh: undefined symbol: rl_completion_rewrite_hook
```

`dash` doesn't link readline. We use it in:

- The VPinballX launch wrapper (see below).
- (Previously) a Chrome shim we no longer need after the Sway-to-Hyprland
  switch, but dash stays in the FHS env for the wrapper.

## The VPinballX launch wrapper

Even after switching to the slim VPinFE with google-chrome, launching a
table silently did nothing. VPinballX would spawn, run for ~13 seconds,
exit without rendering. Running the same binary directly from wezterm
(inside the vpinball-nix `release.nix` FHS env) worked fine.

Root cause: the same `LD_LIBRARY_PATH` pollution. VPinFE spawns
`VPinballX_BGFX` as a child, which inherits VPinFE's polluted env.
VPinballX picks up an incompatible `libstdc++` / `libssl` / etc. from
`vpinfe/_internal/` and silently fails.

Fix: wrap VPinballX with `~/bin/vpinballx-wrapper` (nix-managed via
`home.file` in `hosts/pinball/home.nix`). The wrapper:

1. Uses `#!${pkgs.dash}/bin/dash` so the shell itself doesn't fail on
   the polluted env.
2. Logs its invocation (args, full env, stderr) to
   `~/.cache/vpinballx-wrapper/*.log` -- invaluable for debugging.
3. `unset`s `LD_LIBRARY_PATH`, `LD_PRELOAD`, `PYTHONHOME`, `PYTHONPATH`.
4. `exec`s the real `/home/pjl/ws/vpinball/build/VPinballX_BGFX` with
   the cleaned env.

`vpinfe.ini`'s `vpxbinpath` points at `/home/pjl/bin/vpinballx-wrapper`.

## Hyprland 0.54.2 syntax gotchas

Hyprland 0.54.2 unified `windowrule` and `windowrulev2` into a single
`windowrule` keyword with a new format:

- **Action takes a value**: `float true`, `fullscreen true`.
- **Matcher prefix is `match:`** followed by a space (not a colon):
  `match:title VPinFE BG`, not `title:^(VPinFE BG)$`.
- **No regex anchors**: `match:title VPinFE BG` matches -- adding
  `^(...)$` causes the rule to silently not fire.

Example from `hosts/pinball/home.nix`:

```nix
windowrule = [
  "workspace 1 silent, match:title VPinFE Table"
  "fullscreen true, match:title VPinFE Table"
  "workspace 2 silent, match:title VPinFE BG"
  "fullscreen true, match:title VPinFE BG"
  # ...
];
```

Workspaces pinned to outputs via `workspace = [...]` with
`monitor:NAME` in the workspace definition. Hyprland's windowrule
action set does NOT include `monitor` -- you route via
`workspace N silent` where workspace N is pinned to the target output.

Enable config logging during bring-up so parse errors land in the log
instead of just on screen:

```nix
debug.disable_logs = false;
```

## Display layout

Left to right in Hyprland monitor positions:

| Monitor | Role | Mode | Position |
|---|---|---|---|
| `HDMI-A-1` | Playfield (LG 4K TV) | `3840x2160@119.88` | `0x0` |
| `DP-1` | Backglass | `1920x1080@60` | `3840x0` |
| `DP-2` | DMD / Score | `1920x1080@60` | `5760x0` |

Workspace to output pinning:

- `ws1` -> `HDMI-A-1`
- `ws2` -> `DP-1`
- `ws3` -> `DP-2`

Window routing (VPinFE + VPinballX share the same workspace/output
mapping by title):

- `VPinFE Table`, `Visual Pinball Player` -> ws1 (HDMI-A-1)
- `VPinFE BG`, `Visual Pinball Backglass` -> ws2 (DP-1)
- `VPinFE DMD`, `Visual Pinball Score View` -> ws3 (DP-2)

## DudesCab HID controller

The DudesCab exposes both a USB HID joystick interface (for the game
buttons) and an HID keyboard interface. By default Hyprland (and Sway)
grabs the keyboard interface, which prevents SDL from reading the
joystick interface directly. Fix:

```nix
device = [
  {
    name = "l'atelier-d'arnoz-dudescab";
    enabled = false;
  }
];
```

(Note: Hyprland's device name is the libinput name lowercased with
spaces replaced by hyphens. Use `hyprctl devices` to discover the exact
name for a controller.)

Also required at the system level (in `hosts/pinball/default.nix`):

- `services.udev.extraRules` giving the `input` group access to
  `/dev/hidraw*` for the DudesCab's vendor/product ID.
- The user is a member of `input` via `modules/nixos/arcade.nix`.

## LG TV power-on poll

The LG TV powers off when the cabinet is not in use. If the TV is off
when the compositor starts, `HDMI-A-1` may not be configured and the
playfield window ends up invisible. `.zprofile` polls `lgtv
power-status` up to 10 times (2s intervals), sending `lgtv on` between
attempts, before exec'ing Hyprland. Skipped if `~/.config/lgtvremote/
devices.json` doesn't exist yet (pre-pairing).

See `hosts/pinball/home.nix`.

## Cursor auto-hide

```nix
cursor = {
  inactive_timeout = 5;
  hide_on_key_press = true;
};
```

## File map

- `packages/vpinfe.nix` -- slim VPinFE release in a `buildFHSEnv` with
  the Visual Pinball runtime libs + google-chrome + dash.
- `hosts/pinball/default.nix` -- NixOS side: enables Hyprland (disables
  Sway), adds dash and vpinfe to `systemPackages`, udev rules, firewall
  port 8001 for the Manager UI, the lgtv-power systemd service.
- `hosts/pinball/home.nix` -- home-manager side: the entire Hyprland
  config (outputs, workspaces, windowrules, input, cursor),
  `.zprofile`, and the `vpinballx-wrapper` file.
- `modules/nixos/base.nix` -- `google-chrome` in the unfree allowlist.
- `modules/nixos/arcade.nix` -- `input` + `dialout` groups for the user
  (shared across arcade machines).

## Debugging cheat sheet

```bash
# Hyprland main log (config errors DO NOT land here)
find /run/user/$(id -u)/hypr/ -name hyprland.log

# Live cursor on VPinFE logs
tail -f ~/.config/vpinfe/vpinfe.log

# VPinballX wrapper logs (one per launch)
ls -t ~/.cache/vpinballx-wrapper/
tail ~/.cache/vpinballx-wrapper/$(ls -t ~/.cache/vpinballx-wrapper/ | head -1)

# Where are windows?
hyprctl clients
hyprctl clients -j | jq -r '.[] | "\(.title) ws=\(.workspace.name) mon=\(.monitor) fs=\(.fullscreen)"'

# Input devices Hyprland sees (for the device-disable name)
hyprctl devices

# VPinFE Manager UI from another machine
http://pinball:8001
```
