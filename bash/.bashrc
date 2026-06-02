# =============================================================================
# Bash configuration — Linux-native, OMZ-equivalent experience
#
# Toolchain:
#   ble.sh    → autosuggestions (fish-style grey previews) + syntax highlighting
#   starship  → cross-shell prompt (git status, language versions, etc.)
#   zoxide    → smarter cd / "z" directory jumping
#   fzf       → fuzzy search (Ctrl-R history, Ctrl-T files, Alt-C dirs)
#
# All four are pure bash-compatible — no shell syntax changes, no breaking
# AI-generated bash commands (unlike fish).
# =============================================================================

# ---------- Guard: interactive shells only ----------
[[ $- != *i* ]] && return

# ---------- Shared environment (OS detection, PATH, XDG, editor, locale) ----------
DOTFILES="${HOME}/.dotfiles"
[ -f "$DOTFILES/shared/env.sh" ] && source "$DOTFILES/shared/env.sh"

# ---------- ble.sh — autosuggestions + syntax highlighting ----------
# Pure bash script. Fish-style grey autosuggestions + real-time syntax highlighting.
# Install: bootstrap.sh downloads pre-built nightly from GitHub releases
_ble_path="${HOME}/.local/share/blesh/ble.sh"
if [ -f "$_ble_path" ]; then
    source "$_ble_path" --attach=none
    # ble.sh may not define bleopt in non-TTY environments
    if command -v bleopt &>/dev/null; then
        # Disable the built-in clock in ble.sh's prompt (starship handles the prompt)
        bleopt prompt_clock_show=
    fi
fi
unset _ble_path

# ---------- Starship — cross-shell prompt ----------
# Shows: git branch/status, language versions, command duration, error codes.
# Install: curl -sS https://starship.rs/install.sh | sh
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# ---------- zoxide — smarter cd (replaces "z" plugin) ----------
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# ---------- fzf — fuzzy finder keybindings ----------
# Ctrl-R: fuzzy history search | Ctrl-T: fuzzy file search | Alt-C: fuzzy cd
if command -v fzf &>/dev/null; then
    # Try built-in init first (fzf >= 0.48)
    if fzf --bash &>/dev/null 2>&1; then
        eval "$(fzf --bash)"
    else
        # Fallback: source key-bindings from various possible paths
        for _fzf_kb in \
            "/usr/share/doc/fzf/examples/key-bindings.bash" \
            "$HOME/.local/share/fzf/shell/key-bindings.bash"; do
            if [ -f "$_fzf_kb" ]; then
                source "$_fzf_kb"
                break
            fi
        done
        unset _fzf_kb
    fi
fi

# ---------- Shared aliases ----------
[ -f "$DOTFILES/shared/aliases.sh" ] && source "$DOTFILES/shared/aliases.sh"

# ---------- Shared functions ----------
[ -f "$DOTFILES/shared/functions.sh" ] && source "$DOTFILES/shared/functions.sh"

# ---------- Secrets (API keys etc. — NEVER committed to git) ----------
[ -f "$DOTFILES/shared/secrets.sh" ] && source "$DOTFILES/shared/secrets.sh"
