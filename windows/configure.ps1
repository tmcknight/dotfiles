# configuration script to setup Windows environment

$ErrorActionPreference = 'Stop'

# install apps
winget import -i (Join-Path $PSScriptRoot 'WinGet\winget-packages.json')

# Node is managed by fnm rather than a system-wide install, so the winget import
# on its own leaves the machine with no node at all. winget only updates PATH
# for *new* sessions, so re-read it from the registry to reach the fnm it just
# installed.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

# `fnm default` is the part that matters: --use-on-cd in the profile only
# resolves a version inside a project that pins one, so without a default a
# plain shell has no node. Re-running is a no-op; fnm warns and exits 0 when
# the version is already installed.
fnm install --lts
fnm default lts-latest

# install nerd font
oh-my-posh font install meslo

# set terminal settings
$TerminalStateDir = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $TerminalStateDir) {
    Copy-Item (Join-Path $PSScriptRoot 'Terminal\settings.json') "$TerminalStateDir\settings.json" -Force
} else {
    Write-Warning "Windows Terminal settings dir not found; skipping. Launch Windows Terminal once, then re-run."
}

# oh-my-posh theme (same path as macOS/Linux: ~/.config/oh-my-posh/)
$ThemeDir = "$HOME\.config\oh-my-posh"
New-Item -ItemType Directory -Force -Path $ThemeDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot '..\shared\theme.omp.json') "$ThemeDir\theme.omp.json" -Force

# powershell profile
$ProfileDir = "$HOME\Documents\PowerShell"
New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'Powershell\Microsoft.PowerShell_profile.ps1') "$ProfileDir\Microsoft.PowerShell_profile.ps1" -Force
Unblock-File -Path "$ProfileDir\Microsoft.PowerShell_profile.ps1"

Write-Host ""
Write-Host "=== Setup complete! ==="

# Load the new profile. Dot-sourcing it from here would not work: the prompt
# function and `wu` would land in this script's scope and vanish on exit. So
# hand over to a fresh pwsh session instead, which loads the profile itself and
# picks up the PATH winget just changed. Exiting it returns to this session.
#
# Skipped when there is no interactive console (CI, `-NonInteractive`), where
# waiting on a shell nobody can type into would hang the run. Also skipped when
# pwsh is missing — the profile lives under Documents\PowerShell, which only
# PowerShell 7+ reads, so Windows PowerShell would start without it.
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $pwsh -or -not [Environment]::UserInteractive -or $env:CI) {
    Write-Host "Open a new PowerShell session to load the new profile."
} else {
    Write-Host "Reloading your shell (exit it to return to the previous one)..."
    & $pwsh.Source -NoLogo
}
