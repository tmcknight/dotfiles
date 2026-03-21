# Dotfiles

Everything I need to go from a fresh Mac (or Windows box) to fully set up in one command.

## macOS

On a fresh Mac, run:

```bash
curl -fsSL https://raw.githubusercontent.com/tmcknight/dotfiles/main/macos/install.sh | bash
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
