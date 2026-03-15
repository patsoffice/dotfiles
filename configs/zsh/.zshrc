#!/bin/zsh

# First thing: measure shell startup time if PROFILE_STARTUP is set
if [[ -n "$PROFILE_STARTUP" ]]; then
  # Reset zsh cache
  [[ -e "$HOME/.zcompdump" ]] && rm -f "$HOME/.zcompdump"
  zmodload zsh/zprof
fi

# Early exit for non-interactive shells
[[ $- != *i* ]] && return

# Initialize essential variables
declare -gx SHELL_CONFIG_DIR="$HOME/.zsh"
declare -gx SHELL_LIB_DIR="$SHELL_CONFIG_DIR/lib"
declare -gx SHELL_FUNCTIONS_DIR="$SHELL_CONFIG_DIR/functions"
declare -gx SHELL_CACHE_DIR="$HOME/.cache/zsh"

# Set up fpath for zsh functions
() {
    local -a zsh_paths

    # Common paths that might exist
    local -a possible_paths=(
        "/usr/share/zsh/site-functions"
        "/usr/local/share/zsh/site-functions"
        "/opt/homebrew/share/zsh/site-functions"
        "/usr/share/zsh/functions/Completion"
        "/usr/share/zsh/functions/Completion/Unix"
        "/usr/share/zsh/functions/Completion/Linux"
        "/usr/share/zsh/vendor-functions"
        # Nix-managed completion paths
        "$HOME/.nix-profile/share/zsh/site-functions"
        "$HOME/.nix-profile/share/zsh/vendor-completions"
        "/etc/profiles/per-user/$USER/share/zsh/site-functions"
        "/run/current-system/sw/share/zsh/site-functions"
        "$SHELL_FUNCTIONS_DIR"
    )

    # Only add paths that exist
    for p in "${possible_paths[@]}"; do
        [[ -d "$p" ]] && zsh_paths+=("$p")
    done

    # Set fpath
    fpath=("${zsh_paths[@]}" $fpath)
}

# Load completion system with caching
autoload -Uz compinit
# Regenerate .zcompdump if older than 24 hours, otherwise use cache
() {
    local -a fresh=($HOME/.zcompdump(Nm-1))
    if (( $#fresh )); then
        compinit -C
    else
        compinit
    fi
}

mkdir -p "$SHELL_CACHE_DIR"

# Prevent multiple sourcing
if [[ -n "$ZSH_INITIALIZED" ]]; then
    return 0
fi
ZSH_INITIALIZED=1

# Source global definitions if available
[[ -f /etc/zshrc ]] && source /etc/zshrc

# Module loading helper function
load_module() {
    local module_type=$1
    local module_name=$2
    local module_path

    case "$module_type" in
        "lib")      module_path="$SHELL_LIB_DIR/${module_name}.zsh" ;;
        "function") module_path="$SHELL_FUNCTIONS_DIR/${module_name}.zsh" ;;
        *)          return 1 ;;
    esac

    if [[ -f "$module_path" ]]; then
        source "$module_path"
        return 0
    fi
    return 1
}

# Load core library modules in specific order
core_modules=(
    "platform_detection" # Must be first for platform detection
    "executables"        # Executable setup
    "environment"        # Environment setup
    "shell"              # Shell configuration
    "prompt"             # Prompt setup
    "ssh"                # SSH configuration
    "tmux_emoji_titles"  # Automatic emoji titles for tmux windows
    "utils"              # Utility functions
)

for module in "${core_modules[@]}"; do
    load_module "lib" "$module"
done

# Load utility functions
load_module "function" "utils"


# Initialize core components
setup_environment
init_shell
init_prompt

# FZF key bindings and completion (fzf from nix)
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# Load work profile if it exists
if [[ -f "$HOME/.bash_work_profile" ]]; then
    source "$HOME/.bash_work_profile"
fi

# Final cleanup
unset core_modules function_modules

# Disable correction for specific commands
CORRECT_IGNORE_FILE='.*|claude'

# Load claude wrapper function
if [[ -f "$SHELL_FUNCTIONS_DIR/claude_wrapper.zsh" ]]; then
    source "$SHELL_FUNCTIONS_DIR/claude_wrapper.zsh"
fi

# Display profiling results if PROFILE_STARTUP is set
if [[ -n "$PROFILE_STARTUP" ]]; then
  zprof
fi

# Atuin shell history (disable keybindings — fzf handles Ctrl-R)
if command -v atuin &>/dev/null; then
    export ATUIN_SYNC_ADDRESS=https://sh.chezlawrence.com
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# macOS path_helper fix: Login shells may have PATH reset by /etc/zprofile
# Re-run setup_path to ensure our paths are in the correct order
if is_osx && [[ -o login ]]; then
    setup_path
fi

# Direnv hook (per-directory environment variables)
if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi

# Mise (polyglot runtime manager)
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# Vivid ls colors
if command -v vivid &>/dev/null; then
    export LS_COLORS="$(vivid generate tokyonight-night)"
fi

# Source local config (not in dotfiles repo, for secrets/machine-specific settings)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
