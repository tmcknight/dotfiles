oh-my-posh init pwsh --config "$HOME/.config/oh-my-posh/theme.omp.json" | Invoke-Expression

function wu {
    winget upgrade @args
}
