# Dotfiles Repo Structure

How `config_files/` is organized and how it maps to Windows paths.

## Layout

```
config_files/
├── nvim/
│   ├── init.vim
│   ├── ginit.vim
│   └── autoload/
│       └── plug.vim
├── yazi/
│   ├── yazi.toml
│   ├── keymap.toml
│   └── theme.toml
└── powershell/
    └── profile.ps1
```

## What Gets Deployed Where

| Repo folder | Windows destination |
|-------------|-------------------|
| `nvim/` | `%LOCALAPPDATA%\nvim` |
| `yazi/` | `%APPDATA%\yazi\config` |
| `powershell/profile.ps1` | `$PROFILE` |

## Adding a New Tool

1. Create a folder in `config_files/` matching the tool name (e.g., `config_files/helix/`)
2. Add the config files inside it
3. Add an entry to `$CONFIG_MAP` in `setup-terminal-env.ps1`:
   ```powershell
   "helix" = "$env:APPDATA\helix"
   ```
4. Upload to GitHub — the setup script will pick it up automatically on next run

## Troubleshooting

**Configs not copied**
- Folder name in repo must exactly match the key in `$CONFIG_MAP`
- Verify the destination path is correct for your Windows version

**PowerShell profile not loading**
- Run `. $PROFILE` after setup to reload
- Check for syntax errors: `& { . $PROFILE } 2>&1`
