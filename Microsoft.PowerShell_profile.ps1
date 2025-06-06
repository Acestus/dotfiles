function prompt {
    "PS $($executionContext.SessionState.Path.CurrentLocation)$(':' * ($nestedPromptLevel + 1)) 
> ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
  }

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

function git-daily {
    param (
        [Parameter(Mandatory=$False)]
        [string]$message="Daily Commit"
    )
    Write-Host "Committing changes to git with message: $message"
    git pull
    git add .
    git commit -m $message
    git push
}
# 
#add path C:\Users\wbalconi\AppData\Local\Programs\oh-my-posh\bin\oh-my-posh.exe
# $env:Path += ";C:\Users\wbalconi\AppData\Local\Programs\oh-my-posh\bin"
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\my-posh04.omp.json" | Invoke-Expression

#Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
#$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
#if (Test-Path($ChocolateyProfile)) {
#  Import-Module "$ChocolateyProfile"
#}

$env:Path += "C:\Program Files\nvim\bin"
### Transcript Section ###
# used to setup automated transcript start when PowerShell starts

## Transcript Section Variables ##
# On Windows, I like to put it in the C drive directly.

#$TranscriptDir = "C:\Users\wweeks\OneDrive - Reprise Financial\Documents\transcripts\"

# transcript log sets up the file's name. It will tell you:
# - the computer the transcript came from
# - the user's PowerShell session that is recordedf
# - the day the transcript was made

#$TranscriptLog = (hostname)+"_"+$env:USERNAME+"_"+(Get-Date -UFormat "%Y-%m-%d")

# Transcript Path is the full path and file name of the transcript log.
# (putting it into a single variable increases readability below)
#$TrascriptPath = $TranscriptDir + $TranscriptLog
## end of transcript section variables ##


# Test to see if the transcript directory exists. If it doesn't create it.
#if (!($TranscriptDir)) {
#    New-Item $TranscriptDir -Type Directory -Force
#}

# start the transcription based on the path we've created above
#Start-Transcript -LiteralPath $TrascriptPath -Append
### end of transcript section ###

# Connect via Azure Bastion
#az network bastion rdp --name "<BastionName>" --resource-group "<ResourceGroupName>" --target-resource-id "<VMResourceId>"
function connect {
    param (
        [Parameter(Mandatory=$True)]
        [string]$vmName
    )
    $vmResourceGroupName = get-azvm -Name $vmName | select -ExpandProperty ResourceGroupName
    $vmResourceId = (Get-AzVM -Name $vmName -ResourceGroupName $vmResourceGroupName).Id
    Write-Host "Connecting to $vmName in $vmResourceGroupName"
    az network bastion rdp --name $bastionName --resource-group $vmResourceGroupName --target-resource-id $vmResourceId
}

# get vm with the name busafs

# Oh my Posh
#$env:Path += ";C:\Users\user\AppData\Local\Programs\oh-my-posh\bin"

#$env:Path += ";C:\apps\terraform"
#$env:Path += ";C:\apps\opentofu"
#$env:Path += ";C:\apps\aztfexport"
#$env:Path += ";C:\q\w64"
