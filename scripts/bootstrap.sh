#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap — macOS & Linux
#
# One-command deploy:
#   curl -fsSL https://raw.githubusercontent.com/Degurechaff57/dotfiles/main/scripts/bootstrap.sh | bash
#
# Shared servers / no root:
#   bash ~/.dotfiles/scripts/bootstrap.sh           # user-space only, no sudo
#   bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo  # also install system packages
#
# macOS:  Homebrew + Oh My Zsh + zsh plugins → symlinks ~/.zshrc
# Linux:  user-space: ble.sh + starship + fzf + zoxide → symlinks ~/.bashrc
#         --with-sudo: also apt installs dev tools
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/Degurechaff57/dotfiles.git"
DOTFILES="${HOME}/.dotfiles"
OS="$(uname -s)"

# ---------- Flags ----------
WITH_SUDO=false
if [[ "${1:-}" == "--with-sudo" ]]; then
    WITH_SUDO=true
fi

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Track install status for summary
INSTALLED=()
SKIPPED=()

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
if [ "$WITH_SUDO" = true ]; then
    info "  (--with-sudo: will install system packages)"
else
    info "  (user-space mode: no system packages, no sudo)"
fi

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

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    info "Creating symlinks..."
    backup "$HOME/.zshrc"
    ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

# =============================================================================
# Linux: bash-native toolchain
# =============================================================================
elif [ "$OS" = "Linux" ]; then

    # --- System packages (only with --with-sudo) ---
    if [ "$WITH_SUDO" = true ]; then
        if [ -f /etc/debian_version ]; then
            info "Debian/Ubuntu detected — installing APT packages..."
            if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
                sudo apt update
                grep -v '^#' "$DOTFILES/pkg/apt-packages.txt" | grep -v '^$' | xargs sudo apt install -y
                INSTALLED+=("apt packages")
            else
                warn "sudo failed — skipping APT install."
                SKIPPED+=("apt packages (sudo failed)")
            fi
        elif [ -f /etc/redhat-release ]; then
            warn "Fedora/RHEL detected — install packages manually. See pkg/apt-packages.txt"
            SKIPPED+=("system packages (unsupported distro)")
        elif [ -f /etc/arch-release ]; then
            warn "Arch detected — install packages manually. See pkg/apt-packages.txt"
            SKIPPED+=("system packages (unsupported distro)")
        else
            warn "Unknown Linux distro — skipping system package install."
            SKIPPED+=("system packages (unknown distro)")
        fi
    else
        info "Skipping system packages (use --with-sudo to install)."
        SKIPPED+=("apt packages (use --with-sudo)")
    fi

    # --- fzf: fuzzy finder (install to ~/.local) ---
    if ! command -v fzf &>/dev/null; then
        info "Installing fzf (user-space)..."
        FZF_DIR="${HOME}/.local/share/fzf"
        if [ ! -d "$FZF_DIR" ]; then
            git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR" 2>/dev/null || true
        fi
        if [ -f "$FZF_DIR/install" ]; then
            # --bin: download binary only, don't touch shell configs
            "$FZF_DIR/install" --bin &>/dev/null || true
            # Symlink binary into PATH
            if [ -f "$FZF_DIR/bin/fzf" ]; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$FZF_DIR/bin/fzf" "$HOME/.local/bin/fzf"
            fi
        fi
        if command -v fzf &>/dev/null; then
            INSTALLED+=("fzf")
        else
            SKIPPED+=("fzf")
        fi
    else
        INSTALLED+=("fzf")
    fi

    # --- zoxide: smarter cd (install to ~/.local) ---
    if ! command -v zoxide &>/dev/null; then
        info "Installing zoxide (user-space)..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || true
        if command -v zoxide &>/dev/null || [ -f "$HOME/.local/bin/zoxide" ]; then
            INSTALLED+=("zoxide")
        else
            SKIPPED+=("zoxide")
        fi
    else
        INSTALLED+=("zoxide")
    fi

    # --- ble.sh: autosuggestions + syntax highlighting (pure bash, user-space) ---
    BLESH_DIR="${HOME}/.local/share/blesh"
    if [ ! -f "$BLESH_DIR/ble.sh" ]; then
        info "Installing ble.sh..."
        mkdir -p "$BLESH_DIR"
        curl -fsSL "https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz" \
            | tar xJ -C "$BLESH_DIR" --strip-components=1 \
            || { warn "ble.sh download failed — skipping."; rm -rf "$BLESH_DIR"; }
    fi
    if [ -f "$BLESH_DIR/ble.sh" ]; then
        INSTALLED+=("ble.sh")
    else
        SKIPPED+=("ble.sh")
    fi

    # --- Starship: cross-shell prompt (user-space) ---
    if ! command -v starship &>/dev/null; then
        info "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" \
            || warn "Starship install failed — skipping."
    fi
    if command -v starship &>/dev/null; then
        INSTALLED+=("starship")
    else
        SKIPPED+=("starship")
    fi

    # --- Symlinks ---
    info "Creating symlinks..."
    backup "$HOME/.bashrc"
    ln -sf "$DOTFILES/bash/.bashrc" "$HOME/.bashrc"

fi  # --- end platform block ---

# =============================================================================
# Shared symlinks (both platforms)
# =============================================================================

backup "$HOME/.tmux.conf"
ln -sf "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
    info "Backed up: ~/.config/nvim"
fi
mkdir -p "$HOME/.config"
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"

# =============================================================================
# Secrets — auto-migrate API keys from old config, or copy template
# =============================================================================
_need_secrets=false
if [ ! -f "$DOTFILES/shared/secrets.sh" ] && [ ! -f "$DOTFILES/zsh/.zshrc.secrets" ]; then
    _need_secrets=true
fi

# If secrets.sh exists but is still the unedited template, treat as missing
if [ -f "$DOTFILES/shared/secrets.sh" ] && grep -q 'your-api-key-here' "$DOTFILES/shared/secrets.sh" 2>/dev/null; then
    _need_secrets=true
fi

if [ "$_need_secrets" = true ]; then
    # Try to recover API keys from backed-up configs
    _old_rc="${HOME}/.bashrc.backup."* 2>/dev/null || true
    _found_keys=false

    for _f in $_old_rc; do
        [ -f "$_f" ] || continue
        if grep -q 'ANTHROPIC_AUTH_TOKEN\|ANTHROPIC_BASE_URL' "$_f" 2>/dev/null; then
            info "Found API keys in backup: $(basename "$_f")"
            info "Migrating keys to shared/secrets.sh..."

            # Extract existing env vars from the backup
            {
                echo "# Auto-migrated from $(basename "$_f") on $(date +%Y-%m-%d)"
                grep -E 'export (ANTHROPIC|OPENAI|HUGGINGFACE)_' "$_f" 2>/dev/null || true
                echo ""
                echo "# Fill in any remaining keys below"
                echo "# See shared/secrets.sh.example for the full template"
            } > "$DOTFILES/shared/secrets.sh"

            _found_keys=true
            break
        fi
    done

    if [ "$_found_keys" = false ]; then
        info "Copying secrets template..."
        cp "$DOTFILES/shared/secrets.sh.example" "$DOTFILES/shared/secrets.sh"
        warn ""
        warn "  ╔══════════════════════════════════════════════════════════╗"
        warn "  ║  ACTION REQUIRED: Edit ~/.dotfiles/shared/secrets.sh   ║"
        warn "  ║  Fill in your API keys before using CLI tools.          ║"
        warn "  ╚══════════════════════════════════════════════════════════╝"
        warn ""
    else
        info "API keys migrated. Verify with: nvim ~/.dotfiles/shared/secrets.sh"
    fi
fi
unset _need_secrets _old_rc _found_keys _f

# =============================================================================
# Summary
# =============================================================================
info ""
info "  Bootstrap complete!"

if [ "$OS" = "Darwin" ]; then
    info "  Restart your terminal or run: exec zsh"
    if [ "$SHELL" != "$(which zsh 2>/dev/null)" ] && command -v zsh &>/dev/null; then
        warn "  Default shell is '$SHELL'. Switch with: chsh -s \$(which zsh)"
    fi

elif [ "$OS" = "Linux" ]; then
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    printf  "  │ %-43s │\n" "Tool              Status"
    echo "  ├─────────────────────────────────────────────┤"
    for tool in "ble.sh" "starship" "fzf" "zoxide" "apt packages"; do
        _status=""
        if printf '%s\n' "${INSTALLED[@]}" | grep -qF "$tool"; then
            _status="✅ installed"
        elif printf '%s\n' "${SKIPPED[@]}" | grep -qF "$tool"; then
            _status="⚠️  skipped"
        else
            continue
        fi
        printf "  │ %-20s %-22s │\n" "$tool" "$_status"
    done
    echo "  └─────────────────────────────────────────────┘"
    echo ""
    info "  Restart your terminal or run: exec bash"

    if [ "$WITH_SUDO" != true ]; then
        echo ""
        warn "  This was a user-space install (no sudo)."
        warn "  Nothing was written outside \$HOME."
        warn "  To also install system dev tools:"
        warn "    bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo"
    fi
fi

echo ""
info "  Verify:"
info "    tmux  — Ctrl+b 1/2/3 to switch panes"
info "    nvim  — LazyVim auto-installs plugins on first run"
