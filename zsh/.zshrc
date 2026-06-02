# =============================================================================
# Zsh configuration — macOS primary, Linux optional
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

# ---------- Secrets (API keys etc. — NEVER committed to git) ----------
if [ -f "$DOTFILES/shared/secrets.sh" ]; then
    source "$DOTFILES/shared/secrets.sh"
elif [ -f "$DOTFILES/zsh/.zshrc.secrets" ]; then
    source "$DOTFILES/zsh/.zshrc.secrets"
fi
