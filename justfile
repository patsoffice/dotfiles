# Dotfiles management via Nix

# Apply system configuration
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild switch --flake .#$(hostname -s); \
    elif [ -f /etc/NIXOS ]; then \
        sudo nixos-rebuild switch --flake .#$(hostname -s); \
    fi

# Update all flake inputs
update:
    nix flake update

# Check flake validity
check:
    nix flake check

# Show what would change
dry-run:
    @if [ "$(uname)" = "Darwin" ]; then \
        darwin-rebuild build --flake .#$(hostname -s) && nvd diff /run/current-system result; \
    elif [ -f /etc/NIXOS ]; then \
        nixos-rebuild build --flake .#$(hostname -s) && nvd diff /run/current-system result; \
    fi

# Show diff between running system and new config
diff:
    @if [ "$(uname)" = "Darwin" ]; then \
        darwin-rebuild build --flake .#$(hostname -s) && nvd diff /run/current-system result; \
    elif [ -f /etc/NIXOS ]; then \
        nixos-rebuild build --flake .#$(hostname -s) && nvd diff /run/current-system result; \
    fi

# Format all nix files
fmt:
    nix fmt

# Garbage collect old generations, keeping at least the last 15 days and never
# pruning anything since the last boot (so the booted known-good system and any
# newer generations stay as rollback targets); macOS uses the flat 15-day floor
gc:
    @if [ "$(uname)" = "Linux" ]; then \
        days=$(( ( $(date +%s) - $(date -d "$(uptime -s)" +%s) + 86399 ) / 86400 )); \
        [ "$days" -lt 15 ] && days=15; \
        echo "Keeping generations from the last ${days}d"; \
        nix-collect-garbage --delete-older-than ${days}d; \
        sudo nix-collect-garbage --delete-older-than ${days}d; \
    else \
        nix-collect-garbage --delete-older-than 15d; \
        sudo nix-collect-garbage --delete-older-than 15d; \
    fi
