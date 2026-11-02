# =============================================================================
# Cross-shell aliases (bash & zsh)
# Sourced by both .bashrc and .zshrc
# =============================================================================

# ---------- tmux session ----------
alias dev="dev_layout"
alias qdev="tmux kill-session -t dev"

# ---------- Navigation ----------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias dl="cd ~/Downloads"

# ---------- Safety nets ----------
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# ---------- Git shortcuts ----------
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate -20"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"

# ---------- System update ----------
if [ "$OS" = "macos" ]; then
    alias update="brew update && brew upgrade"
    alias cleanup="brew cleanup && brew autoremove"
elif [ "$OS" = "linux" ]; then
    alias update="sudo apt update && sudo apt upgrade -y"
    alias cleanup="sudo apt autoremove -y && sudo apt autoclean"
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

# bat: Debian/Ubuntu uses 'batcat' (name conflict with another package)
if command -v batcat &>/dev/null; then
    alias cat="batcat --paging=never"
elif command -v bat &>/dev/null; then
    alias cat="bat --paging=never"
fi

# fd: Debian/Ubuntu uses 'fdfind' (name conflict with another package)
if command -v fdfind &>/dev/null; then
    alias find="fdfind"
elif command -v fd &>/dev/null; then
    alias find="fd"
fi

if command -v rg &>/dev/null; then
    alias grep="rg"
fi

# ---------- Platform-specific clipboard ----------
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

# ---------- Quick edit dotfiles ----------
# Single quotes: $DOTFILES and $EDITOR are expanded when the alias runs, so a
# repo cloned somewhere other than ~/.dotfiles still works.
alias dotfiles='cd "$DOTFILES"'
alias zshrc='${EDITOR:-nvim} "$DOTFILES/zsh/.zshrc"'
alias bashrc='${EDITOR:-nvim} "$DOTFILES/bash/.bashrc"'
alias bashprofile='${EDITOR:-nvim} "$DOTFILES/bash/.bash_profile"'
alias tmuxconf='${EDITOR:-nvim} "$DOTFILES/tmux/.tmux.conf"'
alias nvimconf='${EDITOR:-nvim} ~/.config/nvim'
alias wezconf='${EDITOR:-nvim} "$DOTFILES/wezterm/wezterm.lua"'
alias gitconf='${EDITOR:-nvim} "$DOTFILES/git/.gitconfig"'
alias aliasconf='${EDITOR:-nvim} "$DOTFILES/shared/aliases.sh"'
alias funcsconf='${EDITOR:-nvim} "$DOTFILES/shared/functions.sh"'
alias envconf='${EDITOR:-nvim} "$DOTFILES/shared/env.sh"'

# Re-run the installer (add --check to only verify links)
alias bootstrap='bash "$DOTFILES/scripts/bootstrap.sh"'
alias dotcheck='bash "$DOTFILES/scripts/bootstrap.sh" --check'

# 机器专属覆盖（不进仓库）
alias localrc='${EDITOR:-nvim} ~/.zshrc.local'
alias bashlocal='${EDITOR:-nvim} ~/.bashrc.local'
alias gitlocal='${EDITOR:-nvim} ~/.gitconfig.local'
