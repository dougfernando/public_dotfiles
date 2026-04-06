# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terminal setup automation for Windows. Single-script system:

- **Deploy** (`setup-terminal-env.ps1`): Downloads configs from GitHub + installs tools on new machines. No git required — uses GitHub API and `Invoke-WebRequest`.
- **Config files** (`config_files/`): The actual dotfiles, organized by tool at the root level. This directory is meant to be pushed as its own GitHub repo.

Workflow: Edit configs in `config_files/` → upload to GitHub → run `setup-terminal-env.ps1` on new machines.

## Common Commands

### Deploy on a new machine

```powershell
# Interactive: prompts for GitHub repo URL and optional Neovim install
.\setup-terminal-env.ps1

# Custom dotfiles download location
.\setup-terminal-env.ps1 -DotfilesDir "C:\custom\path\dotfiles"

# Force reinstall everything (bypass "already installed" checks)
.\setup-terminal-env.ps1 -Force
```

### One-liner for fresh machines

```powershell
iex (iwr "https://raw.githubusercontent.com/dougfernando/public_dotfiles/master/setup-terminal-env.ps1").Content
```

### Validate PowerShell profile loads correctly

```powershell
& { . $PROFILE } 2>&1  # Shows syntax errors if any
Test-Path $PROFILE      # Verify file exists
```

## Architecture

### Single-Script Design

**`setup-terminal-env.ps1`**
- Runs on fresh/new machines (admin optional; some installs may fail without it)
- Asks for GitHub repo URL and whether to install Neovim
- Downloads all files from the repo using GitHub API + `Invoke-WebRequest` (no git needed)
- Installs tools via winget: yazi, zoxide, eza, ripgrep, fd, fzf, btop, xsv, Tabby, optionally Neovim
- Maps downloaded configs → Windows standard locations (via `$CONFIG_MAP`)
- Backs up existing configs as `.backup.YYYYMMDD-HHMMSS` before overwriting
- Verifies all tools post-install

### Config Flow

```
config_files/ (this repo)
    nvim/, yazi/, powershell/
        ↓ (upload to GitHub)
GitHub repo
        ↓ (GitHub API + iwr download)
setup-terminal-env.ps1
        ↓
Local Windows paths on new machine
```

### Configuration Mapping (`$CONFIG_MAP`)

Defined in `setup-terminal-env.ps1`:

```powershell
$CONFIG_MAP = @{
    "nvim"       = "$env:LOCALAPPDATA\nvim"
    "wezterm"    = "$env:USERPROFILE\.config\wezterm"
    "yazi"       = "$env:APPDATA\yazi\config"
    "powershell" = $PROFILE
}
```

To add a new tool:
1. Add folder to `config_files/` (e.g., `config_files/helix/`)
2. Add entry to `$CONFIG_MAP` in `setup-terminal-env.ps1`
3. Script will auto-download and deploy on next run

### Tool Installation List

Installed via winget (defined in `$TOOLS` array in `setup-terminal-env.ps1`):
- **Yazi/Eza**: File browser & ls replacement
- **Zoxide**: Smart cd with history
- **Ripgrep/fd/fzf**: Search & fuzzy finding
- **btop**: System monitor
- **xsv**: CSV CLI tool
- **Tabby**: Optional terminal
- **Neovim**: Optional code editor (user prompted)

### Error Handling & Backups

- All existing configs backed up before overwrite (suffix: `.backup.YYYYMMDD-HHMMSS`)
- Scripts continue on non-critical failures (e.g., tool already installed)
- Winget exit codes: `0` = success, `-1978335135` = already installed (non-fatal)
- Per-file download failures are counted and reported but don't abort the run

### Key Parameters

**setup-terminal-env.ps1:**
- `-DotfilesDir`: Where to download configs (default: `~/dotfiles`)
- `-Force`: Skip "already installed" checks; force reinstall everything

## Dependencies

- **PowerShell 7+** (Core, not Windows PowerShell 5.1)
- **Winget** (Windows Package Manager; available on Windows 11)
- **Internet access** to reach GitHub API and raw.githubusercontent.com

## Important Notes

- Windows Terminal is the assumed terminal emulator
- Config folder names in the repo must match keys in `$CONFIG_MAP` exactly
- PowerShell profile is sourced from `powershell/profile.ps1` in repo
- Scripts emit a soft admin warning but continue if not running as admin
- Scripts support execution policy bypass: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`
