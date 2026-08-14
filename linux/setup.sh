#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"

echo "=== Linux Setup ==="
echo ""

# Everything below assumes apt. Fail here rather than part-way through with a
# cascade of "apt-get: command not found".
if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script supports Debian/Ubuntu only (apt-get not found)." >&2
    exit 1
fi

# Step 1: Install zsh and make it the default shell.
# The package install is unconditional: a box that already runs zsh (many
# container images do) still needs zsh-autosuggestions, which ~/.zshrc sources.
echo "[1/7] Installing zsh..."
sudo apt-get update
sudo apt-get install -y zsh zsh-autosuggestions unzip

zsh_path=$(command -v zsh)
if [ "$SHELL" != "$zsh_path" ]; then
    echo "  Setting default shell to zsh..."
    chsh -s "$zsh_path"
else
    echo "  Default shell is already zsh."
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

# oh-my-posh themes
mkdir -p "$HOME/.config/oh-my-posh"
cp "$SHARED_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

# Claude Code statusline.
# The script parses its stdin JSON with jq.
if ! command -v jq &>/dev/null; then
    echo "  Installing jq (required by the Claude Code statusline)..."
    sudo apt-get install -y jq
fi
# To enable, add this to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/statusline-command.sh" ]; then
    echo "  Backing up existing statusline-command.sh to ~/.claude/statusline-command.sh.backup"
    cp "$HOME/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh.backup"
fi
# rm first: on a dev machine this path may be a symlink back into the repo,
# and cp would then try to copy the file onto itself and fail.
rm -f "$HOME/.claude/statusline-command.sh"
cp "$SHARED_DIR/claude-statusline.sh" "$HOME/.claude/statusline-command.sh"
chmod +x "$HOME/.claude/statusline-command.sh"

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal to load the new shell configuration."
