#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap — macOS & Linux
#
# One-command deploy:
#   git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles
#   bash ~/.dotfiles/scripts/bootstrap.sh              # user-space, no sudo
#   bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo  # also install apt packages
#
# What it sets up:
#   zsh          → the single INTERACTIVE shell on both platforms
#   Oh My Zsh    → + zsh-autosuggestions, zsh-syntax-highlighting, git, copyfile,
#                  copypath, z  (replaces ble.sh / starship / zoxide / fzf setup)
#   symlinks     → ~/.zshrc, ~/.tmux.conf, ~/.config/nvim
#   ~/.zshrc.local → created empty; host-specific stuff goes here (git-ignored)
#
# Scripts are NOT affected by the login shell — they keep their shebang
# (#!/usr/bin/env bash, #!/usr/bin/env python3, ...). Only interactive use is zsh.
#
# Flags:
#   --with-sudo    also install system packages from pkg/apt-packages.txt
#   --no-nvim      do not touch ~/.config/nvim (keeps an existing独立 config)
#   --skip-chsh    do not offer to change the login shell
# =============================================================================
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-git@github.com:Degurechaff57/my_dev_config.git}"
DOTFILES="${HOME}/.dotfiles"
OS="$(uname -s)"

# ---------- Flags ----------
WITH_SUDO=false
WITH_NVIM=true
OFFER_CHSH=true
for arg in "$@"; do
    case "$arg" in
        --with-sudo) WITH_SUDO=true ;;
        --no-nvim)   WITH_NVIM=false ;;
        --skip-chsh) OFFER_CHSH=false ;;
        -h|--help)   sed -n '2,26p' "$0"; exit 0 ;;
        *)           echo "Unknown flag: $arg (try --help)" >&2; exit 1 ;;
    esac
done

# ---------- Colors ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

INSTALLED=()
SKIPPED=()

# ---------- Pre-flight: repo present? ----------
if [ ! -d "$DOTFILES" ]; then
    info "Dotfiles not found — cloning from ${REPO_URL}..."
    command -v git >/dev/null || { error "git is required."; exit 1; }
    git clone "$REPO_URL" "$DOTFILES"
fi
info "Bootstrapping dotfiles for ${OS}..."
info "  ($([ "$WITH_SUDO" = true ] && echo "--with-sudo: will install system packages" || echo "user-space mode: no system packages, no sudo"))"

# ---------- Backup helper ----------
backup() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then
        mv "$1" "${1}.backup.$(date +%Y%m%d%H%M%S)"
        info "Backed up: $1"
    elif [ -L "$1" ]; then
        rm "$1"
        info "Removed old symlink: $1"
    fi
}

link() {
    backup "$1"
    mkdir -p "$(dirname "$1")"
    ln -sf "$2" "$1"
    info "Linked: $1 → $2"
}

# =============================================================================
# System packages (only with --with-sudo)
# =============================================================================
if [ "$WITH_SUDO" = true ]; then
    if [ "$OS" = "Darwin" ]; then
        if ! command -v brew >/dev/null; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        info "Installing Homebrew packages..."
        brew bundle --file="$DOTFILES/pkg/Brewfile" --no-lock
        INSTALLED+=("brew packages")
    elif [ -f /etc/debian_version ]; then
        info "Debian/Ubuntu detected — installing APT packages..."
        if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
            sudo apt update
            grep -v '^#' "$DOTFILES/pkg/apt-packages.txt" | grep -v '^$' | xargs sudo apt install -y
            INSTALLED+=("apt packages")
        else
            warn "sudo failed — skipping APT install."
            SKIPPED+=("apt packages (sudo failed)")
        fi
    else
        warn "Unsupported Linux distro — install packages from pkg/apt-packages.txt manually."
        SKIPPED+=("system packages (unsupported distro)")
    fi
else
    info "Skipping system packages (use --with-sudo to install)."
    SKIPPED+=("apt packages (use --with-sudo)")
fi

# =============================================================================
# zsh — the single interactive shell (both platforms)
# =============================================================================
if ! command -v zsh >/dev/null; then
    if [ "$OS" = "Darwin" ]; then
        warn "zsh not found — macOS ships it by default. Install with: brew install zsh"
    else
        warn "zsh not found. Install it first:"
        warn "    sudo apt install zsh"
    fi
    warn "Continuing — the config files will still be linked."
    SKIPPED+=("zsh binary")
else
    INSTALLED+=("zsh")
fi

# ---------- Oh My Zsh ----------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended || warn "Oh My Zsh install failed — skipping."
fi
if [ -d "$HOME/.oh-my-zsh" ]; then
    INSTALLED+=("oh-my-zsh")
else
    SKIPPED+=("oh-my-zsh")
fi

# ---------- zsh plugins (user-space git clones) ----------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for spec in \
    "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions" \
    "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"; do
    set -- $spec
    _name="$1"; _repo="$2"
    if [ -d "$ZSH_CUSTOM/plugins/$_name" ]; then
        INSTALLED+=("$_name")
    else
        info "Installing $_name..."
        mkdir -p "$ZSH_CUSTOM/plugins"
        if git clone --depth 1 "$_repo" "$ZSH_CUSTOM/plugins/$_name" >/dev/null 2>&1; then
            INSTALLED+=("$_name")
        else
            warn "$_name clone failed — skipping."
            SKIPPED+=("$_name")
        fi
    fi
done
unset _name _repo spec

# =============================================================================
# Symlinks — zsh + tmux + nvim
# =============================================================================
link "$HOME/.zshrc" "$DOTFILES/zsh/.zshrc"

# Machine-local overrides — created empty if missing, git-ignored
if [ ! -f "$HOME/.zshrc.local" ]; then
    cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-local interactive shell overrides — NOT tracked by git.
# Host-specific PATH entries, vendor SDK env, ulimit tweaks, host-only aliases.
EOF
    info "Created: ~/.zshrc.local (put host-specific config here)"
fi

link "$HOME/.tmux.conf" "$DOTFILES/tmux/.tmux.conf"

if [ "$WITH_NVIM" = true ]; then
    if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        info "Backed up: ~/.config/nvim"
    fi
    mkdir -p "$HOME/.config"
    ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
    info "Linked: ~/.config/nvim → $DOTFILES/nvim"
else
    info "Skipping nvim (--no-nvim)."
    SKIPPED+=("nvim config")
fi

# =============================================================================
# Login shell
# =============================================================================
if [ "$OFFER_CHSH" = true ] && command -v zsh >/dev/null; then
    _zsh_path="$(command -v zsh)"
    if [ "${SHELL:-}" != "$_zsh_path" ]; then
        warn ""
        warn "  Default login shell is '${SHELL:-unknown}', not zsh."
        warn "  Switch with:  chsh -s $_zsh_path"
        warn "  (Interactive config is zsh; scripts keep their shebang either way.)"
        warn ""
    else
        info "Login shell is already zsh."
    fi
fi

# =============================================================================
# Summary
# =============================================================================
info ""
info "  Bootstrap complete!"
echo ""
echo "  ┌───────────────────────────────────────────────┐"
printf  "  │ %-22s %-21s │\n" "Component" "Status"
echo "  ├───────────────────────────────────────────────┤"
for _t in "zsh" "oh-my-zsh" "zsh-autosuggestions" "zsh-syntax-highlighting" \
          "apt packages" "brew packages" "system packages (unsupported distro)" \
          "apt packages (use --with-sudo)" "apt packages (sudo failed)" \
          "zsh binary" "nvim config"; do
    if printf '%s\n' "${INSTALLED[@]:-}" | grep -qxF "$_t"; then
        printf "  │ %-22s %-21s │\n" "$_t" "✅ ready"
    elif printf '%s\n' "${SKIPPED[@]:-}" | grep -qxF "$_t"; then
        printf "  │ %-22s %-21s │\n" "$_t" "⚠️  skipped"
    fi
done
echo "  └───────────────────────────────────────────────┘"
unset _t
echo ""
info "  Next:"
info "    exec zsh                     # enter zsh in this session"
info "    nvim                         # LazyVim installs plugins on first run"
info "    ~/.zshrc.local               # host-specific config (git-ignored)"
