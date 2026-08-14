#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../shared/lib.sh
source "$SHARED_DIR/lib.sh"

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
echo "[1/8] Installing zsh..."
sudo apt-get update
# curl and unzip are what the fnm installer in step 5 checks for and refuses to
# run without.
sudo apt-get install -y zsh zsh-autosuggestions unzip curl

zsh_path=$(command -v zsh)
if [ "$SHELL" != "$zsh_path" ]; then
    echo "  Setting default shell to zsh..."
    chsh -s "$zsh_path"
else
    echo "  Default shell is already zsh."
fi

# Step 2: Create Developer directory
echo "[2/8] Creating ~/Developer directory..."
mkdir -p "$HOME/Developer"

# Step 3: Install eza
if ! command -v eza &>/dev/null; then
    echo "[3/8] Installing eza..."
    sudo apt-get install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update
    sudo apt-get install -y eza
else
    echo "[3/8] eza already installed."
fi

# Step 4: Install GitHub CLI
if ! command -v gh &>/dev/null; then
    echo "[4/8] Installing GitHub CLI..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
else
    echo "[4/8] GitHub CLI already installed."
fi

# Step 5: Install fnm, then a Node LTS through it.
#
# --skip-shell is not optional here: ~/.zshrc is a symlink into this repo, and
# without it the installer appends its own PATH block to the tracked file.
# .zshrc already runs `fnm env`, so there is nothing for it to add.
#
# Installing into ~/.local/bin reuses the PATH entry .zshrc already sets up,
# rather than the installer's default ~/.local/share/fnm, which is on no PATH.
if ! command -v fnm &>/dev/null; then
    echo "[5/8] Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- \
        --skip-shell --install-dir "$HOME/.local/bin"
else
    echo "[5/8] fnm already installed."
fi

# This script is not interactive, so .zshrc has not run and ~/.local/bin is
# not on PATH yet — but fnm was just installed there.
export PATH="$HOME/.local/bin:$PATH"

# `fnm default` is the part that matters: --use-on-cd only resolves a version
# inside a project that pins one, so without a default a plain shell has no
# node. Re-running is a no-op; fnm warns and exits 0 if already installed.
echo "  Installing Node LTS via fnm..."
fnm install --lts
fnm default lts-latest

# Step 6: Install oh-my-posh
if ! command -v oh-my-posh &>/dev/null; then
    echo "[6/8] Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
else
    echo "[6/8] oh-my-posh already installed."
fi

# Step 7: Install dotfiles
echo "[7/8] Installing configuration files..."

# .zshrc
install_file "$SHARED_DIR/.zshrc" "$HOME/.zshrc"
install_file "$SHARED_DIR/.aliases" "$HOME/.aliases"

# .zshenv, read by every zsh rather than only interactive ones. Carries the
# unattended-signing hook, which is the case a remote box needs most: a runner
# or an ssh command never sources .zshrc at all.
install_file "$SHARED_DIR/.zshenv" "$HOME/.zshenv"

# git config
migrate_gitconfig
install_file "$SHARED_DIR/.gitconfig" "$HOME/.gitconfig"

# Unattended signing helpers, sourced by .zshrc. This is the case they exist
# for: an interactive signing agent needs a desktop session, which a remote box
# does not have, so without an on-disk key it cannot sign a commit at all.
install_file "$SHARED_DIR/git-signing.sh" "$HOME/.git-signing.sh"

# oh-my-posh themes
install_file "$SHARED_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

# Claude Code statusline.
# The script parses its stdin JSON with jq.
if ! command -v jq &>/dev/null; then
    echo "  Installing jq (required by the Claude Code statusline)..."
    sudo apt-get install -y jq
fi
# To enable, add this to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
# No chmod needed: the repo tracks claude-statusline.sh as executable, and the
# installed path is a symlink to it.
install_file "$SHARED_DIR/claude-statusline.sh" "$HOME/.claude/statusline-command.sh"

echo ""
echo "=== Setup complete! ==="

# Step 8: Reload the shell config
echo "[8/8] Loading the new shell configuration..."
reload_shell
