# dotfiles

Cross-platform development environment configuration. One command to deploy on **macOS**, **Linux**, and **Windows** (PowerShell + WSL2).

## What's included

| Config | Path | Description |
|--------|------|-------------|
| **Zsh** | `zsh/.zshrc` | Oh My Zsh with modular aliases, functions, env vars |
| **Tmux** | `tmux/.tmux.conf` | Vi-mode, cross-platform clipboard (pbcopy/xclip/wl-copy/clip.exe) |
| **NeoVim** | `nvim/` | LazyVim distribution with Python/Rust/Go/TypeScript support |
| **PowerShell** | `powershell/` | Windows PowerShell profile with Unix-like aliases |

## Quick start

### macOS

```bash
git clone https://github.com/tsumorikawa99/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/scripts/bootstrap.sh
```

### Linux (Debian/Ubuntu)

```bash
git clone https://github.com/tsumorikawa99/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/scripts/bootstrap.sh
```

### Windows

```powershell
git clone https://github.com/tsumorikawa99/dotfiles.git $env:USERPROFILE\.dotfiles
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\.dotfiles\scripts\bootstrap.ps1
```

## Post-install

1. **Fill in your API keys** — edit `~/.dotfiles/zsh/.zshrc.secrets` (created from `.zshrc.secrets.example`)
2. **Restart your terminal** or run `exec zsh`
3. **Launch NeoVim** — LazyVim will auto-install plugins on first run: `nvim`
4. **Install Nerd Font** — [JetBrains Mono Nerd Font](https://www.nerdfonts.com/) for terminal icons

## Structure

```
~/.dotfiles/
├── zsh/
│   ├── .zshrc              # Main shell config (sources the modules below)
│   ├── aliases.zsh         # Git, navigation, system aliases
│   ├── functions.zsh       # dev_layout, mkproj, extract helpers
│   ├── env.zsh             # Cross-platform environment variables
│   └── .zshrc.secrets.example  # Template for API keys (never commit real keys)
├── tmux/
│   └── .tmux.conf          # Vi-mode, cross-platform clipboard, pane navigation
├── nvim/                   # LazyVim configuration (symlinked to ~/.config/nvim)
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── scripts/
│   ├── bootstrap.sh        # macOS & Linux one-shot setup
│   └── bootstrap.ps1       # Windows PowerShell + WSL2 setup
├── pkg/
│   ├── Brewfile            # macOS Homebrew dependencies
│   └── apt-packages.txt    # Linux APT dependencies
├── .gitignore
└── README.md
```

## Platform-specific behavior

| Feature | macOS | Linux | Windows PowerShell |
|---------|-------|-------|--------------------|
| Package manager | Homebrew | apt (detected) | winget |
| Clipboard | pbcopy | xclip / wl-copy | Set-Clipboard |
| File listing | eza | eza (if installed) | eza / Get-ChildItem |
| Tmux copy | pbcopy | wl-copy > xclip > clip.exe | clip.exe (in WSL) |

## Adding new machines

The bootstrap scripts are idempotent — run them multiple times safely. Existing config files are backed up with timestamps before being replaced by symlinks.
