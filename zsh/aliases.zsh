# =============================================================================
# Cross-platform aliases
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

# ---------- System ----------
if [ "$OS" = "macos" ]; then
    alias update="brew update && brew upgrade"
    alias cleanup="brew cleanup && brew autoremove"
elif [ "$OS" = "linux" ]; then
    alias update="sudo apt update && sudo apt upgrade -y"
    alias cleanup="sudo apt autoremove -y && sudo apt autoclean"
fi

# ---------- Quick edit dotfiles ----------
alias dotfiles="cd ~/.dotfiles"
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias tmuxconf="nvim ~/.dotfiles/tmux/.tmux.conf"
alias nvimconf="nvim ~/.config/nvim"
