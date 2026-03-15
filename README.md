# dotfiles

Nix-based system configuration supporting multiple host classes across macOS and Linux. Uses Nix flakes with home-manager, nix-darwin, and NixOS to manage ~100 CLI tools, shell configuration, and system settings declaratively.

## Architecture

The repository is organized around three **host classes**:

| Class | Platform | System | Use case |
| --- | --- | --- | --- |
| `linux-workstation` | x86_64-linux | NixOS + home-manager | Desktop with GUI, compositor, dev tools |
| `linux-server` | x86_64-linux | NixOS + home-manager | Headless server, core CLI only |
| `darwin-workstation` | aarch64-darwin | nix-darwin + home-manager | macOS laptop/desktop |

Each host imports its class modules and can add small per-host overrides (hostname, hardware, extra packages). Adding a new host is a thin `default.nix` plus one line in `flake.nix`:

```nix
my-host = helpers.mkNixosHost {
  hostname = "my-host";
  class = "linux-workstation";
};
```

## Repository Structure

```text
flake.nix                     # Flake inputs/outputs, host definitions
lib/
  mkHost.nix                  # Host constructor helpers (mkNixosHost, mkDarwinHost)
modules/
  nixos/
    base.nix                  # Shared NixOS config (boot, network, users, ssh)
    workstation.nix            # GUI: Niri compositor, DMS greeter, flatpak, printing
    server.nix                 # Server-specific settings
  darwin/
    base.nix                  # nix-darwin system config
  home/
    options.nix               # Custom options (my.user.name, my.dotfilesPath)
    user.nix                  # User identity (auto-derives homeDirectory per platform)
    packages-core.nix         # ~80 CLI tools for all classes
    packages-dev.nix          # Dev toolchains (Go, Rust, Python, C++) for workstations
    packages-linux-gui.nix    # GUI apps, compositor, fonts for Linux workstations
    packages-darwin.nix        # macOS-specific packages
    shell.nix                 # ZSH, direnv, starship symlinks
    git.nix                   # Git config symlinks
    ssh.nix                   # SSH config symlink
    wezterm.nix               # WezTerm config symlink (workstations only)
hostclass/
  linux-workstation.nix       # 1Password agent, git/ssh signing overrides
  linux-server.nix            # Server git signing config
  darwin-workstation.nix       # macOS 1Password agent paths
hosts/
  nixos-testing/
    default.nix               # Hostname, btrfs/swap config
    hardware-configuration.nix
configs/
  zsh/                        # Modular ZSH setup (.zshrc + lib/ + functions/)
  starship/                   # Powerline-style prompt with plx custom segments
  git/                        # .gitconfig + .gitignore_global
  ssh/                        # SSH config (with Include for per-host overrides)
  direnv/                     # nix-direnv integration
  wezterm/                    # Terminal emulator config
```

## Configuration Approach

Dotfiles in `configs/` are symlinked into place via home-manager using `mkOutOfStoreSymlink`. This means edits to config files take effect immediately without a rebuild, similar to GNU Stow.

Package modules are composed per class:

- **All classes**: `packages-core.nix` (CLI tools, infra, networking)
- **Workstations**: + `packages-dev.nix` (language toolchains, editors, media tools)
- **Linux workstations**: + `packages-linux-gui.nix` (GUI apps, compositor, fonts)

User identity (username, home directory, state version) is defined once and derived per platform automatically.

## Shell

ZSH with a modular configuration adapted from [mmichie/dotfiles](https://github.com/mmichie/dotfiles):

- Starship prompt with custom [plx](https://github.com/mmichie/plx) segments for path and git status
- Modern tool aliases (eza, bat, zoxide, fzf)
- History management, vi keybindings, completion system
- Platform detection, tmux integration with smart window titles
- 1Password SSH agent detection on both macOS and Linux, with traditional ssh-agent fallback for servers

## Usage

```bash
# Apply system configuration (auto-detects platform and hostname)
just switch

# Update all flake inputs
just update

# Preview changes without applying
just dry-run

# Check flake validity
just check

# Format all Nix files
just fmt

# Garbage collect old generations
just gc
```

## Prerequisites

- [Nix](https://nixos.org/download/) with flakes enabled
- [just](https://github.com/casey/just) command runner
