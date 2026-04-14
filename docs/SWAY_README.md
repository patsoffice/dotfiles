# Pinball cabinet on Sway (ABANDONED experiment)

> **Branch note:** this document lives on the `sway-experimental` branch.
> The experiment is **abandoned**: Sway + VPinFE hits a chromium crashpad
> fork race that no environmental workaround reliably masks. The default
> and recommended pinball compositor is Hyprland — see
> `HYPRLAND_README.md`. This document is kept as a record of what was
> tried, what I learned, and why I gave up. It will be cherry-picked
> into `main` as reference material.

## TL;DR

- **Sway + VPinFE is not usable on this cabinet.** On most launches, one
  of the three chromium kiosk windows vpinfe spawns dies during
  `crashpad` init with `SIGTRAP`, and the frontend tears down.
- The root cause is a **timing race** in chromium's crashpad
  sibling-process introspection that fires under Sway but not under
  Hyprland, apparently because of differences in event-loop scheduling.
- **`taskset -c 0 vpinfe` works sporadically** — maybe one launch in
  three or four — but the race still fires often enough (cold and warm)
  that it's not acceptable for a kiosk.
- **`strace -fv vpinfe` masks the race completely**, which is how I
  confirmed it's timing-sensitive.
- Nothing else I tested mattered (chrome args, `LD_LIBRARY_PATH`,
  user-data-dir pattern, Python-parent spawning, wlroots version).

## The problem

On Sway with default scheduling, launching VPinFE causes one of its
three chromium kiosk windows to die during crashpad initialisation
with:

```text
[ERROR:.../crashpad/snapshot/elf/elf_dynamic_array_reader.h:64] tag not found
[ERROR:.../crashpad/util/process/process_memory_range.cc:75] read out of range
Window 'bg' exited (code -5)
```

Which window dies (`bg`, `dmd`, or `table`) is non-deterministic. Once
the first dies, VPinFE tears down the remaining two and the cabinet is
left with just wezterm on screen.

## What it is NOT

I ruled out every config difference I could think of:

- Not the chrome args — manually replicating all 30+ vpinfe flags works
- Not `LD_LIBRARY_PATH` pollution — simulating it with
  `LD_LIBRARY_PATH=.../_internal` and a plain chrome run works
- Not the kiosk / user-data-dir pattern — three parallel chromes with
  distinct `--user-data-dir` values launched from a shell work
- Not spawning from a Python parent — Python `subprocess.Popen` also
  works when done manually
- Not the compositor's wayland protocol (Sway and Hyprland use the same
  wlroots backend set)

## What it IS

A **timing race** between chromium helper processes during crashpad
initialisation. When vpinfe forks three chromium windows in quick
succession, crashpad's handler in one process tries to
`process_vm_readv` a sibling process's `/proc/self/maps`-derived address
range which is being mid-unmapped by the sibling's own fork teardown.
Reading out of a transiently-unmapped page returns the "read out of
range" error, which propagates up to crashpad's
`elf_dynamic_array_reader.h` and ultimately aborts the process.

Under Hyprland the race doesn't fire — different event-loop timing on
the compositor side. Under Sway on default scheduling it fires on most
launches (somewhere between 60-80% in my testing).

**Two things demonstrably mask the race, proving it's timing:**

1. Running vpinfe under `strace -fv` — the syscall tracing slows fork
   enough that the race window closes. Masks 100% of the time I've
   tried it.
2. Pinning vpinfe to a single core with `taskset -c 0` — serialises
   the fork sequence so sibling chromium processes never overlap during
   crashpad init. **Works sporadically, maybe 25-50% of the time.** Not
   acceptable for a kiosk that reboots into the frontend.

## What I tried

These live as historical comments in `hosts/pinball/home.nix` and
`HYPRLAND_README.md`. None are currently active.

### `taskset -c 0 vpinfe` startup command

```nix
# hosts/pinball/home.nix — tried, removed because unreliable
startup = [
  { command = "${pkgs.util-linux}/bin/taskset -c 0 ${pkgs.vpinfe}/bin/vpinfe"; }
];
```

The accompanying `vpinballx-wrapper` used to re-pin to all cores via
`taskset -c 0-$LAST_CORE` before exec'ing `VPinballX_BGFX`, so game
performance wouldn't suffer from the single-core constraint leaking
through to the table renderer.

Initial manual testing suggested it worked, but subsequent reboots —
both cold and warm — showed that it masks the race only
intermittently. Eventually gave up.

### `sleep N; vpinfe`

Tried `sleep 5` before vpinfe on the theory that the LG TV's HDMI
handshake and KMS settling were contributing to the timing window. Did
not change the failure rate.

### Patching VPinFE

The cleanest fix would be a small delay between chrome spawns in
VPinFE's `chromium_manager.py` — something like `time.sleep(0.5)`
between the three `subprocess.Popen` calls — but that means carrying a
local fork or pushing upstream. Not worth it for an abandoned
experiment when Hyprland already works.

## Current state of this branch

The Sway config is kept intact as a reference implementation minus the
workaround: `startup` is a plain `vpinfe` call, and the
`vpinballx-wrapper` no longer has the counter-`taskset` logic. So if
you check out this branch and `just switch`, you'll have a working
Sway session but VPinFE will crash on most launches due to the race.

```nix
startup = [
  { command = "${pkgs.vpinfe}/bin/vpinfe"; }
];
```

## Rendered Sway config (post-workaround removal)

For reference, here are the relevant portions of the generated
`~/.config/sway/config` the home-manager module produces (default
keybinds, resize mode, and other boilerplate are omitted; store-path
hashes are elided):

```text
input "11914:4207:L'atelier_d'Arnoz_DudesCab" {
  events disabled
}

output "DP-1" {
  mode 1920x1080@60Hz
  position 3840 0
}

output "DP-2" {
  mode 1920x1080@60Hz
  position 5760 0
}

output "HDMI-A-1" {
  mode 3840x2160@119.880Hz
  position 0 0
}

assign [title="^VPinFE Table$"] 1
assign [title="^Visual Pinball Player$"] 1
assign [title="^VPinFE BG$"] 2
assign [title="^Visual Pinball Backglass$"] 2
assign [title="^VPinFE DMD$"] 3
assign [title="^Visual Pinball Score View$"] 3
for_window [title="^VPinFE Table$"] focus
for_window [title="^Visual Pinball Player$"] focus
exec /nix/store/...-vpinfe-1.1.56/bin/vpinfe

workspace "1" output "HDMI-A-1"
workspace "2" output "DP-1"
workspace "3" output "DP-2"
```

## File map (Sway-specific bits)

- `hosts/pinball/default.nix` -- inherits Sway from the arcade
  hostclass; no `programs.hyprland` enablement.
- `hosts/pinball/home.nix` -- full Sway home-manager config: outputs,
  workspace pinning, assigns for VPinFE/VPinballX titles, focus rules,
  `.zprofile`, and the `vpinballx-wrapper`.
- Everything else (the vpinfe package, the unfree allowlist, etc.) is
  identical to the Hyprland branch. See `HYPRLAND_README.md` for the
  non-Sway-specific bits.

## Debugging cheat sheet

```bash
# See whether vpinfe is actually running
pgrep -af vpinfe

# Look at vpinfe's log for the crashpad errors
tail -50 ~/.config/vpinfe/vpinfe.log

# Reproduce the race (no workaround) to get a fresh crash
pkill -f vpinfe; vpinfe
tail -50 ~/.config/vpinfe/vpinfe.log

# Mask the race with strace (100%) and dump a trace I can inspect
nix shell nixpkgs#strace --command sh -c \
  'strace -fv -o /tmp/vpinfe-trace.log -s 8000 -e trace=execve vpinfe'

# Try the taskset workaround manually (sporadic)
taskset -c 0 vpinfe
```

## Recommendation

Stay on Hyprland. If you care enough to fix Sway, the path forward is
patching VPinFE to stagger its chromium spawns — everything I tried
below the application layer is too fragile.
