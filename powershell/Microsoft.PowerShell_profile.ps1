# =============================================================================
# Cross-platform PowerShell Profile
# Works on: Windows PowerShell 5.1+ | PowerShell Core 7+ (Windows/macOS/Linux)
# Install: Copy to $PROFILE (or symlink)
# =============================================================================

# ---------- Aliases (Unix-like) ----------
function which { Get-Command $args[0] }
function grep  { Select-String $args }
function touch { New-Item -ItemType File -Path $args[0] -Force }
function df    { Get-PSDrive }
function du    { Get-ChildItem -Recurse | Measure-Object -Property Length -Sum }
function sed   { (Get-Content $args[0]) -replace $args[1], $args[2] | Set-Content $args[0] }

# ---------- Navigation (Unix-like cd shortcuts) ----------
function ..   { Set-Location .. }
function ...  { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# ---------- Git shortcuts ----------
function g    { git $args }
function gs   { git status }
function ga   { git add $args }
function gc   { git commit -m $args[0] }
function gp   { git push }
function gl   { git log --oneline --graph --decorate -20 }
function gd   { git diff }
function gco  { git checkout $args }
function gb   { git branch }

# ---------- Editor ----------
$env:EDITOR = "nvim"
$env:VISUAL = "nvim"

# ---------- Modern CLI replacements ----------
function ls {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        eza $args
    } else {
        Get-ChildItem $args
    }
}

# ---------- fzf integration ----------
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ---------- Terminal aesthetics ----------
# Use Nerd Font for icons (install JetBrains Mono Nerd Font first)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
}

# ---------- WSL integration (optional) ----------
function wslbash { wsl bash -c $args }
function wslzsh  { wsl zsh  -c $args }

# ---------- Starship prompt (if oh-my-posh not installed) ----------
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Invoke-Expression (&starship init powershell)
    }
}

# ---------- Cross-platform clipboard ----------
function clip {
    param([string]$text)
    if ($text) {
        $text | Set-Clipboard
    } else {
        $input | Set-Clipboard
    }
}
