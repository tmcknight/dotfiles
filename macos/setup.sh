#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"

echo "=== macOS Setup ==="
echo ""

# Step 1: Set default shell to zsh
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "[1/8] Setting default shell to zsh..."
    chsh -s /bin/zsh
else
    echo "[1/8] Default shell is already zsh."
fi

# Step 2: Create Developer directory
echo "[2/8] Creating ~/Developer directory..."
mkdir -p "$HOME/Developer"

# Step 3: Install Homebrew if not present (also installs Xcode CLT)
if ! command -v brew &>/dev/null; then
    echo "[3/8] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "[3/8] Homebrew already installed, updating..."
    brew update
fi

# Step 2: Install packages from Brewfile
echo "[4/8] Installing packages from Brewfile..."
brew bundle --verbose --file="$SCRIPT_DIR/Brewfile"

# Step 3: Copy .zshrc and oh-my-posh theme
echo "[5/8] Installing .zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    echo "  Backing up existing .zshrc to ~/.zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
cp "$SHARED_DIR/.zshrc" "$HOME/.zshrc"
cp "$SHARED_DIR/.aliases" "$HOME/.aliases"

echo "[6/8] Installing oh-my-posh theme..."
mkdir -p "$HOME/.config/oh-my-posh"
cp "$SHARED_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

echo "[7/8] Installing Ghostty config..."
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
cp "$SCRIPT_DIR/ghostty.config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

# Step 6: Set macOS defaults
echo "[8/8] Setting macOS preferences..."

# Show filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Set new Finder windows to open to Desktop
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Show icons for external drives, internal drives, servers, and removable media on Desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Disable natural scroll direction
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Show full POSIX path in Finder title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use list view as default in all Finder windows
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show ~/Library folder (hidden by default)
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# Expand General and Open With panes in Get Info window
defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal to load the new shell configuration."
