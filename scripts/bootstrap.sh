#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap — macOS & Linux
# Usage: bash <(curl -s https://raw.githubusercontent.com/<user>/dotfiles/main/scripts/bootstrap.sh)
#    or: git clone <repo> ~/.dotfiles && bash ~/.dotfiles/scripts/bootstrap.sh
# =============================================================================
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"
OS="$(uname -s)"

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------- Pre-flight ----------
if [ ! -d "$DOTFILES" ]; then
    error "Dotfiles not found at $DOTFILES"
    echo "Clone first: git clone https://github.com/<your-username>/dotfiles.git ~/.dotfiles"
    exit 1
fi

info "Bootstrapping dotfiles for ${OS}..."

# ---------- macOS: Homebrew ----------
if [ "$OS" = "Darwin" ]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    info "Installing Homebrew packages..."
    brew bundle --file="$DOTFILES/pkg/Brewfile" --no-lock

# ---------- Linux: APT ----------
elif [ "$OS" = "Linux" ]; then
    if [ -f /etc/debian_version ]; then
        info "Debian/Ubuntu detected — installing APT packages..."
        sudo apt update
        xargs -a "$DOTFILES/pkg/apt-packages.txt" sudo apt install -y
    elif [ -f /etc/redhat-release ]; then
        warn "Fedora/RHEL detected — manual install required. See pkg/apt-packages.txt for reference."
    elif [ -f /etc/arch-release ]; then
        warn "Arch detected — manual install required. See pkg/apt-packages.txt for reference."
    else
        warn "Unknown Linux distro — skipping package install."
    fi
fi

# ---------- Oh My Zsh ----------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Zsh autosuggestions
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Zsh syntax highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ---------- Symlinks ----------
info "Creating symlinks..."

# Backup existing files
backup() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then
        mv "$1" "${1}.backup.$(date +%Y%m%d%H%M%S)"
        info "Backed up: $1"
    elif [ -L "$1" ]; then
        rm "$1"
        info "Removed old symlink: $1"
    fi
}

# zsh
backup "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

# tmux
backup "$HOME/.tmux.conf"
ln -sf "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

# NeoVim
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
    info "Backed up: ~/.config/nvim"
fi
mkdir -p "$HOME/.config"
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"

# ---------- Secrets reminder ----------
if [ ! -f "$DOTFILES/zsh/.zshrc.secrets" ]; then
    info "Copying secrets template..."
    cp "$DOTFILES/zsh/.zshrc.secrets.example" "$DOTFILES/zsh/.zshrc.secrets"
    warn ""
    warn "  ╔══════════════════════════════════════════════════════════╗"
    warn "  ║  ACTION REQUIRED: Edit ~/dotfiles/zsh/.zshrc.secrets   ║"
    warn "  ║  Fill in your API keys before using CLI tools.          ║"
    warn "  ╚══════════════════════════════════════════════════════════╝"
    warn ""
fi

# ---------- Done ----------
info ""
info "  Bootstrap complete!"
info "  Restart your terminal or run: exec zsh"
info ""
info "  Verify:"
info "    tmux  — should use your cross-platform config"
info "    nvim  — LazyVim will auto-install plugins on first run"
