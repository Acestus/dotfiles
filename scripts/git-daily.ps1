#!/usr/bin/env pwsh

# Stage all changes
git add -A

$status = git status --short
if (-not $status) {
    Write-Host "Nothing to commit." -ForegroundColor Yellow
    exit 0
}

Write-Host "Changes staged:" -ForegroundColor Cyan
git status --short
Write-Host ""

# Ask Copilot to summarize the staged diff into a commit message
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
