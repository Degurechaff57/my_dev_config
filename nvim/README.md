# 💤 LazyVim — Personal Configuration

My personal [LazyVim](https://github.com/LazyVim/LazyVim) configuration.

## Features

- **Colorscheme**: Tokyo Night (with Catppuccin fallback)
- **Languages**: Go, Rust, Python, C/C++ (clangd), Markdown, TOML
- **Plugins**: blink.cmp, conform.nvim, gitsigns, trouble.nvim, noice.nvim, snacks.nvim, flash.nvim, and more
- **Tools**: stylua, shellcheck, shfmt, flake8 (via Mason)
- **Extras**: mini.surround, mini.pairs, mini.ai, mini.icons

## Requirements

- [Neovim](https://neovim.io/) >= 0.9.0
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (optional, but recommended for icons)
- A C compiler (for treesitter parser compilation) — `gcc`, `clang`, or MSVC on Windows

## Installation

### macOS / Linux

```bash
# 1. Make a backup of your existing Neovim config (if any)
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null

# 2. Clone this repository
git clone https://github.com/Degurechaff57/neovim-config.git ~/.config/nvim

# 3. Launch Neovim — LazyVim will bootstrap itself and install all plugins
nvim
```

### Windows (PowerShell)

```powershell
# 1. Make a backup of your existing Neovim config (if any)
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak -ErrorAction SilentlyContinue
Move-Item $env:LOCALAPPDATA\nvim-data $env:LOCALAPPDATA\nvim-data.bak -ErrorAction SilentlyContinue

# 2. Clone this repository
git clone https://github.com/Degurechaff57/neovim-config.git $env:LOCALAPPDATA\nvim

# 3. Launch Neovim — LazyVim will bootstrap itself and install all plugins
nvim
```

### Windows (Command Prompt)

```cmd
:: 1. Make a backup of your existing Neovim config (if any)
if exist %LOCALAPPDATA%\nvim move %LOCALAPPDATA%\nvim %LOCALAPPDATA%\nvim.bak
if exist %LOCALAPPDATA%\nvim-data move %LOCALAPPDATA%\nvim-data %LOCALAPPDATA%\nvim-data.bak

:: 2. Clone this repository
git clone https://github.com/Degurechaff57/neovim-config.git %LOCALAPPDATA%\nvim

:: 3. Launch Neovim
nvim
```

## Updating

To update all plugins to their latest versions, open Neovim and run:

```
:Lazy sync
```

Or update from the Lazy dashboard by pressing `U`.

## Uninstallation

```bash
# macOS / Linux
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
# Restore your backup if you had one:
# mv ~/.config/nvim.bak ~/.config/nvim
```

```powershell
# Windows (PowerShell)
Remove-Item -Recurse -Force $env:LOCALAPPDATA\nvim
Remove-Item -Recurse -Force $env:LOCALAPPDATA\nvim-data
```
