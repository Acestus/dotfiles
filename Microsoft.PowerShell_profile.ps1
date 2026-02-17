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

function claude {
    param([Parameter(Mandatory=$true)][string]$Message)
    & /home/acestus/git/scripts/claude.ps1 -Message $Message
}
