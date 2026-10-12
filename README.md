# dotfiles

Cross-platform development environment configuration. One command to deploy on **macOS** and **Linux**.

- **Interactive shell**: `zsh` + Oh My Zsh on **both** platforms — one config, no per-OS divergence.
- **Scripts stay as scripts**: they keep their shebang (`#!/usr/bin/env bash`, `#!/usr/bin/env python3`, …). Changing the login shell does not affect them.
- **Baseline for everything**: this repo is the single source of truth. Machines are deployed from it, not the other way around.

## What's included

| Config | Both platforms |
|--------|----------------|
| **Shell** | `zsh/.zshrc` → Oh My Zsh + plugins |
| **Aliases** | `shared/aliases.sh` |
| **Functions** | `shared/functions.sh` (`dev_layout`, `mkproj`, `extract`) |
| **Environment** | `shared/env.sh` (OS detection, PATH, XDG, editor, locale, history) |
| **Tmux** | `tmux/.tmux.conf` |
| **NeoVim** | `nvim/` (LazyVim) |
| **Machine-local overrides** | `~/.zshrc.local` (created empty, git-ignored) |

## Quick start

```bash
# user-space: links configs, installs Oh My Zsh + plugins, no sudo
git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles
bash ~/.dotfiles/scripts/bootstrap.sh

# also install system packages from pkg/apt-packages.txt (Debian/Ubuntu)
bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo
```

Flags: `--with-sudo`, `--no-nvim` (leave an existing `~/.config/nvim` alone), `--skip-chsh`.

The script is idempotent — run it as often as you like. Files it replaces are backed up with a timestamp suffix.

## Post-install

1. **Switch login shell** (one-time, needs your password):
   ```bash
   chsh -s "$(command -v zsh)"
   ```
2. **Restart your terminal**, or enter zsh immediately with `exec zsh`.
3. **Launch NeoVim** — LazyVim installs plugins on first run: `nvim`
4. **Install a Nerd Font** — [JetBrains Mono Nerd Font](https://www.nerdfonts.com/) for terminal icons.
5. **Host-specific config** → `~/.zshrc.local` (CUDA/vendor SDK PATH, `ulimit`, host-only aliases).

## Structure

```
~/.dotfiles/
├── zsh/
│   └── .zshrc               # THE interactive shell entry point (both platforms)
├── shared/                  # sourced by zsh, kept POSIX-sh compatible
│   ├── env.sh               # OS detection, PATH, XDG, editor, locale, history, MAKEFLAGS
│   ├── aliases.sh           # git, navigation, safety nets, modern CLI, clipboard
│   └── functions.sh         # dev_layout, mkproj, extract
├── tmux/
│   └── .tmux.conf           # vi mode, cross-platform clipboard, Ctrl/Alt+N pane jumps
├── nvim/                    # LazyVim config (symlinked to ~/.config/nvim)
├── scripts/
│   ├── bootstrap.sh         # macOS & Linux one-shot setup
│   └── bootstrap.ps1        # Windows / PowerShell
├── pkg/
│   ├── Brewfile             # macOS Homebrew dependencies
│   └── apt-packages.txt     # Linux APT dependencies
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── .gitignore
└── README.md
```

## Shell stack

Everything comes from Oh My Zsh — no external shell tooling to install:

| Need | Provided by |
|------|-------------|
| Fish-style grey autosuggestions | `zsh-autosuggestions` |
| Real-time syntax highlighting | `zsh-syntax-highlighting` |
| Directory jumping (`z foo`) | `z` plugin |
| Git aliases & status in prompt | `git` plugin |
| Prompt | `ZSH_THEME` |
| Clipboard helpers | `copyfile`, `copypath` |

> **Why zsh everywhere instead of bash+ble.sh on Linux?** One config for all machines means one place to fix things. The plugins above cover exactly what ble.sh + starship + zoxide did, with fewer moving parts (no separate binaries in `~/.local/bin`). Scripts are unaffected because they keep their shebang.

## Platform-specific behavior

| Feature | macOS | Linux |
|---------|-------|-------|
| Package manager | Homebrew (`pkg/Brewfile`) | apt (`pkg/apt-packages.txt`) |
| Clipboard | `pbcopy` / `pbpaste` | `wl-copy` / `xclip` (auto-detected) |
| Tmux copy (`y` in copy-mode) | `pbcopy` | `wl-copy` → `xclip` → `clip.exe` |
| `update` / `cleanup` aliases | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |

## Adding new machines

1. `git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles`
2. `bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo`
3. `chsh -s "$(command -v zsh)"` → restart terminal
4. Put anything host-specific in `~/.zshrc.local`

To pull later changes: `git -C ~/.dotfiles pull` (symlinks mean it takes effect immediately). Bumping the nvim plugin lock is the one thing that needs an explicit step — see below.

### Updating nvim plugins

`nvim/lazy-lock.json` is committed, so machines share plugin versions. After updating plugins on one machine:

```bash
nvim --headless "+Lazy! update" +qa
cp ~/.config/nvim/lazy-lock.json ~/.dotfiles/nvim/lazy-lock.json   # symlink → same file
cd ~/.dotfiles && git add nvim/lazy-lock.json && git commit -m "chore: bump nvim plugins" && git push
```

On other machines: `git -C ~/.dotfiles pull` then `:Lazy restore` inside nvim.

## Notes

- **No secrets in this repo.** Tokens and API keys live in `~/.zshrc.local` (git-ignored) or a dedicated secret manager.
- **`~/.bashrc` / `~/.tmux.conf` behaviour**: only `~/.zshrc`, `~/.tmux.conf` and `~/.config/nvim` are symlinked. Your old `~/.bashrc` is left untouched (bash is still there for scripts).
