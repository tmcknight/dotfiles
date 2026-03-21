# Dotfiles

Everything I need to go from a fresh Mac (or Windows box) to fully set up in one command.

## macOS

On a fresh Mac, run:

```bash
curl -fsSL https://raw.githubusercontent.com/tmcknight/dotfiles/main/macos/install.sh | bash
```

The setup script will:

1. Set default shell to zsh
2. Create `~/Developer` directory
3. Install [Homebrew](https://brew.sh) (+ Xcode Command Line Tools if not already installed)
4. Install all packages and casks from the [Brewfile](macos/Brewfile)
5. Copy the [.zshrc](macos/.zshrc) to `~/.zshrc` (backs up existing one first)
6. Install the custom [oh-my-posh theme](macos/theme.omp.json) to `~/.config/oh-my-posh/`
7. Install the [Ghostty config](macos/ghostty.config) to `~/Library/Application Support/com.mitchellh.ghostty/`
8. Set macOS system preferences (Finder settings, key repeat, etc.)

## Windows

```pwsh
# run configuration script to setup Windows environment
Unblock-File -Path .\windows\configure.ps1
.\windows\configure.ps1
```
