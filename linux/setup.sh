#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"

echo "=== Linux Setup ==="
echo ""

# Step 1: Set default shell to zsh
if [ "$SHELL" != "$(which zsh 2>/dev/null)" ]; then
    echo "[1/7] Installing and setting default shell to zsh..."
    sudo apt-get update
    sudo apt-get install -y zsh zsh-autosuggestions unzip
    chsh -s "$(which zsh)"
else
    echo "[1/7] Default shell is already zsh."
fi

# Step 2: Create Developer directory
echo "[2/7] Creating ~/Developer directory..."
mkdir -p "$HOME/Developer"

# Step 3: Install eza
if ! command -v eza &>/dev/null; then
    echo "[3/7] Installing eza..."
    sudo apt-get install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update
    sudo apt-get install -y eza
else
    echo "[3/7] eza already installed."
fi

# Step 4: Install GitHub CLI
if ! command -v gh &>/dev/null; then
    echo "[4/7] Installing GitHub CLI..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
else
    echo "[4/7] GitHub CLI already installed."
fi

# Step 5: Install Node.js
if ! command -v node &>/dev/null; then
    echo "[5/7] Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[5/7] Node.js already installed."
fi

# Step 6: Install oh-my-posh
if ! command -v oh-my-posh &>/dev/null; then
    echo "[6/7] Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
else
    echo "[6/7] oh-my-posh already installed."
fi

# Step 7: Install dotfiles
echo "[7/7] Installing configuration files..."

# .zshrc
if [ -f "$HOME/.zshrc" ]; then
    echo "  Backing up existing .zshrc to ~/.zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi
cp "$SHARED_DIR/.zshrc" "$HOME/.zshrc"
cp "$SHARED_DIR/.aliases" "$HOME/.aliases"

# oh-my-posh theme
mkdir -p "$HOME/.config/oh-my-posh"
cp "$SHARED_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal to load the new shell configuration."
