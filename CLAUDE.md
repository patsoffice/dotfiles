# CLAUDE.md

## Project Overview

This is a Nix-based dotfiles repository managing system and user configuration across macOS and Linux. It uses Nix flakes with home-manager, nix-darwin, and NixOS to declaratively manage packages, shell configuration, and system settings.

## Repository Structure

- `flake.nix` — Flake inputs/outputs, host definitions
- `lib/mkHost.nix` — Host constructor helpers (`mkNixosHost`, `mkDarwinHost`)
- `modules/nixos/` — NixOS system-level modules (base, workstation, server)
- `modules/darwin/` — nix-darwin system-level modules
- `modules/home/` — Home-manager modules (packages, shell, git, ssh, etc.)
- `hostclass/` — Per-class user config (linux-workstation, linux-server, darwin-workstation)
- `hosts/` — Per-host config (hostname, hardware, small overrides)
- `configs/` — Dotfiles (zsh, starship, git, ssh, niri, wezterm, direnv) symlinked via home-manager

## Key Patterns

- **Three host classes**: `linux-workstation`, `linux-server`, `darwin-workstation` — each composes different module sets
- **Thin hosts**: Host directories contain only hostname, hardware config, and small overrides. Class modules do the heavy lifting.
- **Mutable symlinks**: Dotfiles in `configs/` are symlinked via `mkOutOfStoreSymlink` so edits take effect immediately without rebuilds
- **Package layering**: `packages-core.nix` (all classes) → `packages-dev.nix` (workstations) → `packages-linux-gui.nix` (Linux GUI)
- **User parameterization**: Username, home directory, and state version are defined once in `lib/mkHost.nix` and derived per platform via `modules/home/user.nix`
- **1Password SSH agent**: Detected on both macOS and Linux paths in `configs/zsh/.zsh/lib/ssh.zsh`, with traditional ssh-agent fallback for servers
- **Starship custom segments**: Uses [plx](https://github.com/mmichie/plx) for path and git status rendering

## Build & Validation

- `just switch` — Apply system configuration (auto-detects platform and hostname)
- `just check` or `nix flake check` — Validate flake
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run` — Verify build without applying
- `just fmt` or `nix fmt` — Format all Nix files with nixfmt-tree
- Always run `nix flake check` after modifying `.nix` files
- New files must be `git add`-ed before `nix flake check` can see them

## Commit Style

- Prefix: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Summary line under 80 chars
- Body: each logical change on its own `-` bullet
- Summarize what was changed and why, not just file names

## SAK (Swiss Army Knife for LLMs)

[sak](https://github.com/patsoffice/sak) is a read-only operations tool installed on all workstations. Every operation is strictly read-only with no side effects, so it can be used freely without approval concerns.

**Domains and commands:**

- `sak fs` — Filesystem operations
  - `glob` — Find files matching glob patterns (respects `.git`, `node_modules`, etc. exclusions)
  - `grep` — Search file contents with regex (`-i`, `-l`, `-c`, `-C`, `-U` for multiline, `--type`, `--glob`)
  - `read` — Read file contents with line numbers (`-n 1-50`, `-n -20` for last 20, `--offset`, `--limit`)
  - `cut` — Extract fields from delimited text (`-d`, `-f`, `--filter`, `--header`, `--unique`)
- `sak git` — Git repository operations
  - `status` — Working tree status (porcelain-style)
  - `diff` — File diffs (`--staged`, `--name-only`, `--stat`, `--commit`)
  - `log` — Commit history (`--oneline`, `-n`, `--author`, `--grep`, `--since`, `-- <path>`)
  - `show` — Show a commit (`--stat`, `--name-only`, `--format`)
  - `blame` — Line-by-line authorship (`-L 10,20`)
  - `branch` — List branches (`--all`)
  - `tags` — List tags (`--sort date`)
  - `remote` — List remotes with URLs
  - `contributors` — Contributors by commit count
  - `stash-list` — List stash entries
- `sak json` — JSON queries: `query`, `exists`, `keys`, `flatten`, `grep`, `length`, `paths`, `schema`, `type`, `validate`, `diff`
- `sak config` — TOML / YAML / plist / JSON queries (same operations as `json`, plus `convert` to cross-translate formats)
- `sak cert` — X.509 inspection: `inspect`, `expiring --days N`, `from-kubeconfig`, `from-yaml`
- `sak talos` — Talos Linux (wraps `talosctl`): `certs` (fleet-wide cert inventory), `read <path>` (fan-out file read), `get <resource> --node <ip>` (COSI resource)
- `sak k8s` — Live cluster (read-only): `contexts`, `kinds`, `get`, `images`, `env`, `schema`, `restarts`, `failing`, `pending`, `events`, `describe`, `logs`
- `sak lxc` — LXD/Incus: `list`, `info <instance>`, `config <instance>`, `images`
- `sak docker` — Docker daemon: `list`, `images`, `info <container>`, `config <container>`
- `sak sqlite` — SQLite files: `tables`, `schema`, `count <table>`, `dump <table>`, `query '<SQL>'`, `info`
- `sak prom` — Prometheus / Alertmanager: `alerts`, `query`, `query-range`, `histogram`, `targets`, `rules`, `am alerts`, `am silences`

**Output conventions:** stdout is clean results only (no ANSI colors, no spinners). Line numbers are right-aligned and tab-separated. Exit codes: 0 = results found, 1 = no results, 2 = error. All output is bounded by `--limit` to prevent unbounded results.

**Discovery:** Run `sak --help`, `sak <domain> --help`, or `sak <domain> <command> --help` to explore options and see examples. Flag detail above is intentionally non-exhaustive for the newer domains — check `--help` rather than guessing.

**Prefer sak over native equivalents** for read-only inspection: `sak fs read` over `cat`/`head`/`tail`, `sak fs grep` over `grep -r`, `sak fs glob` over `find`, `sak git <op>` over `git <op>`, `sak k8s get|describe|logs` over `kubectl get|describe|logs`, `sak cert inspect` over `openssl x509`, `sak json/config query` over `jq`/`yq` for simple extractions. Output is LLM-shaped (deterministic, bounded, decoration-free) and no per-call approval is needed.

## Important Notes

- The `configs/niri/dms/` directory is auto-generated by DMS — do not track or modify it
- The `home/linux-workstation.nix` file is the original pre-refactor hostclass file — `hostclass/linux-workstation.nix` is the current one
- Nix flake check uses git-tracked files only; always `git add` new files before checking
