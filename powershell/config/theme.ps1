# config/theme.ps1

# Import Terminal Icons module
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

# Initialize oh-my-posh with the Catppuccin Mocha theme
oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json | Invoke-Expression

# Set PSReadLine colors for better readability
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    String = 'DarkCyan'
}

# Configure ls color schemes to act like lsd
if (Get-Command ls -ErrorAction SilentlyContinue) {
    Set-Alias ls Get-ChildItem
    $env:LS_COLORS = "di=34:ln=36:so=32:pi=33:ex=35:bd=34:cd=34:su=31:sg=31:tw=34:ow=34"
}

