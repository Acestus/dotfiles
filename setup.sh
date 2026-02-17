#!/usr/bin/env bash
# setup.sh: Symlink dotfiles and set up environment for local or Codespaces use
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Symlink bashrc
if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
fi
ln -sf "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"

# Symlink PowerShell profile (Linux)
POWERSHELL_PROFILE="$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
mkdir -p "$(dirname "$POWERSHELL_PROFILE")"
ln -sf "$DOTFILES_DIR/Microsoft.PowerShell_profile.ps1" "$POWERSHELL_PROFILE"

# Symlink VS Code settings
VSCODE_USER="$HOME/.config/Code/User"
mkdir -p "$VSCODE_USER/snippets"
ln -sf "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER/settings.json"
ln -sf "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
ln -sf "$DOTFILES_DIR/vscode/snippets/snippets.code-snippets" "$VSCODE_USER/snippets/snippets.code-snippets"

echo "Symlinks created. Your environment is now using dotfiles from $DOTFILES_DIR."

