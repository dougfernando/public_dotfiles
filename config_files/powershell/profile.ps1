

$ENV:EDITOR = "nvim"
$ENV:VISUAL = "nvim-qt"
$ENV:LANG = "pt_br.utf-8"

set-alias l ls
set-alias grep select-string
set-alias vi nvim
set-alias vim nvim
set-alias edit nvim
set-alias grep select-string
set-alias cat bat -Option AllScope
Set-Alias reload Reload-Powershell
${function:~} = { Set-Location ~ }

function winget-list {
    winget list --upgrade-available --source=winget
}

function which ($command) { 
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue 
}

function external-display-only {
    DisplaySwitch.exe /external
}

function extend-notebook-display {
    DisplaySwitch.exe /extend
}

function test-sound {
    [System.Media.SystemSounds]::Beep.Play()
}

function mode-high-performance {
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
}

function mode-power-saver {
    powercfg -setactive a1841308-3541-4fab-bc81-f71556f20b4a
}

function mode-balanced {
    powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
}

# function FZE { fzf | % { nvim $_ }   }
function FZE { 
    fzf | % { 
        switch -regex ($_) {
            '\.md$' { nvim $_ }  # Open Markdown files with Neovim
                '\.txt$' { nvim $_ }  # Open text files with Notepad
                '\.pdf$' { Start-Process $_ }  # Open PDF files with default program 
                '\.jpg$|\.png$' { Start-Process mspaint $_ }  # Open images with MS Paint
                default { Start-Process $_ }  # Default to Neovim for any other file types
        }
    }   
}

function FZV {
    fzf --preview 'bat  --color=always {}'
}



Set-Location ~
