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

DOTFILES="${HOME}/.dotfiles"

# ---------- Shared environment (OS detection, PATH, XDG, editor, locale) ----------
[ -f "$DOTFILES/shared/env.sh" ] && source "$DOTFILES/shared/env.sh"

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

# ---------- Shared aliases (git, navigation, modern CLI replacements, clipboard) ----------
[ -f "$DOTFILES/shared/aliases.sh" ] && source "$DOTFILES/shared/aliases.sh"

# ---------- Shared functions (dev_layout, mkproj, extract) ----------
[ -f "$DOTFILES/shared/functions.sh" ] && source "$DOTFILES/shared/functions.sh"

# ---------- Machine-local additions (NOT tracked by git) ----------
# Put host-specific things here: CUDA paths, vendor SDK env, ulimit tweaks,
# host-only aliases. Create it with: touch ~/.zshrc.local
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
