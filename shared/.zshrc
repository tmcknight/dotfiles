# Load aliases
[ -f ~/.aliases ] && source ~/.aliases

# History. Without HISTFILE set, zsh keeps no history between sessions at all.
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY        # live sync across open shells
setopt EXTENDED_HISTORY     # timestamp + duration per entry
setopt HIST_IGNORE_ALL_DUPS # keep only the most recent copy of a command
setopt HIST_IGNORE_SPACE    # omit commands typed with a leading space
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY          # expand !! onto the prompt instead of running it

# Add oh-my-posh to PATH on Linux (installed to ~/.local/bin by default)
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Completion. Homebrew drops per-formula completions (gh, az, uv) into
# share/zsh/site-functions, which is not on the default fpath.
if [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions" ]]; then
    fpath=("${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit
# -C reuses the cached dump instead of re-scanning fpath on every shell start.
# After installing something new: rm -f ~/.zcompdump && compinit
compinit -C

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive

# Prompt. `$+commands[...]` is a zsh builtin lookup — no subprocess.
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && (( $+commands[oh-my-posh] )); then
    eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.omp.json)"
fi

# zsh-autosuggestions. Probing known paths beats forking `brew --prefix` on
# every shell start, and also picks up Intel Macs (/usr/local).
for _zsh_autosuggest in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
do
    if [[ -f "$_zsh_autosuggest" ]]; then
        source "$_zsh_autosuggest"
        break
    fi
done
unset _zsh_autosuggest

# fnm — Node version manager, and the only source of node on any platform:
# the Brewfile on macOS, the install script in linux/setup.sh.
#   --use-on-cd               switch on cd, from .nvmrc/.node-version
#   --version-file-strategy   also look in parent dirs, so monorepo subdirs work
#   --resolve-engines         fall back to package.json engines.node
if (( $+commands[fnm] )); then
    eval "$(fnm env --use-on-cd --shell zsh \
        --version-file-strategy=recursive \
        --resolve-engines)"
fi

# Skips the OSC 11 background-colour probe that glamour-based tools (gh) fire at
# startup. Terminals that answer it slowly leave the reply in the tty buffer, and
# the next prompt prints it as `11;rgb:...`.
export GLAMOUR_STYLE=dark

# Machine-specific config — absolute paths, work-only tooling, secrets. Not
# tracked. Sourced last so it can override anything above.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Commit signing. Sourced after .zshrc.local, which is where GIT_SIGNING_KEY and
# anything the untracked half needs get set — this reads them, so it cannot run
# first. Defines git-signing-{on,off,status} for use at the prompt.
#
# The *unattended* opt-in is not this file's job any more, though sourcing here
# still triggers it for a shell that inherited GIT_SIGNING_UNATTENDED=1 from its
# parent. A runner that injects that variable per command sets it after this
# file was read, so ~/.zshenv owns that case — see the note there.
[ -f ~/.git-signing.sh ] && source ~/.git-signing.sh
