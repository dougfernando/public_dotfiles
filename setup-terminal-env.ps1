<#
.SYNOPSIS
    Sets up terminal environment with yazi, zoxide, eza, btop, and other tools.
    Optionally installs Neovim. Syncs configs from a GitHub dotfiles repo.

.DESCRIPTION
    Interactive setup:
    1. Asks for GitHub dotfiles repo URL
    2. Asks whether to install Neovim (optional)
    3. Installs tools: yazi, zoxide, eza, btop, ripgrep, fd, fzf, etc. (via winget)
    4. Downloads dotfiles from GitHub (no git required — uses GitHub API + Invoke-WebRequest)
    5. Copies configs to correct locations (~/.config, $PROFILE, etc.)
    6. Sets up PowerShell profile if needed

.PARAMETER DotfilesDir
    Where to clone dotfiles repo (default: ~/dotfiles)

.PARAMETER Force
    Force reinstall tools and re-sync configs (skip existing check)

.EXAMPLE
    # Download and run in one command:
    iwr -Uri "https://raw.githubusercontent.com/USERNAME/dotfiles/main/setup-terminal-env.ps1" -OutFile "$env:TEMP\setup.ps1"; & "$env:TEMP\setup.ps1"

    # Or run locally with optional force:
    .\setup-terminal-env.ps1 -Force
#>

param(
    [string]$DotfilesDir = "$env:USERPROFILE\dotfiles",
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# CONFIGURATION
# ============================================================================

$TOOLS = @(
@{id = "sxyazi.yazi";                  name = "Yazi (file browser)" }
    @{id = "ajeetdsouza.zoxide";           name = "Zoxide (cd shortcut)" }
    @{id = "eza-community.eza";            name = "Eza (ls replacement)" }
    @{id = "Eugeny.Tabby";                 name = "Tabby (optional terminal)" }
    @{id = "BurntSushi.ripgrep.msvc";      name = "Ripgrep (grep replacement)" }
    @{id = "sharkdp.fd";                   name = "fd (find replacement)" }
    @{id = "BurntSushi.xsv";               name = "xsv (CSV tool)" }
    @{id = "junegunn.fzf";                 name = "fzf (fuzzy finder)" }
    @{id = "aristocratos.btop";            name = "btop (system monitor)" }
)

# Optional tools (conditionally added based on user choice)
$NEOVIM_TOOL = @{id = "neovim.neovim"; name = "Neovim" }

# Mapping of tool → config source in dotfiles repo
$CONFIG_MAP = @{
    # Source folder in repo → Destination directory (or file for powershell)
    "nvim"       = "$env:LOCALAPPDATA\nvim"
"yazi"       = "$env:APPDATA\yazi\config"
    "powershell" = $PROFILE
}

# ============================================================================
# HELPERS
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n▶ $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    $?
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Success "Created directory: $Path"
    }
}

function Refresh-Path {
    # Reload PATH from registry (used after winget installs new tools)
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + `
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ============================================================================
# MAIN
# ============================================================================

Write-Host "
╔══════════════════════════════════════════════════════════════╗
║    Terminal Environment Setup (Windows)                      ║
║    Installing: yazi, zoxide, eza, btop, fzf, etc.          ║
╚══════════════════════════════════════════════════════════════╝
" -ForegroundColor Magenta

# Soft admin check — warn but continue
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠ Not running as admin — some installs may fail. Re-run as admin if issues occur." -ForegroundColor Yellow
}

# ============================================================================
# STEP 0: Ask for GitHub repo and optional tools
# ============================================================================

Write-Step "GitHub Dotfiles Repo"
$GitHubRepo = Read-Host "Enter GitHub repo URL (e.g., https://github.com/username/dotfiles)"
if (-not $GitHubRepo) {
    Write-Error "GitHub repo URL required. Exiting."
    exit 1
}
Write-Success "Using repo: $GitHubRepo"

# ============================================================================
# Ask about optional tools
# ============================================================================

Write-Step "Optional: Install Neovim?"
Write-Host "  Neovim is a code editor. Install it?" -ForegroundColor Gray
$response = Read-Host "  [Y]es / [N]o (default: N)"

if ($response -eq "Y" -or $response -eq "y") {
    $TOOLS += $NEOVIM_TOOL
    Write-Success "Neovim will be installed"
} else {
    Write-Host "  Skipping Neovim installation" -ForegroundColor Gray
}

# ============================================================================
# STEP 1: Update winget
# ============================================================================

Write-Step "Updating winget"
try {
    winget upgrade --all --silent --accept-source-agreements 2>$null
    Write-Success "Winget updated"
} catch {
    Write-Host "  Failed to update winget (non-critical, continuing)" -ForegroundColor Yellow
}

# ============================================================================
# STEP 2: Download dotfiles from GitHub (no git required)
# ============================================================================

Write-Step "Downloading dotfiles from GitHub"

# Parse owner/repo from URL (supports https://github.com/owner/repo and https://github.com/owner/repo.git)
$repoPath = $GitHubRepo -replace "^https://github\.com/", "" -replace "\.git$", ""
if ($repoPath -notmatch "^[^/]+/[^/]+$") {
    Write-Host "✗ Could not parse repo path from URL: $GitHubRepo" -ForegroundColor Red
    exit 1
}

Write-Host "  Fetching file list from GitHub API..." -NoNewline
try {
    $apiUrl = "https://api.github.com/repos/$repoPath/git/trees/HEAD?recursive=1"
    $tree = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "setup-terminal-env" } -ErrorAction Stop
    Write-Host " ✓" -ForegroundColor Green
} catch {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "  Failed to fetch repo file tree. Check the URL and your internet connection." -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$configFiles = $tree.tree | Where-Object { $_.type -eq "blob" -and $_.path -like "configs/*" }

if ($configFiles.Count -eq 0) {
    Write-Host "  ⚠ No files found under configs/ in repo. Check your repo structure." -ForegroundColor Yellow
} else {
    Write-Host "  Downloading $($configFiles.Count) config files..."
    $downloadErrors = 0

    foreach ($file in $configFiles) {
        $rawUrl = "https://raw.githubusercontent.com/$repoPath/HEAD/$($file.path)"
        $localPath = Join-Path $DotfilesDir ($file.path -replace "/", "\")
        $localDir  = Split-Path $localPath

        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }

        try {
            Invoke-WebRequest -Uri $rawUrl -OutFile $localPath -ErrorAction Stop
        } catch {
            Write-Host "  ⚠ Failed to download: $($file.path)" -ForegroundColor Yellow
            $downloadErrors++
        }
    }

    if ($downloadErrors -eq 0) {
        Write-Success "All config files downloaded to: $DotfilesDir"
    } else {
        Write-Host "  ⚠ $downloadErrors file(s) failed to download — check warnings above." -ForegroundColor Yellow
    }
}

# ============================================================================
# STEP 3: Install remaining tools via winget
# ============================================================================

Write-Step "Installing tools via winget"

foreach ($tool in $TOOLS) {
    $id = $tool.id
    $name = $tool.name

    if (Test-CommandExists ($name.Split()[0].ToLower()) -and -not $Force) {
        Write-Success "Already installed: $name"
        continue
    }

    Write-Host "  Installing $name..." -NoNewline
    $result = & winget install --id $id --scope user --silent --accept-source-agreements --accept-package-agreements 2>&1

    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335135) {  # 0 = success, -1978... = already installed
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ⚠" -ForegroundColor Yellow
    }
}

Write-Success "Tool installation complete"

# ============================================================================
# STEP 4: Copy configs
# ============================================================================

Write-Step "Syncing configs"

$ConfigSource = $DotfilesDir

if (-not (Test-Path $ConfigSource)) {
    Write-Error "Config directory not found. Expected: $ConfigSource"
    exit 1
}

# Copy each config
foreach ($configName in $CONFIG_MAP.Keys) {
    $srcPath = "$ConfigSource\$configName"
    $destPath = $CONFIG_MAP[$configName]

    if (-not (Test-Path $srcPath)) {
        Write-Host "  ⊘ Skipping $configName (not in repo)" -ForegroundColor Gray
        continue
    }

    Ensure-Directory (Split-Path $destPath)

    Write-Host "  Copying $configName..." -NoNewline

    # Backup existing config
    if (Test-Path $destPath) {
        $backupPath = "$destPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $destPath -Destination $backupPath -Recurse -Force | Out-Null
        Write-Host " (backed up to .backup)" -ForegroundColor Gray -NoNewline
    }

    Copy-Item -Path $srcPath -Destination $destPath -Recurse -Force
    Write-Host " ✓" -ForegroundColor Green
}

# ============================================================================
# STEP 5: Set up PowerShell profile
# ============================================================================

Write-Step "Setting up PowerShell profile"

$psProfileSource = "$ConfigSource\powershell\profile.ps1"

if (Test-Path $psProfileSource) {
    Ensure-Directory (Split-Path $PROFILE)

    Write-Host "  Checking if profile needs update..." -NoNewline

    if (Test-Path $PROFILE) {
        $backup = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $PROFILE -Destination $backup -Force | Out-Null
        Write-Host " (backed up)" -ForegroundColor Gray -NoNewline
    }

    Copy-Item -Path $psProfileSource -Destination $PROFILE -Force
    Write-Host " ✓" -ForegroundColor Green
    Write-Success "PowerShell profile installed. Run: . `$PROFILE to reload"
} else {
    Write-Host "  ⚠ powershell/profile.ps1 not found in repo (optional)" -ForegroundColor Gray
}

# ============================================================================
# STEP 6: Verify installations
# ============================================================================

Write-Step "Verifying installations"

$verifyCommands = @(
    "yazi", "zoxide", "eza", "btop", "rg", "fd", "fzf"
)

# Add nvim to verify list only if it was installed
$neovimInstalled = $TOOLS | Where-Object { $_.id -eq "neovim.neovim" }
if ($neovimInstalled) {
    $verifyCommands = @("nvim") + $verifyCommands
}

$allOk = $true
foreach ($cmd in $verifyCommands) {
    if (Test-CommandExists $cmd) {
        $ver = & $cmd --version 2>$null | Select-Object -First 1
        Write-Success "$cmd : $(($ver -split '\n')[0])"
    } else {
        Write-Error "$cmd : NOT FOUND"
        $allOk = $false
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
if ($allOk) {
    Write-Host "║  ✓ Setup complete! Your terminal is ready to go.           ║" -ForegroundColor Green
} else {
    Write-Host "║  ⚠ Setup mostly complete. Check errors above.              ║" -ForegroundColor Yellow
}
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Reload PowerShell: . `$PROFILE"
Write-Host "  2. Check configs: ls $DotfilesDir"
Write-Host "  3. Customize as needed in: $DotfilesDir"
Write-Host "`nBackups created at: [config-path].backup.YYYYMMDD-HHMMSS`n"
