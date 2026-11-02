# dotfiles

跨平台开发环境配置：**一条命令**部署到 **macOS** 与 **Linux (Ubuntu/Debian)**。

- **交互 shell**：`zsh` + Oh My Zsh，两个平台统一 —— 一份配置，无按系统分叉。
- **bash 仍然可用**：`bash/.bashrc` + `bash/.bash_profile`，与 zsh 共用 `shared/` 里的环境、别名、函数。脚本靠 shebang 运行，不受登录 shell 影响。
- **唯一基线**：本仓库是所有机器的配置来源；机器从仓库部署，而不是反过来。
- **终端**：WezTerm（`wezterm/wezterm.lua`），键位刻意与 VSCode 对齐。
- **部署会先问**：任何会覆盖你已有配置的操作都要确认，被替换的内容先备份。

## 包含什么

| 配置 | 由谁提供 | 两个平台通用 |
|---|---|---|
| **zsh** | `zsh/.zshrc`（→ `~/.zshrc`） | ✅ |
| **bash** | `bash/.bashrc`、`bash/.bash_profile` | ✅ |
| **别名** | `shared/aliases.sh`（zsh/bash 共用） | ✅ |
| **函数** | `shared/functions.sh`（`dev_layout`、`mkproj`、`extract`） | ✅ |
| **环境变量** | `shared/env.sh`（OS 检测、PATH、XDG、编辑器、locale、history、nvm、MAKEFLAGS） | ✅ |
| **tmux** | `tmux/.tmux.conf` | ✅ |
| **git** | `git/.gitconfig` + `git/.gitignore_global` | ✅ |
| **WezTerm** | `wezterm/wezterm.lua`（→ `~/.wezterm.lua`） | ✅ |
| **NeoVim / LazyVim** | `nvim/`（→ `~/.config/nvim`） | ✅ |
| **机器本地覆盖** | `~/.zshrc.local`、`~/.bashrc.local`、`~/.gitconfig.local`（自动创建，git-ignored） | 每台机器自己写 |

## 快速开始

```bash
# 1. 克隆
git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles

# 2. 部署（交互式：改动已有配置前会询问）
bash ~/.dotfiles/scripts/bootstrap.sh

# 变体
bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo    # 顺便装系统包（apt / brew）
bash ~/.dotfiles/scripts/bootstrap.sh --dry-run      # 先看看会动哪些文件
bash ~/.dotfiles/scripts/bootstrap.sh --check        # 只检查软链是否就位
bash ~/.dotfiles/scripts/bootstrap.sh --yes          # 无人值守（新机器/CI，仍先备份）
```

装完执行 `exec zsh`，首次运行 `nvim` 会自动安装 LazyVim 插件。

仓库**不必**放在 `~/.dotfiles`：`zsh/.zshrc` 与 `bash/.bashrc` 会从自身真实路径反解仓库位置，克隆到任何目录都能用（`DOTFILES_DIR` 可覆盖脚本的判断）。

## 部署脚本会做什么

| 情况 | 行为 |
|---|---|
| 目标路径不存在 | 直接创建软链，不询问 |
| 目标已是正确软链 | 跳过，不询问 |
| 目标是别的文件/目录/软链 | **询问**：`[b]`备份替换（默认） / `[o]`直接覆盖 / `[s]`跳过 / `[d]`看差异 / `[q]`退出 / `[a]`之后全部备份替换 |
| 目标是非空目录（如 `~/.config/nvim`） | 先备份目录，再额外确认一次 |
| 要装系统包（`--with-sudo`） | 先询问，再走 sudo |
| 要装 Oh My Zsh / 插件 | 先询问 |
| 切换登录 shell（`chsh`） | 只提示；回答 yes 才执行，默认 no |

- **备份位置**：`~/.dotfiles-backup/<时间戳>/`，保留原路径结构。恢复：`mv ~/.dotfiles-backup/<时间戳>/.zshrc ~/.zshrc`。
- **幂等**：重复运行安全；已就位的软链不会重复处理。
- **非交互环境**（`curl | bash`、CI）：默认**不**做破坏性改动，只提示；需要无人值守请显式 `--yes`。
- 全部参数：`bash ~/.dotfiles/scripts/bootstrap.sh --help`。

## 目录结构

```
~/.dotfiles/
├── zsh/
│   └── .zshrc               # 交互 shell 入口（自解析仓库位置）
├── bash/
│   ├── .bashrc              # 交互 bash（非交互 bash 静默返回）
│   └── .bash_profile        # 登录 bash（macOS Terminal 会读它）
├── shared/                  # 被 zsh / bash 共同 source
│   ├── env.sh               # OS 检测、PATH、XDG、编辑器、locale、history、nvm、MAKEFLAGS
│   ├── aliases.sh           # git、导航、安全网、现代 CLI、剪贴板、dotfiles 快捷编辑
│   └── functions.sh         # dev_layout、mkproj、extract
├── tmux/
│   └── .tmux.conf           # vi 模式、跨平台剪贴板、Ctrl/Alt+数字切窗格
├── git/
│   ├── .gitconfig           # 身份、别名、行为（跨机器通用；include ~/.gitconfig.local）
│   └── .gitignore_global
├── wezterm/
│   └── wezterm.lua          # 终端配置，键位与 VSCode 对齐
├── nvim/                    # LazyVim 配置（软链到 ~/.config/nvim）
├── scripts/
│   ├── bootstrap.sh         # macOS & Linux 一键部署（带冲突询问）
│   └── bootstrap.ps1        # Windows / PowerShell
├── pkg/
│   ├── Brewfile             # macOS Homebrew 依赖
│   └── apt-packages.txt     # Linux APT 依赖
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── .gitignore
└── README.md
```

软链清单（由脚本维护）：

```
~/.zshrc  ~/.bashrc  ~/.bash_profile  ~/.tmux.conf
~/.gitconfig  ~/.gitignore_global  ~/.wezterm.lua  ~/.config/nvim
```

**不**由本仓库接管的：`~/.profile`（发行版/GUI 会话文件，见下）、`~/.bash_logout`、`~/.oh-my-zsh`（外部安装）。

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

bash 只是备用交互 shell：它 source 同一份 `shared/`，但没有 OMZ 的插件层。

> **为什么交互 shell 统一到 zsh 而不是 Linux 用 bash？** 所有机器一份配置，意味着只有一个地方需要修。
> 上面的插件正好覆盖了 ble.sh + starship + zoxide 的功能，而且活动部件更少。

## 平台差异

| 特性 | macOS | Linux (Ubuntu/Debian) |
|---|---|---|
| 包管理器 | Homebrew（`pkg/Brewfile`） | apt（`pkg/apt-packages.txt`） |
| bash 版本 | 系统自带 3.2（脚本兼容 3.2） | 5.x |
| 登录 shell 文件 | bash 读 `~/.bash_profile`；zsh 读 `~/.zprofile` | bash 读 `~/.bash_profile`（没有才读 `~/.profile`） |
| `~/.profile` | 通常不存在 | 发行版自带，GUI 会话读它（输入法变量等） |
| 剪贴板 | `pbcopy` / `pbpaste` | `wl-copy` / `xclip`（自动检测） |
| tmux 复制（copy-mode 里按 `y`） | `pbcopy` | `wl-copy` → `xclip` → `clip.exe` |
| `update` / `cleanup` 别名 | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |

**关于 `~/.profile`**：它属于机器/发行版，不由本仓库软链。Linux 上输入法变量（`GTK_IM_MODULE=fcitx` 等）就写在那里；我们的 `~/.bash_profile` 会 `source ~/.profile`，所以 bash 登录会话仍拿得到这些变量。macOS 没有这个文件时该步骤自动跳过。

## 新增一台机器

```bash
git clone git@github.com:Degurechaff57/my_dev_config.git ~/.dotfiles
bash ~/.dotfiles/scripts/bootstrap.sh --with-sudo
exec zsh
```

1. 脚本会询问每一处冲突（老配置 → 备份 → 软链）。
2. 需要切换登录 shell 时按提示回答，或手动 `chsh -s "$(command -v zsh)"`。
3. 机器专属的东西写进 `~/.zshrc.local` / `~/.bashrc.local` / `~/.gitconfig.local`，不要改仓库里的文件。

## 更新

```bash
git -C ~/.dotfiles pull      # 软链立即生效；新 shell 会话即可看到
bash ~/.dotfiles/scripts/bootstrap.sh --check   # 检查软链有没有被第三方安装器改掉
```

### 更新 nvim 插件

`nvim/lazy-lock.json` 提交进仓库，各机器插件版本一致。在一台机器上升级后：

```bash
nvim --headless "+Lazy! update" +qa
# ~/.config/nvim 是软链，lazy-lock.json 就是仓库里的那份，无需复制
cd ~/.dotfiles && git add nvim/lazy-lock.json && git commit -m "chore: bump nvim plugins" && git push
```

其它机器：`git -C ~/.dotfiles pull`，然后在 nvim 里 `:Lazy restore`。

## 注意事项

- **仓库里没有密钥。** token / API key / 代理 / credential helper 放 `~/.zshrc.local`、`~/.bashrc.local`、`~/.gitconfig.local`（都 git-ignored）或专用密钥管理器。
- **第三方安装器的坑**：`agy`、nvm 等会往 `~/.zshrc` 追加绝对路径。由于 `~/.zshrc` 是软链，这会**写进仓库**，在另一台机器上变成无效的 `/home/<user>/...`。这类内容请移到 `~/.zshrc.local`；`bootstrap.sh --check` 能帮你确认软链没被替换。
- **不要在仓库里写死代理**（`http.proxy=127.0.0.1:...`）：换机器后 git 会直接失败。
- **Nerd Font 需另装**：WezTerm 首选 `MesloLGM Nerd Font`（脚本不装字体）。apt 的 `fonts-jetbrains-mono` 是非 Nerd 版，只能当后备。
- **`--yes` 的边界**：它会同意所有提问（含装包），唯一例外是 `chsh` —— 需要密码，非交互模式下只打印命令。
