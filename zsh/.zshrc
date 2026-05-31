# =============================================================================
# Cross-platform ZSH configuration
# Supports: macOS (Homebrew) | Linux (apt/dnf/pacman) | Windows (WSL2)
# =============================================================================

# ---------- OS Detection ----------
case "$(uname -s)" in
    Darwin)  export OS="macos" ;;
    Linux)   export OS="linux" ;;
    *)       export OS="unknown" ;;
esac

# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
    git
    copyfile
    copypath
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ---------- Path Setup ----------
# Cross-platform PATH additions
case "$OS" in
    macos)
        # Homebrew paths (Apple Silicon)
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
        # macOS-specific binaries
        export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
        ;;
    linux)
        # Linuxbrew (if installed)
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
        # Standard Linux paths
        export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
        ;;
esac

# Load additional local PATH (if exists)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ---------- Editor ----------
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Platform-specific clipboard aliases ----------
if [ "$OS" = "macos" ]; then
    alias clip="pbcopy"
    alias paste="pbpaste"
elif [ "$OS" = "linux" ]; then
    if command -v wl-copy &>/dev/null; then
        alias clip="wl-copy"
        alias paste="wl-paste"
    elif command -v xclip &>/dev/null; then
        alias clip="xclip -selection clipboard"
        alias paste="xclip -selection clipboard -o"
    fi
fi

# ---------- Modern CLI replacements ----------
if command -v eza &>/dev/null; then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -la"
    alias tree="eza --tree"
elif [ "$OS" = "linux" ]; then
    alias ll="ls -lh"
    alias la="ls -lAh"
fi

if command -v bat &>/dev/null; then
    alias cat="bat --paging=never"
fi

if command -v fd &>/dev/null; then
    alias find="fd"
fi

if command -v rg &>/dev/null; then
    alias grep="rg"
fi

# ---------- Load modular configs ----------
DOTFILES="$HOME/.dotfiles/zsh"

# Aliases
[ -f "$HOME/.dotfiles/zsh/aliases.zsh" ] && source "$HOME/.dotfiles/zsh/aliases.zsh"

# Functions
[ -f "$HOME/.dotfiles/zsh/functions.zsh" ] && source "$HOME/.dotfiles/zsh/functions.zsh"

# Environment variables (cross-platform, no secrets)
[ -f "$HOME/.dotfiles/zsh/env.zsh" ] && source "$HOME/.dotfiles/zsh/env.zsh"

# Secrets (API keys etc. — NEVER committed to git)
[ -f "$HOME/.dotfiles/zsh/.zshrc.secrets" ] && source "$HOME/.dotfiles/zsh/.zshrc.secrets"
