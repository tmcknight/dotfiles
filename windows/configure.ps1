# configuration script to setup Windows environment

# install apps
winget import -i WinGet\winget-packages.json

# install nerd font
oh-my-posh font install meslo

# set terminal settings
cp windows\Terminal\settings.json $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# powershell profile
cp windows\PowerShell\Microsoft.PowerShell_profile.ps1 $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
Unblock-File -Path $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1