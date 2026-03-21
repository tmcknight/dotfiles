#!/bin/bash
set -e

curl -L https://github.com/tmcknight/dotfiles/archive/refs/heads/main.tar.gz | tar xz -C /tmp

case "$(uname)" in
    Darwin) /tmp/dotfiles-main/macos/setup.sh ;;
    Linux)  /tmp/dotfiles-main/linux/setup.sh ;;
    *)      echo "Unsupported OS: $(uname)" && exit 1 ;;
esac
