# =============================================================================
# Cross-platform environment variables
# Values here should be safe to commit (no tokens, no passwords)
# Put secrets in .zshrc.secrets (git-ignored)
# =============================================================================

# ---------- XDG Base Directory ----------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Language & locale ----------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ---------- Less config ----------
export LESS="-RiF"

# ---------- History ----------
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$HOME/.zsh_history"

# ---------- Platform-specific Python/pip ----------
if [ "$OS" = "macos" ]; then
    # Use Homebrew Python on macOS
    export PATH="/opt/homebrew/opt/python@3/libexec/bin:$PATH"
elif [ "$OS" = "linux" ]; then
    # pip user installs
    export PATH="$HOME/.local/bin:$PATH"
fi

# ---------- Build system concurrency ----------
# Use all available cores
export MAKEFLAGS="-j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"
