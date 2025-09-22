# Windows

```pwsh
# install apps
winget import -i windows\WinGet\winget-packages.json

# install nerd font
oh-my-posh font install meslo

# terminal
cp windows\Terminal\settings.json $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# powershell
cp windows\PowerShell\Microsoft.PowerShell_profile.ps1 $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```
