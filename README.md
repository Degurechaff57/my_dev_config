# dotfiles

Cross-platform development environment configuration. One command to deploy on **macOS** and **Linux**.

- **macOS**: zsh + Oh My Zsh (native zsh experience)
- **Linux**: bash + ble.sh + starship + zoxide + fzf (OMZ-equivalent, no shell replacement needed)

## What's included

| Config | macOS | Linux |
|--------|-------|-------|
| **Shell** | zsh + Oh My Zsh + plugins | bash + ble.sh (autosuggestions) + starship (prompt) |
| **Aliases** | `shared/aliases.sh` | `shared/aliases.sh` (same file!) |
| **Functions** | `shared/functions.sh` | `shared/functions.sh` (same file!) |
| **Environment** | `shared/env.sh` | `shared/env.sh` (same file!) |
| **Tmux** | `tmux/.tmux.conf` | `tmux/.tmux.conf` (same file!) |
| **NeoVim** | `nvim/` LazyVim | `nvim/` LazyVim (same file!) |

> **Why bash on Linux?** Linux defaults to bash. AI tools generate bash commands. Fish breaks AI workflows. ble.sh gives you fish-style autosuggestions + syntax highlighting without leaving bash — no learning curve, no broken scripts.

## Quick start

One command — copy, paste, enter:

```bash
curl -fsSL https://raw.githubusercontent.com/Degurechaff57/dotfiles/main/scripts/bootstrap.sh | bash
```

This auto-clones the repo to `~/.dotfiles`, installs dependencies, and symlinks your config files.

If you've already cloned the repo:

```bash
bash ~/.dotfiles/scripts/bootstrap.sh
```

## Post-install

1. **Fill in your API keys** — edit `~/.dotfiles/shared/secrets.sh` (created from `shared/secrets.sh.example`)
2. **Restart your terminal** or run `exec bash` (Linux) / `exec zsh` (macOS)
3. **Launch NeoVim** — LazyVim will auto-install plugins on first run: `nvim`
4. **Install Nerd Font** — [JetBrains Mono Nerd Font](https://www.nerdfonts.com/) for terminal icons

## Structure

```
~/.dotfiles/
├── bash/
│   └── .bashrc              # Linux entry point (ble.sh + starship + shared/)
├── zsh/
│   ├── .zshrc               # macOS entry point (OMZ + shared/)
│   ├── aliases.zsh           # (deprecated — see shared/)
│   ├── functions.zsh         # (deprecated — see shared/)
│   ├── env.zsh               # (deprecated — see shared/)
│   └── .zshrc.secrets.example
├── shared/                   # Cross-shell configs (sourced by both)
│   ├── env.sh                # OS detection, PATH, XDG, editor, locale
│   ├── aliases.sh            # Git, navigation, modern CLI replacements, clipboard
│   ├── functions.sh          # dev_layout, mkproj, extract
│   └── secrets.sh.example    # Template for API keys (never commit real keys)
├── tmux/
│   └── .tmux.conf            # Vi-mode, cross-platform clipboard
├── nvim/                     # LazyVim configuration (symlinked to ~/.config/nvim)
├── scripts/
│   └── bootstrap.sh          # macOS & Linux one-shot setup
├── pkg/
│   ├── Brewfile              # macOS Homebrew dependencies
│   └── apt-packages.txt      # Linux APT dependencies
├── .gitignore
└── README.md
```

## Linux shell enhancements

The Linux bootstrap installs a bash-native toolchain — no zsh required:

| Tool | Purpose | OMZ equivalent |
|------|---------|----------------|
| **[ble.sh](https://github.com/akinomyoga/ble.sh)** | Fish-style grey autosuggestions + real-time syntax highlighting | `zsh-autosuggestions` + `zsh-syntax-highlighting` |
| **[starship](https://starship.rs/)** | Git-aware prompt (branch, status, language versions, error codes) | `ZSH_THEME` |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | Smarter `cd` — learns your habits, fuzzy-matches directories | `z` plugin |
| **[fzf](https://github.com/junegunn/fzf)** | Ctrl-R fuzzy history, Ctrl-T fuzzy files, Alt-C fuzzy dirs | — |

All four are **pure bash** — zero syntax changes. Every bash command you copy from Stack Overflow, `man` page, or AI still works.

## Platform-specific behavior

| Feature | macOS | Linux |
|---------|-------|-------|
| Shell | zsh + Oh My Zsh | bash + ble.sh + starship |
| Package manager | Homebrew | apt |
| Clipboard | pbcopy | xclip / wl-copy |
| File listing | eza | eza (if installed) |
| Tmux copy | pbcopy | wl-copy > xclip > clip.exe |

## Adding new machines

The bootstrap script is idempotent — run it multiple times safely. Existing config files are backed up with timestamps before being replaced by symlinks.
