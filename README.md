# Dotfiles

Everything I need to go from a fresh Mac, Linux box, or Windows box to fully set up in one command.

## macOS / Linux

On a fresh Mac or Linux box, run:

```bash
curl -fsSL -o /tmp/install.sh https://raw.githubusercontent.com/tmcknight/dotfiles/main/install.sh && bash /tmp/install.sh
```

The script auto-detects the OS and runs the appropriate setup.

### macOS

The setup script will:

1. Set default shell to zsh
2. Create `~/Developer` directory
3. Install [Homebrew](https://brew.sh) (+ Xcode Command Line Tools if not already installed)
4. Install all packages and casks from the [Brewfile](macos/Brewfile)
5. Copy the [.zshrc](shared/.zshrc) to `~/.zshrc` (backs up existing one first)
6. Install the custom [oh-my-posh theme](shared/theme.omp.json) to `~/.config/oh-my-posh/`
7. Install the [Ghostty config](macos/ghostty.config) to `~/Library/Application Support/com.mitchellh.ghostty/`
8. Set macOS system preferences (Finder settings, key repeat, etc.)

### Linux (Debian/Ubuntu)

The setup script will:

1. Install and set default shell to zsh (+ zsh-autosuggestions)
2. Create `~/Developer` directory
3. Install [eza](https://github.com/eza-community/eza) via official apt repo
4. Install [GitHub CLI](https://cli.github.com/)
5. Install [Node.js](https://nodejs.org/) LTS via NodeSource
6. Install [oh-my-posh](https://ohmyposh.dev/) and the custom [theme](shared/theme.omp.json)
7. Copy the [.zshrc](shared/.zshrc) to `~/.zshrc` (backs up existing one first)

## Windows

```pwsh
# run configuration script to setup Windows environment
Unblock-File -Path .\windows\configure.ps1
.\windows\configure.ps1
```
