echo "Startup test"

mkdir "~/.config/powershell"
ln -s /workspaces/.codespaces/.persistedshare/dotfiles/Microsoft.PowerShell_profile.ps1 /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1

mkdir "~/.config/fish"
ln -s /workspaces/.codespaces/.persistedshare/dotfiles/fish.config /home/vscode/.config/fish/fish.config

