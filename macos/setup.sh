#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../shared/lib.sh
source "$SHARED_DIR/lib.sh"

echo "=== macOS Setup ==="
echo ""

# Set default shell to zsh
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "[1/10] Setting default shell to zsh..."
    chsh -s /bin/zsh
else
    echo "[1/10] Default shell is already zsh."
fi

# Create Developer directory
echo "[2/10] Creating ~/Developer directory..."
mkdir -p "$HOME/Developer"

# Install Homebrew if not present (also installs Xcode CLT)
if ! command -v brew &>/dev/null; then
    echo "[3/10] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "[3/10] Homebrew already installed, updating..."
    brew update
fi

# Homebrew refuses to load formulae and casks from third-party taps until they
# are explicitly trusted, so on a fresh machine `brew bundle` aborts the moment
# it reaches the first cask from one. Trust exactly the taps this Brewfile
# declares -- nothing broader -- so adding a tap to the Brewfile is the single
# place that decision gets made. `brew trust` is idempotent and does not need
# the tap to be tapped yet.
echo "[4/10] Trusting third-party taps from Brewfile..."
while read -r tap; do
    echo "  $tap"
    brew trust --tap "$tap"
done < <(awk -F'"' '/^tap "/ { print $2 }' "$SCRIPT_DIR/Brewfile")

# Install packages from Brewfile
echo "[5/10] Installing packages from Brewfile..."
brew bundle --verbose --file="$SCRIPT_DIR/Brewfile"

# Node is managed by fnm, not a global brew node, so the Brewfile alone leaves
# a machine with no node at all. `fnm default` is the part that matters: without
# it, the --use-on-cd hook in .zshrc only resolves a version inside projects
# that pin one, and a plain shell has no node. Re-running is a no-op; fnm warns
# and exits 0 if the version is already installed.
echo "[6/10] Installing Node LTS via fnm..."
fnm install --lts
fnm default lts-latest

# Link .zshrc, aliases and git config into place
echo "[7/10] Installing shell and git config..."
install_file "$SHARED_DIR/.zshrc" "$HOME/.zshrc"
install_file "$SHARED_DIR/.aliases" "$HOME/.aliases"

echo "  Installing git config..."
migrate_gitconfig
install_file "$SHARED_DIR/.gitconfig" "$HOME/.gitconfig"

echo "[8/10] Installing oh-my-posh themes..."
install_file "$SHARED_DIR/theme.omp.json" "$HOME/.config/oh-my-posh/theme.omp.json"

# Claude Code statusline.
# Requires jq. To enable, add this to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
# No chmod needed: the repo tracks claude-statusline.sh as executable, and the
# installed path is a symlink to it.
install_file "$SHARED_DIR/claude-statusline.sh" "$HOME/.claude/statusline-command.sh"

echo "[9/10] Installing Ghostty config..."
install_file "$SCRIPT_DIR/ghostty.config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

# Set macOS defaults
echo "[10/10] Setting macOS preferences..."

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

# Show ~/Library folder (hidden by default).
# `xattr -d` exits 1 when the attribute is absent, which is the normal case on
# modern macOS — without the guard that aborts the whole script under `set -e`.
chflags nohidden ~/Library
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# Expand General and Open With panes in Get Info window
defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal to load the new shell configuration."
