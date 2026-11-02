# =============================================================================
# Bash configuration — the fallback interactive shell
#
# zsh is the login shell on every machine (zsh/.zshrc).  This file only runs
# when you explicitly type `bash`, or when an IDE/SSH session starts bash.
# Scripts are unaffected: they keep their shebang and never read this file.
#
# Portable on both macOS (bash 3.2) and Linux: no bash-4+ features.
# =============================================================================

# ---------- Non-interactive bash must stay silent ----------
# (`bash script.sh`, scp, ssh command, CI). Returns when sourced, exits when run.
case $- in
    *i*) ;;
      *) return 2>/dev/null || exit 0 ;;
esac

# ---------- Resolve the repo root from this file's REAL path ----------
# ~/.bashrc is a symlink into the repo; follow it so any clone location works.
# bash 3.2 compatible (no ${var@Q}, no readlink -f).
_dotfiles_resolve() {
    local p="$1" d
    while [ -L "$p" ]; do
        d="$(cd -P "$(dirname "$p")" 2>/dev/null && pwd)" || break
        p="$(readlink "$p")"
        case "$p" in /*) ;; *) p="$d/$p" ;; esac
    done
    cd -P "$(dirname "$p")" 2>/dev/null && pwd
}
DOTFILES="$(cd "$(_dotfiles_resolve "${BASH_SOURCE[0]:-$HOME/.bashrc}")/.." 2>/dev/null && pwd)"
[ -n "${DOTFILES-}" ] && [ -d "$DOTFILES/shared" ] || DOTFILES="${HOME}/.dotfiles"
unset -f _dotfiles_resolve

# Debian/Ubuntu: ~/.profile sources this file, and our ~/.bash_profile sources
# ~/.profile — guard against the double load.
if [ -n "${_DOTFILES_BASHRC_LOADED-}" ]; then
    return 0 2>/dev/null || exit 0
fi
_DOTFILES_BASHRC_LOADED=1

# ---------- Shared config — the same files zsh sources ----------
[ -f "$DOTFILES/shared/env.sh" ]       && . "$DOTFILES/shared/env.sh"
[ -f "$DOTFILES/shared/aliases.sh" ]   && . "$DOTFILES/shared/aliases.sh"
[ -f "$DOTFILES/shared/functions.sh" ] && . "$DOTFILES/shared/functions.sh"

# ---------- bash-only niceties ----------
shopt -s checkwinsize 2>/dev/null || true
shopt -s histappend 2>/dev/null || true
bind 'set enable-bracketed-paste on' 2>/dev/null || true

# Readline: case-insensitive completion, no bell on ambiguous tabs
bind 'set completion-ignore-case on' 2>/dev/null || true
bind 'set bell-style none' 2>/dev/null || true
HISTCONTROL="ignoreboth:erasedups"

# ---------- bash-completion (shipped by apt / Homebrew, optional) ----------
if ! shopt -q -o posix; then
    for _f in \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        /usr/local/etc/profile.d/bash_completion.sh \
        /opt/homebrew/etc/profile.d/bash_completion.sh; do
        if [ -r "$_f" ]; then
            . "$_f"
            break
        fi
    done
    unset _f
fi

# ---------- Prompt ----------
# Only when the distro did not set one; keeps bash usable without overriding
# a distro/IDE prompt.
if [ -z "${PS1-}" ]; then
    PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
fi

# ---------- Machine-local additions (NOT tracked by git) ----------
# Host-only PATH entries, vendor SDK env, ulimit tweaks, host-only aliases.
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
