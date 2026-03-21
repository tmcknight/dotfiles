#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
brew bundle --file="$SCRIPT_DIR/Brewfile"

# Step 3: Copy .zshrc and oh-my-posh theme
echo "[5/8] Installing .zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    echo "  Backing up existing .zshrc to ~/.zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

echo "[6/8] Installing oh-my-posh theme..."
mkdir -p "$HOME/.config/oh-my-posh"
cp "$SCRIPT_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

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

# Disable natural scroll direction
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal to load the new shell configuration."
