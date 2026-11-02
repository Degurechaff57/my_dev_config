# =============================================================================
# Bash login-shell configuration (macOS Terminal starts bash as a login shell)
#
# Order matters and mirrors Debian/Ubuntu's own convention:
#   1. ~/.profile   → login-session env (GUI/session PATH, input-method vars…)
#   2. ~/.bashrc    → interactive config (guarded against double sourcing)
#
# Linux: bash reads ~/.bash_profile INSTEAD of ~/.profile, so sourcing it here
# keeps the Debian behaviour (fcitx/GUI env from ~/.profile) intact.
# macOS: there is usually no ~/.profile; the guard makes this a no-op.
# =============================================================================

# 1) login/session environment (distro-owned file, never overwritten by us)
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# 2) interactive config (safe to source twice — it has its own guard)
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
