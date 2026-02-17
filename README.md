# Dotfiles

This repository contains my cross-platform dotfiles for bash, PowerShell, and VS Code. Designed for local use and Codespaces.

## Quick Setup

Run the setup script to symlink all configs:

```bash
bash setup.sh
```

This will:
- Symlink `.bashrc` to your home directory
- Symlink PowerShell profile to `~/.config/powershell/`
- Symlink VS Code `settings.json`, `keybindings.json`, and snippets

## Editing Configs

Use the provided aliases (see bashrc and PowerShell profile) to quickly edit your config files:
- `editbashrc` — Edit bashrc
- `editprofile` — Edit PowerShell profile
- `editvscodesettings` — Edit VS Code settings
- `editvscodekeys` — Edit VS Code keybindings
- `editvscodesnippets` — Edit VS Code snippets

## Codespaces

These dotfiles are Codespaces-ready. Add this repo as your Codespaces dotfiles repo for instant setup.

## Recommendations
- Add your own aliases and functions to `bashrc` or PowerShell profile
- Use `.gitignore` to avoid committing unwanted files
- Extend with zsh/fish configs if needed
