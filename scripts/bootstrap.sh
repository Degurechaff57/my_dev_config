#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap — macOS & Linux
#
# One-command deploy:
#   curl -fsSL https://raw.githubusercontent.com/Degurechaff57/dotfiles/main/scripts/bootstrap.sh | bash
#
# Or if already cloned:
#   bash ~/.dotfiles/scripts/bootstrap.sh
#
# macOS:  Homebrew + Oh My Zsh + zsh plugins → symlinks ~/.zshrc
# Linux:  APT + ble.sh + starship + zoxide + fzf → symlinks ~/.bashrc
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/Degurechaff57/dotfiles.git"
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

# ---------- Pre-flight: auto-clone if needed ----------
if [ ! -d "$DOTFILES" ]; then
    info "Dotfiles not found — cloning from ${REPO_URL}..."
    if command -v git &>/dev/null; then
        git clone "$REPO_URL" "$DOTFILES"
    else
        error "git is not installed. Please install git first, then re-run this script."
        exit 1
    fi
fi

info "Bootstrapping dotfiles for ${OS}..."

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

# =============================================================================
# macOS: Homebrew + Oh My Zsh + zsh plugins
# =============================================================================
if [ "$OS" = "Darwin" ]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    info "Installing Homebrew packages..."
    brew bundle --file="$DOTFILES/pkg/Brewfile" --no-lock

    # --- Oh My Zsh ---
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

    # --- Symlinks (macOS: zsh + tmux + nvim) ---
    info "Creating symlinks..."
    backup "$HOME/.zshrc"
    ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

# =============================================================================
# Linux: bash-native toolchain (ble.sh + starship + zoxide + fzf)
# No zsh, no OMZ — bash enhanced to OMZ-equivalent level.
# =============================================================================
elif [ "$OS" = "Linux" ]; then
    if [ -f /etc/debian_version ]; then
        info "Debian/Ubuntu detected — installing APT packages..."

        # Pre-check sudo access
        if sudo -n true 2>/dev/null; then
            sudo apt update
            grep -v '^#' "$DOTFILES/pkg/apt-packages.txt" | grep -v '^$' | xargs sudo apt install -y
        elif sudo -v 2>/dev/null; then
            sudo apt update
            grep -v '^#' "$DOTFILES/pkg/apt-packages.txt" | grep -v '^$' | xargs sudo apt install -y
        else
            warn "sudo not available — skipping APT package install."
            warn "Install packages manually: see pkg/apt-packages.txt"
        fi
    elif [ -f /etc/redhat-release ]; then
        warn "Fedora/RHEL detected — manual install required. See pkg/apt-packages.txt for reference."
    elif [ -f /etc/arch-release ]; then
        warn "Arch detected — manual install required. See pkg/apt-packages.txt for reference."
    else
        warn "Unknown Linux distro — skipping package install."
    fi

    # --- ble.sh: autosuggestions + syntax highlighting (pure bash) ---
    # Download pre-built nightly release — no make/gawk needed.
    BLESH_DIR="${HOME}/.local/share/blesh"
    if [ ! -f "$BLESH_DIR/ble.sh" ]; then
        info "Installing ble.sh (bash autosuggestions + syntax highlighting)..."
        mkdir -p "$BLESH_DIR"
        curl -fsSL "https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz" \
            | tar xJ -C "$BLESH_DIR" --strip-components=1 \
            || { warn "ble.sh download failed — skipping."; rm -rf "$BLESH_DIR"; }
    fi

    # --- Starship: cross-shell prompt ---
    # Install to ~/.local/bin (no sudo, already in PATH via shared/env.sh)
    if ! command -v starship &>/dev/null; then
        info "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" || warn "Starship install failed — skipping."
    fi

    # --- Symlinks (Linux: bash + tmux + nvim) ---
    info "Creating symlinks..."
    backup "$HOME/.bashrc"
    ln -sf "$DOTFILES/bash/.bashrc" "$HOME/.bashrc"

fi  # --- end platform block ---

# =============================================================================
# Shared symlinks (both platforms)
# =============================================================================

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

# =============================================================================
# Secrets template
# =============================================================================
if [ ! -f "$DOTFILES/shared/secrets.sh" ] && [ ! -f "$DOTFILES/zsh/.zshrc.secrets" ]; then
    info "Copying secrets template..."
    cp "$DOTFILES/shared/secrets.sh.example" "$DOTFILES/shared/secrets.sh"
    warn ""
    warn "  ╔══════════════════════════════════════════════════════════╗"
    warn "  ║  ACTION REQUIRED: Edit ~/.dotfiles/shared/secrets.sh   ║"
    warn "  ║  Fill in your API keys before using CLI tools.          ║"
    warn "  ╚══════════════════════════════════════════════════════════╝"
    warn ""
fi

# =============================================================================
# Done
# =============================================================================
info ""
info "  Bootstrap complete!"

if [ "$OS" = "Darwin" ]; then
    info "  Restart your terminal or run: exec zsh"
    info ""
    if [ "$SHELL" != "$(which zsh 2>/dev/null)" ] && command -v zsh &>/dev/null; then
        warn "  Your default shell is still '$SHELL'."
        warn "  To switch to zsh permanently, run:"
        warn "    chsh -s \$(which zsh)"
        warn "  Then log out and back in."
        info ""
    fi
elif [ "$OS" = "Linux" ]; then
    info "  Restart your terminal or run: exec bash"
    info "  Your bash is now enhanced with:"
    info "    ble.sh   — autosuggestions + syntax highlighting"
    info "    starship — git-aware prompt"
    info "    zoxide   — smarter cd (try: z <dirname>)"
    info "    fzf      — Ctrl-R fuzzy history, Ctrl-T fuzzy files"
    info ""
fi

info "  Verify:"
info "    tmux  — should use your cross-platform config"
info "    nvim  — LazyVim will auto-install plugins on first run"
