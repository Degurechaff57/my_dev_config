# =============================================================================
# Cross-shell functions (bash & zsh)
# Sourced by both .bashrc and .zshrc
# =============================================================================

# ---------- Intelligent 3-pane dev layout ----------
# If tmux session 'dev' exists: attach instantly
# If not: create a 3-pane layout with opencode + nvim
# If already inside tmux: split current window
function dev_layout() {
    # Detect available AI coding assistant (opencode, or fallback to plain shell)
    local ai_cmd=""
    if command -v opencode &>/dev/null; then
        ai_cmd="opencode"
    elif command -v claude &>/dev/null; then
        ai_cmd="claude"
    fi

    if [ -z "$TMUX" ]; then
        # Outside tmux — check for existing session
        tmux has-session -t dev 2>/dev/null
        if [ $? -eq 0 ]; then
            tmux attach-session -t dev
            return
        fi

        # Create fresh session
        tmux new-session -d -s dev
        tmux split-window -h -t dev:0.0 -p 80
        tmux split-window -v -t dev:0.1 -p 50
        if [ -n "$ai_cmd" ]; then
            tmux send-keys -t dev:0.0 "$ai_cmd" C-m
        fi
        tmux send-keys -t dev:0.2 "nvim" C-m
        tmux select-pane -t dev:0.1
        tmux attach-session -t dev
    else
        # Inside tmux — split current window
        tmux split-window -h -p 80
        tmux select-pane -t 1
        tmux split-window -v -p 50
        tmux select-pane -t 0
        if [ -n "$ai_cmd" ]; then
            tmux send-keys "$ai_cmd" C-m
        fi
        tmux select-pane -t 2
        tmux send-keys "nvim" C-m
        tmux select-pane -t 1
    fi
}

# ---------- Quick project scaffolding ----------
function mkproj() {
    if [ -z "$1" ]; then
        echo "Usage: mkproj <project-name>"
        return 1
    fi
    mkdir -p "$1" && cd "$1" && git init && echo "# $1" > README.md
    echo "Project $1 initialized."
}

# ---------- Extract various archives ----------
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xf "$1" ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
