# configuration script to setup Windows environment

$ErrorActionPreference = 'Stop'

# install apps
winget import -i (Join-Path $PSScriptRoot 'WinGet\winget-packages.json')

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
