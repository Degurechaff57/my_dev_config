# =============================================================================
# Cross-shell environment variables (bash & zsh)
# Sourced by both .bashrc and .zshrc
# =============================================================================

# ---------- OS Detection ----------
case "$(uname -s)" in
    Darwin) export OS="macos" ;;
    Linux)  export OS="linux" ;;
    *)      export OS="unknown" ;;
esac

# ---------- XDG Base Directory ----------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Language & locale ----------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ---------- Editor ----------
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Less config ----------
export LESS="-RiF"

# ---------- History ----------
export HISTSIZE=10000
export HISTFILESIZE=10000

if [ -n "${BASH_VERSION-}" ]; then
    # bash-specific history
    export HISTFILE="$HOME/.bash_history"
    shopt -s histappend 2>/dev/null
    export HISTCONTROL="ignoreboth:erasedups"
elif [ -n "${ZSH_VERSION-}" ]; then
    # zsh-specific history
    export HISTFILE="$HOME/.zsh_history"
    export SAVEHIST=10000
fi

# ---------- Path Setup ----------
case "$OS" in
    macos)
        # Homebrew paths (Apple Silicon)
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
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

# ---------- nvm (Node Version Manager) ----------
# 必须在 PATH 设置之后加载：nvm 会把自己管理的 node 版本插到 PATH 最前面。
# 不加载它的话，nvm 里装的全局工具（npm 包等）在交互 shell 里全部不可见 ——
# 这是从 bash 切到 zsh 时最容易漏掉的一步。
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    # nvm 的 bash 补全（zsh 下也有对应的 _nvm 补全，由 oh-my-zsh 处理）
    [ -n "${BASH_VERSION-}" ] && [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

# ---------- Build system concurrency ----------
export MAKEFLAGS="-j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"
