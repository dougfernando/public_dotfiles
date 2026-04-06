# Terminal Environment Setup Guide

## Quick Start

### On a New Machine

1. Open Windows Terminal (PowerShell 7+)

2. Run the one-liner:
   ```powershell
   iwr -Uri "https://raw.githubusercontent.com/dougfernando/public_dotfiles/master/setup-terminal-env.ps1" -OutFile "$env:TEMP\setup.ps1"; & "$env:TEMP\setup.ps1"
   ```

3. When prompted, enter your GitHub repo URL and choose whether to install Neovim

4. Reload your profile:
   ```powershell
   . $PROFILE
   ```

---

## What Gets Installed

| Tool | Purpose |
|------|---------|
| **Yazi** | Fast TUI file browser |
| **Eza** | Modern `ls` replacement |
| **Zoxide** | Smart `cd` with memory |
| **btop** | System monitor |
| **Ripgrep** | Fast grep replacement |
| **fd** | Fast find replacement |
| **fzf** | Fuzzy finder |
| **xsv** | CSV CLI tool |
| **Tabby** | Optional terminal |
| **Neovim** | Optional editor (prompted) |

---

## Script Details

### `setup-terminal-env.ps1`

Downloads configs and installs tools. No git required.

**Parameters:**
- `-DotfilesDir` — where to download configs (default: `~/dotfiles`)
- `-Force` — skip "already installed" checks; reinstall everything

**Steps:**
1. Updates winget
2. Downloads all config files from your GitHub repo via API
3. Installs tools via winget
4. Copies configs to correct Windows locations
5. Sets up PowerShell profile
6. Verifies all installations

Existing configs are backed up as `.backup.YYYYMMDD-HHMMSS` before overwriting.

---

## Customizing

### Add or remove tools

Edit the `$TOOLS` array in `setup-terminal-env.ps1`:

```powershell
$TOOLS = @(
    @{id = "MyCompany.MyTool"; name = "My Tool" }
    # ...
)
```

Find winget IDs at https://winget.run/

### Add or remove configs

1. Add/remove the folder in `config_files/`
2. Update `$CONFIG_MAP` in `setup-terminal-env.ps1`:
   ```powershell
   $CONFIG_MAP = @{
       "nvim"       = "$env:LOCALAPPDATA\nvim"
       "yazi"       = "$env:APPDATA\yazi\config"
       "powershell" = $PROFILE
   }
   ```

---

## Troubleshooting

**Execution policy error**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

**Tools not installing**
```powershell
winget list          # Check winget works
winget search yazi   # Find correct package ID
```

**PowerShell profile not loading**
```powershell
Test-Path $PROFILE         # Check file exists
& { . $PROFILE } 2>&1     # Check for syntax errors
. $PROFILE                 # Reload manually
```

**Config not deployed**
- Folder name in repo must exactly match the key in `$CONFIG_MAP`
- Run with `-Force` to overwrite: `.\setup-terminal-env.ps1 -Force`

---

## Directory Reference

| Tool | Windows path |
|------|-------------|
| Neovim | `%LOCALAPPDATA%\nvim` |
| Yazi config | `%APPDATA%\yazi\config` |
| PowerShell profile | `$PROFILE` |
