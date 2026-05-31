# =============================================================================
# Windows PowerShell Bootstrap Script
# Usage: powershell -ExecutionPolicy Bypass -File bootstrap.ps1
# This sets up the PowerShell profile and optionally WSL2 dotfiles
# =============================================================================

param(
    [switch]$SkipWSL,
    [switch]$SkipWinget,
    [switch]$SkipProfile
)

$ErrorActionPreference = "Stop"
$DotfilesPath = "$env:USERPROFILE\.dotfiles"

function Write-Info  { Write-Host "[INFO]  $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[WARN]  $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

# ---------- Step 1: Install winget packages ----------
if (-not $SkipWinget) {
    Write-Info "Installing Windows packages via winget..."

    $packages = @(
        "Microsoft.PowerShell",
        "Git.Git",
        "GitHub.cli",
        "Neovim.Neovim",
        "Microsoft.WindowsTerminal",
        "JanDeDobbeleer.OhMyPosh",
        "eza-community.eza",
        "sharkdp.fd",
        "BurntSushi.ripgrep.MSVC",
        "junegunn.fzf",
        "ajeetdsouza.zoxide",
        "JetBrains.Mono",
        "OpenJS.NodeJS",
        "Python.Python.3.12"
    )

    foreach ($pkg in $packages) {
        Write-Info "  Installing: $pkg"
        winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements
    }
}

# ---------- Step 2: Symlink PowerShell profile ----------
if (-not $SkipProfile) {
    Write-Info "Setting up PowerShell profile..."

    $ProfileDir = Split-Path $PROFILE -Parent
    $ProfileFile = $PROFILE

    if (!(Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }

    # Backup existing profile
    if (Test-Path $ProfileFile) {
        $backup = "$ProfileFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $ProfileFile $backup
        Write-Info "Backed up existing profile to: $backup"
    }

    # Create symlink (requires admin, or use Copy-Item as fallback)
    try {
        New-Item -ItemType SymbolicLink -Path $ProfileFile -Target "$DotfilesPath\powershell\Microsoft.PowerShell_profile.ps1" -Force
        Write-Info "Symlinked PowerShell profile."
    } catch {
        Write-Warn "Cannot create symlink (may need admin). Copying instead..."
        Copy-Item "$DotfilesPath\powershell\Microsoft.PowerShell_profile.ps1" $ProfileFile -Force
        Write-Info "Copied PowerShell profile."
    }
}

# ---------- Step 3: WSL2 setup ----------
if (-not $SkipWSL) {
    Write-Info "Checking WSL2..."
    $wslStatus = wsl --status 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Info "WSL2 is installed. Running Linux bootstrap inside WSL..."
        wsl bash -c "bash ~/.dotfiles/scripts/bootstrap.sh"
    } else {
        Write-Warn "WSL2 not installed. Skipping WSL bootstrap."
        Write-Warn "To install WSL2: wsl --install"
    }
}

# ---------- Step 4: Install Oh My Posh theme (optional) ----------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Info "Oh My Posh installed. Run 'oh-my-posh init pwsh | Invoke-Expression' in your profile."
}

# ---------- Done ----------
Write-Info ""
Write-Info "  Bootstrap complete for Windows!"
Write-Info "  Restart PowerShell or run: . `$PROFILE"
Write-Info ""
Write-Info "  Manual steps:"
Write-Info "    1. Install JetBrains Mono Nerd Font from: https://www.nerdfonts.com/"
Write-Info "    2. Set Windows Terminal font to 'JetBrainsMono Nerd Font'"
Write-Info "    3. Run 'nvim' to let LazyVim install plugins (if you use WSL nvim)"
