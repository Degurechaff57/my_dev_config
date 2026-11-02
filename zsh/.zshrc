# =============================================================================
# Zsh configuration — unified interactive shell for macOS & Linux
#
# This is the ONLY interactive shell config. Scripts stay on their shebang
# (bash/python/...), so they are unaffected by the login shell.
#
# Toolchain (all via Oh My Zsh plugins — no ble.sh / starship needed):
#   zsh-autosuggestions      → fish-style grey inline suggestions
#   zsh-syntax-highlighting  → real-time syntax colouring
#   z                       → directory jumping (replaces zoxide)
#   git/copyfile/copypath    → git aliases & clipboard helpers
#
# Sources shared/ configs for cross-shell aliases, functions, and env vars.
# =============================================================================

# ---------- Resolve the repo root from this file's REAL path ----------
# ~/.zshrc is a symlink into the repo, so `:A` follows it. This keeps the repo
# working from any clone location, not only ~/.dotfiles.
DOTFILES="${${(%):-%x}:A:h:h}"
[ -d "$DOTFILES/shared" ] || DOTFILES="${HOME}/.dotfiles"

# ---------- Shared environment (OS detection, PATH, XDG, editor, locale) ----------
[ -f "$DOTFILES/shared/env.sh" ] && source "$DOTFILES/shared/env.sh"

# ---------- Oh My Zsh ----------
# 未安装时不要报一串 "no such file"：给一句可执行的提示，然后继续加载
# shared/ 里的环境与别名，shell 仍然可用。
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

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    print -u2 "zsh: 未找到 Oh My Zsh（$ZSH）。安装：bash \"$DOTFILES/scripts/bootstrap.sh\""
fi

# ---------- Shared aliases (git, navigation, modern CLI replacements, clipboard) ----------
[ -f "$DOTFILES/shared/aliases.sh" ] && source "$DOTFILES/shared/aliases.sh"

# ---------- Shared functions (dev_layout, mkproj, extract) ----------
[ -f "$DOTFILES/shared/functions.sh" ] && source "$DOTFILES/shared/functions.sh"

# ---------- Machine-local additions (NOT tracked by git) ----------
# Put host-specific things here: CUDA paths, vendor SDK env, ulimit tweaks,
# host-only aliases. Create it with: touch ~/.zshrc.local
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# NOTE: third-party installers (Antigravity, nvm, …) tend to append absolute
# paths to ~/.zshrc — which here is a symlink into this repo. Keep such lines
# in ~/.zshrc.local instead: a hard-coded /home/<user> path breaks the moment
# the repo is deployed on another machine.
