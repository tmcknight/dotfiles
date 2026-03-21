# Dotfiles

Personal configuration files for setting up new machines.

## macOS

Copy the dotfiles to the new machine and run the setup script:

```bash
# from your current machine (enable Remote Login on the new Mac first)
scp -r ~/Developer/dotfiles user@new-mac:~/.dotfiles
ssh user@new-mac "~/.dotfiles/macos/setup.sh"
```

The setup script will:

1. Install Xcode Command Line Tools
2. Set default shell to zsh
3. Create `~/Developer` directory
4. Install [Homebrew](https://brew.sh) (if not already installed)
5. Install all packages and casks from the [Brewfile](macos/Brewfile)
6. Copy the [.zshrc](macos/.zshrc) to `~/.zshrc` (backs up existing one first)
7. Install the custom [oh-my-posh theme](macos/theme.omp.json) to `~/.config/oh-my-posh/`
8. Install the [Ghostty config](macos/ghostty.config) to `~/Library/Application Support/com.mitchellh.ghostty/`
9. Set macOS system preferences (Finder settings, key repeat, etc.)

## Windows

```pwsh
# run configuration script to setup Windows environment
Unblock-File -Path .\windows\configure.ps1
.\windows\configure.ps1
```
