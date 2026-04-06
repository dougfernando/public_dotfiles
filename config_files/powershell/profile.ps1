# oh-my-posh init pwsh --config "~\OneDrive - Accenture\Documents\PowerShell\myposh.omp.json" | Invoke-Expression

function prompt {
    $timeColor = "`e[38;5;245m"  # Grey
    $userColor = "`e[38;5;135m"  # Purple
    $hostColor = "`e[0m@"
    $pathColor = "`e[38;5;46m"   # Green
    $reset = "`e[0m"

    # Time, User and path
    $timeDisplay = "$timeColor[" + (Get-Date -Format "HH:mm") + "]$reset"
    $userDisplay = "$userColor" + "douglas" + "$reset"
    $pathDisplay = "$pathColor$(Get-Location)$reset"

    # Lambda symbol prompt
    $lambdaSymbol = "`e[38;5;208mλ$reset"

    "$timeDisplay $userDisplay $hostColor $pathDisplay `n$lambdaSymbol "
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

$ENV:EDITOR = "nvim"
$ENV:VISUAL = "nvim-qt"
$ENV:LANG = "pt_br.utf-8"
$ENV:XDG_DATA_HOME = "C:\Users\douglas.f.silva\AppData\Local"

set-alias grep rg 
set-alias vi nvim
set-alias vim nvim
set-alias edit nvim
set-alias grep select-string
set-alias cat bat
Set-Alias reload Reload-Powershell
Set-Alias top btop
Set-Alias l ls

${function:~} = { Set-Location ~ }

function winget-list {
    winget list --upgrade-available --source=winget
}

# Import-Module ~\scripts\list-calendar-events.ps1

function which ($command) { 
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue 
}

function touch ($file) {
    New-Item -Path $file -ItemType File -Force
}

function new-symlink($source, $destiny) {
    New-Item -ItemType SymbolicLink -Path $destiny -Target $source
}

function notes {
    cd '~\OneDrive - Accenture\Notebooks\Accenture\'
}

Import-Module ~\scripts\my_ps1_functions.ps1

function claude-yolo { claude --dangerously-skip-permissions --allowedTools "*" @args }

function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}


function cal {
    rusti-cal --color | bat
}

function tail {
  param($Path, $n = 20, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
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

Import-Module -Name Microsoft.WinGet.CommandNotFound
Invoke-Expression (& { (zoxide init powershell | Out-String) })
