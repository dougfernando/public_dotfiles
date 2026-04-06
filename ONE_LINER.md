# One-Liner Setup

Run this in Windows Terminal (PowerShell 7+) on any new machine:

```powershell
iex (iwr "https://raw.githubusercontent.com/dougfernando/public_dotfiles/master/setup-terminal-env.ps1").Content
```

If you hit an execution policy error, prepend:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

## What happens

1. Downloads `setup-terminal-env.ps1` from your repo
2. Prompts for your GitHub repo URL and whether to install Neovim
3. Downloads all configs via GitHub API (no git required)
4. Installs tools via winget: yazi, zoxide, eza, btop, ripgrep, fd, fzf, xsv
5. Deploys configs to their correct Windows locations
6. Verifies all installations

## Force reinstall

```powershell
iex (iwr "https://raw.githubusercontent.com/dougfernando/public_dotfiles/master/setup-terminal-env.ps1").Content
```

To pass `-Force`, save to a temp file first:
```powershell
iwr "https://raw.githubusercontent.com/dougfernando/public_dotfiles/master/setup-terminal-env.ps1" -OutFile "$env:TEMP\setup.ps1"; & "$env:TEMP\setup.ps1" -Force
```

## After setup

```powershell
. $PROFILE   # Reload PowerShell profile
```
