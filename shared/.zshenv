# Sourced by EVERY zsh — interactive, non-interactive, and scripts alike. That
# is the whole reason this file exists, and it is the reason to keep it nearly
# empty: anything here runs before every `zsh -c` on the machine.
#
# ~/.zshrc is not enough for one case. An agent runner (Claude Code, CI, a
# remote hook) sets GIT_SIGNING_UNATTENDED=1 in the environment of the commands
# it runs, not in the login shell it inherited. .zshrc was read once, at
# startup, before that variable existed — so the opt-in at the bottom of
# git-signing.sh evaluated against an empty value and signing stayed on the
# interactive agent, which then failed with no human there to approve it. The
# symptom is a commit that dies at "failed to write commit object" while
# `git-signing-status` insists the functions are loaded, because they are: the
# definitions survive in the runner's shell snapshot, and only the top-level
# opt-in was missed.
#
# The test is repeated here rather than just sourcing unconditionally so a
# normal shell behaves exactly as it did before this file existed — it pays
# nothing, and .zshrc still sources git-signing.sh for the interactive
# git-signing-{on,off,status} commands.
if [ "${GIT_SIGNING_UNATTENDED:-0}" = "1" ]; then
    # Machine-specific GIT_SIGNING_KEY, for a box that keeps the key somewhere
    # other than the default. ~/.zshrc.local is the usual home for that kind of
    # override and it is too late here — .zshenv runs first, by design.
    # shellcheck source=/dev/null
    [ -f ~/.zshenv.local ] && source ~/.zshenv.local

    # Its own bottom-of-file hook reads GIT_SIGNING_UNATTENDED and switches over.
    # shellcheck source=/dev/null
    [ -f ~/.git-signing.sh ] && source ~/.git-signing.sh
fi
