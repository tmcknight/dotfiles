#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/tmcknight/dotfiles.git"
REPO_DIR="${DOTFILES_DIR:-$HOME/Developer/dotfiles}"

# The configs are symlinked out of this clone, so it has to live somewhere
# permanent — a temp dir would leave every symlink dangling after a reboot.
if ! command -v git >/dev/null 2>&1; then
    case "$(uname)" in
        Darwin)
            echo "git not found. Installing the Xcode Command Line Tools..."
            xcode-select --install || true
            echo "Re-run this script once the Command Line Tools finish installing."
            exit 1
            ;;
        Linux)
            echo "git not found. Installing..."
            sudo apt-get update
            sudo apt-get install -y git
            ;;
        *)
            echo "Unsupported OS: $(uname)" >&2
            exit 1
            ;;
    esac
fi

if [ -d "$REPO_DIR/.git" ]; then
    echo "Updating existing clone at $REPO_DIR..."
    git -C "$REPO_DIR" pull --ff-only
else
    echo "Cloning dotfiles to $REPO_DIR..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
fi

case "$(uname)" in
    Darwin) "$REPO_DIR/macos/setup.sh" ;;
    Linux)  "$REPO_DIR/linux/setup.sh" ;;
    *)      echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
esac
