#!/bin/bash
set -e

curl -L https://github.com/tmcknight/dotfiles/archive/refs/heads/main.tar.gz | tar xz -C /tmp
/tmp/dotfiles-main/linux/setup.sh
