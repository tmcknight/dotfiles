#!/bin/bash
# Shared helpers for the macOS and Linux setup scripts. Sourced, not executed.

# install_file SRC DEST
#
# Symlink DEST to SRC, backing up whatever real file was there first. Creates
# DEST's parent directory if needed. Linking rather than copying means edits to
# the repo take effect immediately, with no re-run of setup.sh.
install_file() {
    local src="$1" dest="$2"
    local ts

    if [ ! -f "$src" ]; then
        echo "  ERROR: missing source file: $src" >&2
        return 1
    fi

    # Absolute, so the link resolves no matter where it is followed from.
    src="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"

    mkdir -p "$(dirname "$dest")"

    # Already pointing where we want — nothing to do.
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return 0
    fi

    # A real file here is the user's, so save it before replacing. Timestamped:
    # a fixed .backup name would be overwritten on the second run, destroying
    # the original it saved the first time round.
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        ts=$(date +%Y%m%d-%H%M%S)
        echo "  Backing up existing $dest to $dest.$ts.backup"
        cp "$dest" "$dest.$ts.backup"
    fi

    ln -sfn "$src" "$dest"
}
