#!/usr/bin/env bash
# =============================================================================
# Dotfiles 部署脚本 — macOS 与 Linux(Ubuntu/Debian) 通用
#
#   bash ~/.dotfiles/scripts/bootstrap.sh              # 交互式（默认）
#   bash ~/.dotfiles/scripts/bootstrap.sh --yes        # 无人值守，全部自动（仍先备份）
#   bash ~/.dotfiles/scripts/bootstrap.sh --dry-run    # 只打印计划，不动文件
#   bash ~/.dotfiles/scripts/bootstrap.sh --check      # 只检查软链是否就位
#
# 管理的路径（软链到本仓库）：
#   ~/.zshrc  ~/.bashrc  ~/.bash_profile  ~/.tmux.conf
#   ~/.gitconfig  ~/.gitignore_global  ~/.wezterm.lua  ~/.config/nvim
#
# 冲突处理（核心行为）：
#   目标不存在              → 直接创建软链，不询问
#   目标已是正确软链        → 跳过，不询问
#   目标是别的文件/目录/软链 → 询问：
#        [b] 备份后替换（默认）   [o] 直接覆盖   [s] 跳过
#        [d] 查看差异             [q] 退出        [a] 之后全部按备份替换
#   被替换的内容先移动到 ~/.dotfiles-backup/<时间戳>/ 下（保留原路径结构）
#
# 常用参数见 --help。
# 环境变量覆盖：DOTFILES_DIR、DOTFILES_REPO_URL、DOTFILES_BACKUP_ROOT
# =============================================================================
set -uo pipefail

# ---------- 默认值 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
REPO_URL="${DOTFILES_REPO_URL:-git@github.com:Degurechaff57/my_dev_config.git}"
BACKUP_ROOT="${DOTFILES_BACKUP_ROOT:-$HOME/.dotfiles-backup}"
BACKUP_DIR=""

OS_NAME="$(uname -s)"          # Darwin | Linux
WITH_SUDO=false
WITH_NVIM=true
WITH_BASH=true
WITH_ZSH_SETUP=true
OFFER_CHSH=true
ASSUME_YES=false
DRY_RUN=false
FORCE_INTERACTIVE=false
CHECK_ONLY=false

LINKED=0
UPDATED=0
SKIPPED=0
BACKED_UP=0
PLANNED=0

# ---------- 颜色（仅终端） ----------
if [ -t 1 ]; then
    CL_RED=$'\033[0;31m'; CL_GREEN=$'\033[0;32m'; CL_YELLOW=$'\033[1;33m'
    CL_BLUE=$'\033[0;34m'; CL_DIM=$'\033[2m'; CL_OFF=$'\033[0m'
else
    CL_RED=''; CL_GREEN=''; CL_YELLOW=''; CL_BLUE=''; CL_DIM=''; CL_OFF=''
fi
info()  { printf '%s[INFO]%s  %s\n' "$CL_GREEN" "$CL_OFF" "$*"; }
ok()    { printf '%s[ OK ]%s  %s\n' "$CL_GREEN" "$CL_OFF" "$*"; }
warn()  { printf '%s[WARN]%s  %s\n' "$CL_YELLOW" "$CL_OFF" "$*"; }
err()   { printf '%s[ERR ]%s  %s\n' "$CL_RED" "$CL_OFF" "$*" >&2; }
note()  { printf '%s        %s%s\n' "$CL_DIM" "$*" "$CL_OFF"; }
head_() { printf '\n%s== %s ==%s\n' "$CL_BLUE" "$*" "$CL_OFF"; }

# 把 /home/user/xxx 显示成 ~/xxx
# 注意：不能用 ${1/#$HOME/~} —— bash 会把替换串里的 ~ 再展开成 $HOME，
# 结果只是把前缀换成了同一个绝对路径，什么都没缩短。
tilde() {
    case "$1" in
        "$HOME")   printf '~' ;;
        "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
        *)         printf '%s' "$1" ;;
    esac
}

usage() {
    cat <<'USAGE'
Dotfiles 部署脚本 — macOS 与 Linux(Ubuntu/Debian) 通用

用法:
  bash ~/.dotfiles/scripts/bootstrap.sh              # 交互式（默认）
  bash ~/.dotfiles/scripts/bootstrap.sh --yes        # 无人值守，全部自动（仍先备份）
  bash ~/.dotfiles/scripts/bootstrap.sh --dry-run    # 只打印计划，不动文件
  bash ~/.dotfiles/scripts/bootstrap.sh --check      # 只检查软链是否就位

管理的路径（软链到本仓库）:
  ~/.zshrc  ~/.bashrc  ~/.bash_profile  ~/.tmux.conf
  ~/.gitconfig  ~/.gitignore_global  ~/.wezterm.lua  ~/.config/nvim

冲突处理:
  目标不存在              → 直接创建软链，不询问
  目标已是正确软链        → 跳过，不询问
  目标是别的文件/目录/软链 → 询问 [b]备份替换(默认) [o]覆盖 [s]跳过 [d]差异 [q]退出 [a]全部
  被替换的内容先移入 ~/.dotfiles-backup/<时间戳>/（保留原路径结构，可原样恢复）

参数:
  -y, --yes            非交互：全部同意（危险操作仍会先备份）
      --dry-run        演练：只打印将要做的事
      --interactive    即使 stdin 不是 tty 也强制询问
      --check          只检查软链，不修改；全部就位返回 0
      --with-sudo      安装系统包（apt / brew），会二次确认
      --no-nvim        不动 ~/.config/nvim
      --no-bash        不动 ~/.bashrc / ~/.bash_profile
      --no-zsh-setup   不安装/更新 Oh My Zsh 及插件
      --skip-chsh      不提示切换登录 shell
      --backup-dir DIR 备份根目录（默认 ~/.dotfiles-backup）
  -h, --help           显示本帮助

环境变量: DOTFILES_DIR / DOTFILES_REPO_URL / DOTFILES_BACKUP_ROOT
USAGE
}

# =============================================================================
# 参数解析
# =============================================================================
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)        ASSUME_YES=true ;;
        --dry-run)       DRY_RUN=true ;;
        --interactive)   FORCE_INTERACTIVE=true ;;
        --check)         CHECK_ONLY=true ;;
        --with-sudo)     WITH_SUDO=true ;;
        --no-nvim)       WITH_NVIM=false ;;
        --no-bash)       WITH_BASH=false ;;
        --no-zsh-setup)  WITH_ZSH_SETUP=false ;;
        --skip-chsh)     OFFER_CHSH=false ;;
        --backup-dir)    shift; BACKUP_ROOT="${1:?--backup-dir 需要一个目录}" ;;
        -h|--help)       usage; exit 0 ;;
        *)               err "未知参数：$1（试 --help）"; exit 1 ;;
    esac
    shift
done

if [ "$DRY_RUN" = true ] && [ "$CHECK_ONLY" = true ]; then
    err "--dry-run 与 --check 不能同时使用（--check 本身不会改文件）"
    exit 1
fi

# =============================================================================
# 交互与询问
# =============================================================================
# 保存“真正的”标准输入到 fd 3。
# 原因：解析受管路径用的是 `while read ... <<EOF`，它会把循环体的 stdin 换成
# 仓库里的路径清单；此时函数里的 `read` 若还读 fd 0，就会把清单当成用户输入
# 吃掉（真遇到过）。所有询问统一从 fd 3 读，与循环重定向互不干扰。
exec 3<&0

can_prompt() {
    [ "$FORCE_INTERACTIVE" = true ] && return 0
    [ "$ASSUME_YES" = true ] && return 1
    [ -t 0 ] || [ -t 3 ]
}

# ask <问题> <默认 y|n>  → 0 = yes
ask() {
    local q="$1" def="${2:-n}" ans
    if [ "$ASSUME_YES" = true ] || ! can_prompt; then
        [ "$def" = y ] && return 0 || return 1
    fi
    while :; do
        printf '%s ' "$q"
        if ! IFS= read -r ans <&3; then
            printf '\n'
            return 1
        fi
        ans="${ans:-$def}"
        case "$ans" in
            [yY]*) return 0 ;;
            [nN]*) return 1 ;;
            *) warn "请输入 y 或 n（回车 = 默认 ${def}）" ;;
        esac
    done
}

describe_target() {
    local t="$1"
    if [ -L "$t" ]; then
        printf '软链 → %s' "$(readlink "$t" 2>/dev/null)"
    elif [ -d "$t" ]; then
        printf '目录（%s 个条目）' "$(ls -A "$t" 2>/dev/null | wc -l | tr -d ' ')"
    else
        printf '文件（%s 字节）' "$(wc -c < "$t" 2>/dev/null | tr -d ' ')"
    fi
}

show_diff() {
    local t="$1" s="$2"
    if [ -d "$t" ] && [ ! -L "$t" ]; then
        warn "目标是目录，无法逐行比较。目录内容概览："
        ( cd "$t" 2>/dev/null && find . -maxdepth 2 -type f | head -20 ) || true
        return 0
    fi
    [ -L "$t" ] && return 0
    if command -v diff >/dev/null 2>&1; then
        printf '%s' "$CL_DIM"
        diff -u "$t" "$s" 2>/dev/null | head -60 || true
        printf '%s' "$CL_OFF"
    else
        warn "系统没有 diff，无法显示差异"
    fi
}

ALWAYS_ACTION=""

# choose_action <目标> <源> <说明> → 结果写入全局 ACTION: b|o|s|q|dry
choose_action() {
    local target="$1" source="$2" desc="$3" ans

    if [ -n "$ALWAYS_ACTION" ]; then ACTION="$ALWAYS_ACTION"; return 0; fi
    if [ "$DRY_RUN" = true ]; then ACTION="dry"; return 0; fi
    if [ "$ASSUME_YES" = true ]; then ACTION="b"; return 0; fi
    if ! can_prompt; then
        ACTION="s"
        warn "非交互环境：跳过 $(tilde "$target")"
        note "用 --yes 自动备份替换，或 --interactive 强制询问"
        return 0
    fi

    printf '\n'
    printf '  %s需要改动已有配置：%s%s\n' "$CL_YELLOW" "$desc" "$CL_OFF"
    printf '    目标   : %s\n' "$(tilde "$target")"
    printf '    现状   : %s\n' "$(describe_target "$target")"
    printf '    将变为 : 软链 → %s\n' "$(tilde "$source")"
    printf '    备份到 : %s\n' "$(tilde "$BACKUP_DIR/${target#"$HOME"/}")"

    while :; do
        printf '    选择 [b]备份替换 / [o]覆盖 / [s]跳过 / [d]差异 / [q]退出 / [a]全部备份替换 : '
        if ! IFS= read -r ans <&3; then
            printf '\n'
            ACTION="s"; return 0
        fi
        case "$ans" in
            ""|b|B) ACTION="b"; return 0 ;;
            o|O)    ACTION="o"; return 0 ;;
            s|S)    ACTION="s"; return 0 ;;
            d|D)    show_diff "$target" "$source"; continue ;;
            q|Q)    ACTION="q"; return 0 ;;
            a|A)    ALWAYS_ACTION="b"; ACTION="b"; return 0 ;;
            *)      warn "无效选择：$ans" ;;
        esac
    done
}

# =============================================================================
# 软链操作
# =============================================================================
backup_existing() {
    local target="$1" rel dest
    rel="${target#"$HOME"/}"
    dest="$BACKUP_DIR/$rel"
    if [ "$DRY_RUN" = true ]; then
        note "[演练] 备份 $(tilde "$target") → $(tilde "$dest")"
        return 0
    fi
    mkdir -p "$(dirname "$dest")" || return 1
    if mv "$target" "$dest" 2>/dev/null; then
        BACKED_UP=$((BACKED_UP + 1))
        ok "已备份：$(tilde "$target") → $(tilde "$dest")"
        return 0
    fi
    err "备份失败：$target"
    return 1
}

create_link() {
    local target="$1" source="$2"
    if [ "$DRY_RUN" = true ]; then
        note "[演练] 创建软链 $(tilde "$target") → $(tilde "$source")"
        return 0
    fi
    mkdir -p "$(dirname "$target")" || return 1
    ln -s "$source" "$target"
}

# link_one <相对目标> <相对源> <说明>
link_one() {
    local rel="$1" src_rel="$2" desc="$3"
    local target="$HOME/$rel"
    local source="$DOTFILES_DIR/$src_rel"
    local cur

    if [ ! -e "$source" ] && [ ! -L "$source" ]; then
        err "仓库里缺少源文件：$(tilde "$source")"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    # 1) 目标不存在 → 直接建链
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        if create_link "$target" "$source"; then
            if [ "$DRY_RUN" = true ]; then
                PLANNED=$((PLANNED + 1))
            else
                LINKED=$((LINKED + 1))
                info "新建：$(tilde "$target") → $(tilde "$source")"
            fi
        else
            err "创建软链失败：$target"
            SKIPPED=$((SKIPPED + 1))
        fi
        return 0
    fi

    # 2) 已是正确软链 → 跳过
    if [ -L "$target" ]; then
        cur="$(readlink "$target" 2>/dev/null || true)"
        if [ "$cur" = "$source" ]; then
            ok "已就位：$(tilde "$target")"
            return 0
        fi
    fi

    # 3) 需要改动 → 询问
    ACTION=""
    choose_action "$target" "$source" "$desc"

    case "$ACTION" in
        q)
            warn "按你的要求退出（已完成的改动保留）"
            summary
            exit 0
            ;;
        s)
            SKIPPED=$((SKIPPED + 1))
            note "跳过：$(tilde "$target")"
            return 0
            ;;
        dry)
            PLANNED=$((PLANNED + 1))
            note "[演练] 会备份并替换：$(tilde "$target")"
            return 0
            ;;
    esac

    # 目录替换多一道确认
    if [ -d "$target" ] && [ ! -L "$target" ] && [ "$ACTION" = "b" ]; then
        # 选了 [a]（之后全部备份替换）就不再逐项确认目录
        if can_prompt && [ "$ASSUME_YES" != true ] && [ -z "$ALWAYS_ACTION" ]; then
            if ! ask "  确认把整个目录移入备份并换成软链？[y/N]" n; then
                SKIPPED=$((SKIPPED + 1))
                note "跳过：$(tilde "$target")"
                return 0
            fi
        fi
    fi

    if [ "$ACTION" = "b" ]; then
        backup_existing "$target" || { SKIPPED=$((SKIPPED + 1)); return 0; }
    elif [ "$ACTION" = "o" ]; then
        if [ "$DRY_RUN" = true ]; then
            note "[演练] 直接覆盖 $(tilde "$target")（不备份）"
        else
            rm -rf -- "$target" || { err "无法删除：$target"; SKIPPED=$((SKIPPED + 1)); return 0; }
            warn "已直接覆盖（未备份）：$(tilde "$target")"
        fi
    fi

    if create_link "$target" "$source"; then
        UPDATED=$((UPDATED + 1))
        info "已替换：$(tilde "$target") → $(tilde "$source")"
    else
        err "创建软链失败：$target"
        SKIPPED=$((SKIPPED + 1))
    fi
}

# =============================================================================
# 受管路径
# =============================================================================
managed_links() {
    cat <<'EOF'
.zshrc|zsh/.zshrc|zsh 入口
.bashrc|bash/.bashrc|bash 交互配置
.bash_profile|bash/.bash_profile|bash 登录配置
.tmux.conf|tmux/.tmux.conf|tmux
.gitconfig|git/.gitconfig|git 全局配置
.gitignore_global|git/.gitignore_global|git 全局忽略
.wezterm.lua|wezterm/wezterm.lua|WezTerm 配置
.config/nvim|nvim|LazyVim 配置（目录）
EOF
}

# 该路径本次是否需要处理（--no-bash / --no-nvim）
wanted() {
    case "$1" in
        .bashrc|.bash_profile) [ "$WITH_BASH" = true ] ;;
        .config/nvim)          [ "$WITH_NVIM" = true ] ;;
        *)                     return 0 ;;
    esac
}

# =============================================================================
# --check 模式
# =============================================================================
check_links() {
    local rel src desc target source status bad=0
    head_ "软链检查"
    while IFS='|' read -r rel src desc; do
        [ -z "$rel" ] && continue
        wanted "$rel" || continue
        target="$HOME/$rel"
        source="$DOTFILES_DIR/$src"
        if [ -L "$target" ] && [ "$(readlink "$target" 2>/dev/null)" = "$source" ]; then
            printf '  %-24s ✅ 就位     %s\n' "$(tilde "$target")" "$desc"
        elif [ ! -e "$target" ] && [ ! -L "$target" ]; then
            printf '  %-24s ❌ 缺失     %s\n' "$(tilde "$target")" "$desc"
            bad=$((bad + 1))
        elif [ -L "$target" ]; then
            printf '  %-24s ⚠️  指向 %s\n' "$(tilde "$target")" "$(readlink "$target" 2>/dev/null)"
            bad=$((bad + 1))
        else
            printf '  %-24s ⚠️  普通文件/目录  %s\n' "$(tilde "$target")" "$desc"
            bad=$((bad + 1))
        fi
    done <<EOF
$(managed_links)
EOF

    for f in .zshrc.local .bashrc.local .gitconfig.local; do
        if [ -f "$HOME/$f" ]; then
            printf '  %-24s ✅ 就位\n' "$(tilde "$HOME/$f")"
        else
            printf '  %-24s ⚠️  缺失（运行 bootstrap.sh 自动创建）\n' "$(tilde "$HOME/$f")"
        fi
    done

    if [ "$bad" -eq 0 ]; then
        printf '\n'; ok "全部就位。"
        return 0
    fi
    printf '\n'
    warn "有 ${bad} 处未就位，运行：bash $(tilde "$DOTFILES_DIR/scripts/bootstrap.sh")"
    return 2
}

# =============================================================================
# 汇总
# =============================================================================
summary() {
    head_ "结果"
    printf '  新建软链 : %s\n' "$LINKED"
    printf '  替换     : %s\n' "$UPDATED"
    printf '  跳过     : %s\n' "$SKIPPED"
    if [ "$BACKED_UP" -gt 0 ]; then
        printf '  已备份   : %s 项 → %s\n' "$BACKED_UP" "$(tilde "$BACKUP_DIR")"
    fi
    if [ "$DRY_RUN" = true ]; then
        printf '  演练计划 : %s 项（未写入任何文件）\n' "$PLANNED"
    fi
    if [ "$BACKED_UP" -gt 0 ]; then
        printf '\n'
        note "恢复某一项：mv $(tilde "$BACKUP_DIR")/<相对路径> ~/<相对路径>"
    fi
}

# =============================================================================
# 预检
# =============================================================================
if [ ! -d "$DOTFILES_DIR" ]; then
    info "未找到 dotfiles 仓库（$DOTFILES_DIR），开始克隆..."
    if ! command -v git >/dev/null 2>&1; then
        err "需要 git 才能克隆仓库"; exit 1
    fi
    if [ "$DRY_RUN" = true ]; then
        note "[演练] git clone $REPO_URL $DOTFILES_DIR"
    else
        git clone "$REPO_URL" "$DOTFILES_DIR" || { err "克隆失败：$REPO_URL"; exit 1; }
    fi
fi

if [ ! -d "$DOTFILES_DIR/shared" ]; then
    err "仓库结构不完整（缺少 shared/）：$DOTFILES_DIR"
    exit 1
fi

if [ "$CHECK_ONLY" = true ]; then
    check_links
    exit $?
fi

BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

head_ "Dotfiles 部署"
printf '  系统     : %s\n' "$OS_NAME"
printf '  仓库     : %s\n' "$(tilde "$DOTFILES_DIR")"
if [ "$DRY_RUN" = true ]; then
    printf '  模式     : 演练（只打印，不写文件）\n'
elif [ "$ASSUME_YES" = true ]; then
    printf '  模式     : 无人值守（--yes，仍先备份）\n'
else
    printf '  模式     : 交互（改动已有配置前会询问）\n'
fi
printf '  备份目录 : %s\n' "$(tilde "$BACKUP_DIR")"

# =============================================================================
# 系统包
# =============================================================================
head_ "系统包"
if [ "$WITH_SUDO" != true ]; then
    note "跳过（未指定 --with-sudo）"
elif [ "$OS_NAME" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        if ask "未安装 Homebrew，是否安装？[Y/n]" y; then
            if [ "$DRY_RUN" = true ]; then
                note "[演练] 安装 Homebrew"
            else
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
                    || warn "Homebrew 安装失败，跳过 brew 包"
            fi
        else
            warn "跳过 Homebrew 安装"
        fi
    fi
    if command -v brew >/dev/null 2>&1; then
        if ask "用 brew bundle 安装 pkg/Brewfile 中的包？[Y/n]" y; then
            if [ "$DRY_RUN" = true ]; then
                note "[演练] brew bundle --file=$DOTFILES_DIR/pkg/Brewfile"
            else
                brew bundle --file="$DOTFILES_DIR/pkg/Brewfile" --no-lock \
                    || warn "brew bundle 有失败项（继续）"
            fi
        fi
    fi
elif [ -f /etc/debian_version ]; then
    if ask "使用 sudo 安装 pkg/apt-packages.txt 中的系统包？[Y/n]" y; then
        if [ "$DRY_RUN" = true ]; then
            note "[演练] sudo apt update && sudo apt install -y <pkg/apt-packages.txt>"
        elif sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
            sudo apt update
            packages="$(grep -v '^[[:space:]]*#' "$DOTFILES_DIR/pkg/apt-packages.txt" \
                       | grep -v '^[[:space:]]*$' | tr '\n' ' ')"
            if [ -n "$packages" ]; then
                # shellcheck disable=SC2086  # 这里必须有词分割
                sudo apt install -y $packages || warn "部分包安装失败（继续）"
            fi
        else
            warn "sudo 验证失败，跳过系统包"
        fi
    fi
else
    warn "未识别的 Linux 发行版；请手动安装 pkg/apt-packages.txt 中的包"
fi

# =============================================================================
# zsh / Oh My Zsh / 插件
# =============================================================================
head_ "zsh 环境"
if [ "$WITH_ZSH_SETUP" != true ]; then
    note "跳过（--no-zsh-setup）"
else
    if command -v zsh >/dev/null 2>&1; then
        ok "zsh：$(command -v zsh)（$(zsh --version 2>/dev/null | head -1)）"
    else
        warn "未找到 zsh。交互 shell 依赖它：Debian/Ubuntu 用 sudo apt install zsh，macOS 用 brew install zsh"
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        if ask "安装 Oh My Zsh？[Y/n]" y; then
            if [ "$DRY_RUN" = true ]; then
                note "[演练] 安装 Oh My Zsh"
            else
                RUNZSH=no KEEP_ZSHRC=yes \
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
                    || warn "Oh My Zsh 安装失败（继续）"
            fi
        fi
    else
        ok "Oh My Zsh 已存在"
    fi

    if [ -d "$HOME/.oh-my-zsh" ]; then
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        for spec in \
            "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions" \
            "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"; do
            plugin="${spec%% *}"; repo="${spec#* }"
            if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
                ok "插件已存在：$plugin"
            elif [ "$DRY_RUN" = true ]; then
                note "[演练] git clone $repo → $ZSH_CUSTOM/plugins/$plugin"
            else
                info "安装插件：$plugin"
                mkdir -p "$ZSH_CUSTOM/plugins"
                if git clone --depth 1 "$repo" "$ZSH_CUSTOM/plugins/$plugin" >/dev/null 2>&1; then
                    ok "已安装：$plugin"
                else
                    warn "插件安装失败：$plugin"
                fi
            fi
        done
        unset plugin repo spec
    fi
fi

# =============================================================================
# 软链
# =============================================================================
head_ "软链配置"
while IFS='|' read -r rel src desc; do
    [ -z "$rel" ] && continue
    wanted "$rel" || continue
    link_one "$rel" "$src" "$desc"
done <<EOF
$(managed_links)
EOF

# =============================================================================
# 机器本地覆盖文件（只补缺失，不覆盖）
# =============================================================================
head_ "机器本地覆盖"
create_local() {
    local file="$1" template="$2"
    if [ -f "$file" ]; then
        ok "已存在：$(tilde "$file")"
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        note "[演练] 创建 $(tilde "$file")"
        return 0
    fi
    printf '%s\n' "$template" > "$file"
    ok "已创建：$(tilde "$file")"
}
create_local "$HOME/.zshrc.local" "# 本机专属 zsh 配置（不进仓库）
# - CUDA / SDK 的 PATH、*_HOME
# - ulimit、host 专属 alias、第三方安装器追加的 PATH"
if [ "$WITH_BASH" = true ]; then
    create_local "$HOME/.bashrc.local" "# 本机专属 bash 配置（不进仓库）
# - 第三方安装器追加的 PATH、host 专属 alias"
fi
create_local "$HOME/.gitconfig.local" "# 本机专属 git 配置（不进仓库）
# - credential helper、签名密钥、代理、per-host 身份"

# =============================================================================
# 登录 shell
# =============================================================================
if [ "$OFFER_CHSH" = true ] && command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    if [ "${SHELL:-}" != "$zsh_path" ]; then
        head_ "登录 shell"
        note "当前登录 shell：${SHELL:-未知}；建议切换为：$zsh_path"
        if ask "现在切换登录 shell（chsh，需要输入密码）？[y/N]" n; then
            if [ "$DRY_RUN" = true ]; then
                note "[演练] chsh -s $zsh_path"
            elif [ "$ASSUME_YES" = true ] || ! can_prompt; then
                note "非交互模式不执行 chsh；请手动运行：chsh -s $zsh_path"
            else
                chsh -s "$zsh_path" || warn "chsh 失败（可手动执行：chsh -s $zsh_path）"
            fi
        else
            note "稍后可手动执行：chsh -s $zsh_path"
        fi
    fi
fi

# =============================================================================
# 收尾
# =============================================================================
summary
printf '\n'
info "下一步："
note "exec zsh"
note "nvim                              # 首次运行自动安装 LazyVim 插件"
note "bash $(tilde "$DOTFILES_DIR/scripts/bootstrap.sh") --check   # 随时检查软链状态"
exit 0
