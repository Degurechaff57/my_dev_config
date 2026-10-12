# dotfiles

跨平台开发环境配置。一条命令部署到 **macOS** 和 **Linux**。

- **交互 shell**：`zsh` + Oh My Zsh，**两个平台统一** —— 一份配置，无按系统分叉。
- **脚本仍是脚本**：保留各自的 shebang（`#!/usr/bin/env bash`、`#!/usr/bin/env python3`…）。改登录 shell 不影响它们。
- **唯一基线**：本仓库是所有机器的配置来源；机器从仓库部署，而不是反过来。
- **终端**：WezTerm（`wezterm/wezterm.lua`），键位刻意与 VSCode 对齐。

## 包含什么

| 配置 | 两个平台通用 |
|---|---|
| **Shell** | `zsh/.zshrc` → Oh My Zsh + 插件 |
| **别名** | `shared/aliases.sh` |
| **函数** | `shared/functions.sh`（`dev_layout`、`mkproj`、`extract`） |
| **环境变量** | `shared/env.sh`（OS 检测、PATH、XDG、编辑器、locale、history、nvm、MAKEFLAGS） |
| **tmux** | `tmux/.tmux.conf` |
| **git** | `git/.gitconfig` + `git/.gitignore_global` |
| **WezTerm** | `wezterm/wezterm.lua` |
| **NeoVim** | `nvim/`（LazyVim） |
| **机器本地覆盖** | `~/.zshrc.local`、`~/.gitconfig.local`（自动创建，git-ignored） |

## 快速开始

```bash
# 用户态：链接配置、装 Oh My Zsh + 插件，不需要 sudo
git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles
bash ~/.dotfiles/scripts/bootstrap.sh

# 顺便按 pkg/apt-packages.txt 装系统包（Debian/Ubuntu）
bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo
```

可用参数：`--with-sudo`、`--no-nvim`（不动已有的 `~/.config/nvim`）、`--skip-chsh`。

脚本是幂等的，重复运行安全；被替换的文件会加时间戳后缀备份。

## 安装后

1. **切换登录 shell**（一次性，需要密码）：
   ```bash
   chsh -s "$(command -v zsh)"
   ```
2. **重启终端**，或立即进入 zsh：`exec zsh`
3. **启动 NeoVim** —— 首次运行会自动装插件：`nvim`
4. **装 Nerd Font** —— 终端图标需要。WezTerm 首选 **MesloLGM Nerd Font**：
   ```bash
   mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
   curl -fLO "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Meslo/M/LG/complete/MesloLG%20Nerd%20Font%20Complete.ttf"
   fc-cache -f
   ```
   > apt 的 `fonts-jetbrains-mono` 是**非 Nerd 版**，没有图标字形，只能当后备。
5. **机器专属配置** → `~/.zshrc.local`（CUDA/厂商 SDK 的 PATH、`ulimit`、host 专属别名）

## 目录结构

```
~/.dotfiles/
├── zsh/
│   └── .zshrc               # 交互 shell 入口（两个平台共用）
├── shared/                  # 被 zsh source，保持 POSIX-sh 兼容
│   ├── env.sh               # OS 检测、PATH、XDG、编辑器、locale、history、nvm、MAKEFLAGS
│   ├── aliases.sh           # git、导航、安全网、现代 CLI、剪贴板
│   └── functions.sh         # dev_layout、mkproj、extract
├── tmux/
│   └── .tmux.conf           # vi 模式、跨平台剪贴板、Ctrl/Alt+数字 切窗格
├── git/
│   ├── .gitconfig           # 身份、别名、行为（跨机器通用）
│   └── .gitignore_global    # C++/Python/LaTeX 构建产物全局忽略
├── wezterm/
│   └── wezterm.lua          # 终端配置，键位与 VSCode 对齐
├── nvim/                    # LazyVim 配置（软链到 ~/.config/nvim）
├── scripts/
│   ├── bootstrap.sh         # macOS & Linux 一键部署
│   └── bootstrap.ps1        # Windows / PowerShell
├── pkg/
│   ├── Brewfile             # macOS Homebrew 依赖
│   └── apt-packages.txt     # Linux APT 依赖
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── .gitignore
└── README.md
```

## Shell 工具链

全部来自 Oh My Zsh —— 不需要额外安装 shell 工具：

| 需求 | 由谁提供 |
|---|---|
| fish 风格灰色自动建议 | `zsh-autosuggestions` |
| 实时语法高亮 | `zsh-syntax-highlighting` |
| 目录跳转（`z foo`） | `z` 插件 |
| git 别名与提示符状态 | `git` 插件 |
| 提示符 | `ZSH_THEME` |
| 剪贴板辅助 | `copyfile`、`copypath` |

> **为什么两平台都用 zsh 而不是 Linux 上用 bash+ble.sh？** 所有机器一份配置，意味着只有一个地方需要修。
> 上面的插件正好覆盖了 ble.sh + starship + zoxide 的功能，而且活动部件更少（不需要往 `~/.local/bin` 放额外二进制）。
> 脚本不受影响，因为它们保留自己的 shebang。

## 平台差异

| 特性 | macOS | Linux |
|---|---|---|
| 包管理器 | Homebrew（`pkg/Brewfile`） | apt（`pkg/apt-packages.txt`） |
| 剪贴板 | `pbcopy` / `pbpaste` | `wl-copy` / `xclip`（自动检测） |
| tmux 复制（copy-mode 里按 `y`） | `pbcopy` | `wl-copy` → `xclip` → `clip.exe` |
| `update` / `cleanup` 别名 | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |

## 新增一台机器

1. `git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles`
2. `bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo`
3. `chsh -s "$(command -v zsh)"` → 重启终端
4. 任何 host 专属的东西放 `~/.zshrc.local`

后续拉取更新：`git -C ~/.dotfiles pull`（因为是软链，立即生效）。
唯一需要额外一步的是 nvim 插件锁文件 —— 见下。

### 更新 nvim 插件

`nvim/lazy-lock.json` 是提交进仓库的，所以各机器插件版本一致。在一台机器上升级插件后：

```bash
nvim --headless "+Lazy! update" +qa
# ~/.config/nvim 是软链，lazy-lock.json 就是仓库里的那份，无需复制
cd ~/.dotfiles && git add nvim/lazy-lock.json && git commit -m "chore: bump nvim plugins" && git push
```

其它机器：`git -C ~/.dotfiles pull`，然后在 nvim 里 `:Lazy restore`。

## 注意事项

- **仓库里没有密钥。** token 与 API key 放在 `~/.zshrc.local`、`~/.gitconfig.local`（都已 git-ignored）或专用密钥管理器。
- **`~/.bashrc` 不再由本仓库管理**：已最小化为几行注释，仅在手动进入 `bash` 时生效。脚本仍用 bash，但走 shebang，不读该文件。
- **软链清单**：`~/.zshrc`、`~/.tmux.conf`、`~/.gitconfig`、`~/.gitignore_global`、`~/.wezterm.lua`、`~/.config/nvim`。其余文件（如 `~/.bashrc`、`~/.profile`）本仓库不碰。
