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

# Garbage collect old generations
gc:
    nix-collect-garbage -d
