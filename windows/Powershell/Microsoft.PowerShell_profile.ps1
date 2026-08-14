oh-my-posh init pwsh --config "$HOME/.config/oh-my-posh/theme.omp.json" | Invoke-Expression

# fnm — Node version manager, installed by winget. Same flags as ~/.zshrc, so
# both platforms resolve the same version for a given project:
#   --use-on-cd               switch on cd, from .nvmrc/.node-version
#   --version-file-strategy   also look in parent dirs, so monorepo subdirs work
#   --resolve-engines         fall back to package.json engines.node
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell `
        --version-file-strategy=recursive `
        --resolve-engines | Out-String | Invoke-Expression
}

function wu {
    winget upgrade @args
}
