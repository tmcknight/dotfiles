#!/bin/bash
# Point git at an alternate commit signer for the current shell. Sourced from
# .zshrc, not executed.
#
# Signing normally runs through whatever gpg.ssh.program ~/.gitconfig.local
# names — here, an interactive agent that needs a human to approve every
# request. That is the right default, and wrong in the two cases this file
# exists for: a session with nobody at the keyboard, and a remote host where
# that agent does not exist at all and signing fails outright.
#
# The switch is made with git's GIT_CONFIG_* environment overrides, which
# outrank every config file. Nothing here edits ~/.gitconfig.local, so a shell
# that has not opted in signs exactly as before.
#
#   git-signing-on       sign with the key at $GIT_SIGNING_KEY, this shell only
#   git-signing-off      hand signing back to the configured default
#   git-signing-status   report which of the two is in effect
#
# Getting a key to $GIT_SIGNING_KEY is deliberately out of scope: it is the part
# that depends on your secret store, and it is the part worth keeping out of a
# public repo. Define git-signing-export in ~/.git-signing.local.sh, which is
# sourced at the bottom of this file if present.
#
# SECURITY: a key reachable without a prompt is a key an attacker can use
# without a prompt. Its signatures are indistinguishable from the interactive
# ones, so the commit log cannot tell you which commits were unattended. Put a
# key on a machine only if you would trust that machine with your identity, and
# revoke it if the machine is lost.

# Which key git-signing-on switches to. Override in ~/.zshrc.local if you keep
# it somewhere else.
GIT_SIGNING_KEY="${GIT_SIGNING_KEY:-$HOME/.ssh/id_ed25519_git_signing}"

# git-signing-on
#
# Override gpg.ssh.program and user.signingkey for this shell and everything it
# spawns. Dies with the shell; touches no files.
git-signing-on() {
    local base

    if [ ! -f "$GIT_SIGNING_KEY" ]; then
        echo "git-signing: no key at $GIT_SIGNING_KEY" >&2
        return 1
    fi

    # Already on. Re-running would append a second, redundant pair and lose the
    # saved base index that -off needs to undo the first.
    [ -n "${GIT_SIGNING_ACTIVE:-}" ] && return 0

    # Append to any GIT_CONFIG_* pairs already in the environment rather than
    # assuming ours are the only ones — another tool may have set some.
    base="${GIT_CONFIG_COUNT:-0}"

    # ssh-keygen is git's built-in default signer, and the one thing we can rely
    # on being present: it comes with openssh, not with any password manager.
    export "GIT_CONFIG_KEY_$base=gpg.ssh.program"
    export "GIT_CONFIG_VALUE_$base=ssh-keygen"
    export "GIT_CONFIG_KEY_$((base + 1))=user.signingkey"
    export "GIT_CONFIG_VALUE_$((base + 1))=$GIT_SIGNING_KEY"
    export GIT_CONFIG_COUNT=$((base + 2))

    # Remember where our pairs started, so -off removes exactly those.
    export GIT_SIGNING_ACTIVE="$base"
}

# git-signing-off
#
# Undo git-signing-on, restoring whatever GIT_CONFIG_* state preceded it.
git-signing-off() {
    local base="${GIT_SIGNING_ACTIVE:-}"

    [ -n "$base" ] || return 0

    unset "GIT_CONFIG_KEY_$base" "GIT_CONFIG_VALUE_$base"
    unset "GIT_CONFIG_KEY_$((base + 1))" "GIT_CONFIG_VALUE_$((base + 1))"

    if [ "$base" -eq 0 ]; then
        unset GIT_CONFIG_COUNT
    else
        export GIT_CONFIG_COUNT="$base"
    fi

    unset GIT_SIGNING_ACTIVE
}

# git-signing-status
#
# What git would actually do here, asked of git rather than reconstructed — so
# it accounts for a repo-local override too. Run it inside a repo; the identity
# line is the per-org one only when the repo's remote matches a rule.
git-signing-status() {
    if [ -n "${GIT_SIGNING_ACTIVE:-}" ]; then
        echo "git-signing: unattended — on-disk key, no prompt"
    else
        echo "git-signing: interactive — configured default"
    fi

    echo "  gpg.ssh.program = $(git config --get gpg.ssh.program 2>/dev/null || echo 'ssh-keygen (default)')"
    echo "  user.signingkey = $(git config --get user.signingkey 2>/dev/null || echo '<unset>')"
    echo "  user.email      = $(git config --get user.email 2>/dev/null || echo '<unset>')"
    echo "  commit.gpgsign  = $(git config --get commit.gpgsign 2>/dev/null || echo false)"
}

# Machine-specific signing bits — how a key gets onto this box, and where from.
# Untracked, because that is the half that names a secret store.
# shellcheck source=/dev/null
[ -f ~/.git-signing.local.sh ] && . ~/.git-signing.local.sh

# Opt in for a whole session without typing anything: set GIT_SIGNING_UNATTENDED=1
# in the environment before the shell starts. This is the hook for agent runners
# and remote hosts, where there is no interactive moment to run a command in.
if [ "${GIT_SIGNING_UNATTENDED:-0}" = "1" ] && [ -f "$GIT_SIGNING_KEY" ]; then
    git-signing-on
fi
