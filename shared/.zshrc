# Load aliases
[ -f ~/.aliases ] && source ~/.aliases

# Add oh-my-posh to PATH on Linux (installed to ~/.local/bin by default)
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
    eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.omp.json)"
fi

if [[ "$(uname)" == "Darwin" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
