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
alias dotfiles="cd ~/.dotfiles"
alias shrc="${EDITOR:-nvim} ~/.dotfiles/bash/.bashrc"
alias zshrc="${EDITOR:-nvim} ~/.dotfiles/zsh/.zshrc"
alias tmuxconf="${EDITOR:-nvim} ~/.dotfiles/tmux/.tmux.conf"
alias nvimconf="${EDITOR:-nvim} ~/.config/nvim"
