
# --- oh-my-posh transient prompt setup (must be first) ---
$global:_ompTransientPrompt = $true
$env:PATH += ":$HOME/.local/bin"
oh-my-posh init pwsh --config "$HOME/git/dotfiles/.night-owl02.json" | Invoke-Expression
# --- end oh-my-posh transient prompt setup ---

# Development Tools
Set-Alias -Name k -Value kubectl -Option AllScope
Set-Alias -Name mfa -Value .\powershell\aws\aws-mfa.ps1 -Option AllScope
Set-Alias -Name dn -Value daily-note -Option AllScope
Set-Alias -Name gd -Value git-daily -Option AllScope
Set-Alias -Name tf -Value tofu -Option AllScope
Set-Alias -Name py -Value python -Option AllScope

# Daily note function
function daily-note {
    $dir = "C:\Users\wweeks\workspace\planner"
    $filename = (Get-Date).ToString("MM-dd") + ".md"
    $path = Join-Path -Path $dir -ChildPath $filename
    $tasksListPath = "C:\Users\wweeks\workspace\planner\tasks-list.txt"

    if (!(Test-Path -Path $path) -or (Get-Content $path -ErrorAction SilentlyContinue).Count -eq 0) {
        $tasksList = if (Test-Path $tasksListPath) {
            Get-Content $tasksListPath | Where-Object { $_.Trim() -ne "" }
        }
        else {
            @(
                "- [ ] 32032 - AWS Lambda end of support for Python 3.9"
            )
        }
        $tasksSection = $tasksList -join "`n"
        $content = @"
$(Get-Date)

$tasksSection
"@
        Set-Content -Path $path -Value $content
    }
    Invoke-Item $path
}

# aws-mfa function
function aws-mfa {
    param (
        [Parameter(Mandatory = $false)]
        [string]$token
    )
    & ~/workspace/powershell/aws/aws-mfa.ps1 -token $token
}

# Git log functions
function log {
    git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all -n 20
}


# Approved verb: Show
function Show-GitLogAll {
    git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all
}

# Update alias for convenience
Set-Alias -Name log-all -Value Show-GitLogAll -Option AllScope

# git-daily function
function git-daily {
    git add -A

    $status = git status --short
    if (-not $status) {
        Write-Host "Nothing to commit." -ForegroundColor Yellow
        return
    }

    Write-Host "Changes staged:" -ForegroundColor Cyan
    git status --short
    Write-Host ""

    $prompt = @'
Inspect the staged git changes in the current repository and output only one concise commit message, no quotes, no markdown. Use git diff --cached if needed.
'@
    $commitMsg = (& copilot -p $prompt --silent --allow-tool 'shell(git:*)' --allow-all-paths --no-color | Out-String).Trim()
    $commitMsg = ($commitMsg -split "`r?`n")[0].Trim().Trim('"')

    if (-not $commitMsg) {
        throw "Copilot did not return a commit message."
    }

    Write-Host "Suggested commit message:" -ForegroundColor Cyan
    Write-Host "  $commitMsg" -ForegroundColor White
    Write-Host ""

    git commit --message $commitMsg
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed."
    }

    git push
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed."
    }
    Write-Host "Pushed successfully." -ForegroundColor Green
}



# winget argument completer
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}


# Alias to edit this profile
Set-Alias editprofile "code /home/acestus/git/dotfiles/Microsoft.PowerShell_profile.ps1"
# Alias to edit bashrc
Set-Alias editbashrc "code /home/acestus/git/dotfiles/bashrc"
# Alias to edit VS Code settings
Set-Alias editvscodesettings "code /home/acestus/git/dotfiles/vscode/settings.json"
# Alias to edit VS Code keybindings
Set-Alias editvscodekeys "code /home/acestus/git/dotfiles/vscode/keybindings.json"
# Alias to edit VS Code snippets
Set-Alias editvscodesnippets "code /home/acestus/git/dotfiles/vscode/snippets/snippets.code-snippets"

# Alias to run Azure CLI in Docker (if not installed natively)

function claude {
    param([Parameter(Mandatory = $true)][string]$Message)
    & /home/acestus/git/scripts/claude.ps1 -Message $Message
}

# --- oh-my-posh transient prompt workaround ---
# remove any existing dynamic module of OMP
if ($null -ne (Get-Module -Name "oh-my-posh-core")) {
    Remove-Module -Name "oh-my-posh-core" -Force
}

# disable all known python virtual environment prompts
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
$env:PYENV_VIRTUALENV_DISABLE_PROMPT = 1

# Helper functions which need to be defined before the module is loaded
function global:Get-PoshStackCount {
    $locations = Get-Location -Stack
    if ($locations) {
        return $locations.Count
    }
    return 0
}

# global enablers
$global:_ompJobCount = $false
$global:_ompFTCSMarks = $false
$global:_ompPoshGit = $false
$global:_ompAzure = $false
$global:_ompExecutable = "oh-my-posh"
$global:_ompTransientPrompt = $true
$global:_ompStreaming = $false

New-Module -Name "oh-my-posh-core" -ScriptBlock {
    # ...existing code from the provided script...
} | Import-Module -Global
# --- end oh-my-posh transient prompt workaround ---

# oh-my-posh and PSReadLine settings (must be last to set prompt)
try {
    oh-my-posh init pwsh --config "$HOME/git/dotfiles/.night-owl02.json" | Invoke-Expression
}
catch {
    "[$(Get-Date)] oh-my-posh failed: $($_.Exception.Message)" | Out-File -Append "$HOME/omp-profile-error.log"
}
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
#Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
