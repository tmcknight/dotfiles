#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== macOS Setup ==="
echo ""

# Step 1: Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo "[1/9] Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "  Waiting for installation to complete..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
else
    echo "[1/9] Xcode Command Line Tools already installed."
fi

# Step 2: Set default shell to zsh
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "[2/9] Setting default shell to zsh..."
    chsh -s /bin/zsh
else
    echo "[2/9] Default shell is already zsh."
fi

# Step 3: Create Developer directory
echo "[3/9] Creating ~/Developer directory..."
mkdir -p "$HOME/Developer"

# Step 4: Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    echo "[4/9] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "[4/9] Homebrew already installed, updating..."
    brew update
fi

# Step 2: Install packages from Brewfile
echo "[5/9] Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

# Step 3: Copy .zshrc and oh-my-posh theme
echo "[6/9] Installing .zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    echo "  Backing up existing .zshrc to ~/.zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

echo "[7/9] Installing oh-my-posh theme..."
mkdir -p "$HOME/.config/oh-my-posh"
cp "$SCRIPT_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

echo "[8/9] Installing Ghostty config..."
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
cp "$SCRIPT_DIR/ghostty.config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

# Step 6: Set macOS defaults
echo "[9/9] Setting macOS preferences..."

# Show filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Disable natural scroll direction
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal to load the new shell configuration."
