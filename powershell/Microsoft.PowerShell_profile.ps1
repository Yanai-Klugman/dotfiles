# Microsoft.PowerShell_profile.ps1

<#
    Cheat Sheet:
    - Navigation:
        - docs    : Navigate to Documents folder
        - dtop    : Navigate to Desktop folder
        - dev     : Navigate to Development drive (D:\)
    - File Operations:
        - touch <file> : Create a new file
        - ff <name>    : Find files with <name>
        - grep <regex> [dir] : Search for <regex> in [dir] or input
        - sed <file> <find> <replace> : Replace <find> with <replace> in <file>
        - which <name> : Show full path of <name>
        - head <file> [n] : Show first [n] lines of <file> (default: 10)
        - tail <file> [n] : Show last [n] lines of <file> (default: 10)
        - unzip <file> : Unzip <file> to current directory
    - Git Operations:
        - gs  : Git status
        - ga  : Git add all changes
        - gc <message> : Git commit with <message>
        - gp  : Git push
        - gcom <message> : Git add, commit, and push with <message>
        - lazyg <message> : Git add, commit, and push with <message>
    - Clipboard Operations:
        - cpy <text> : Copy <text> to clipboard
        - pst : Paste from clipboard
    - System Operations:
        - uptime : Show system uptime
        - sysinfo : Show system information
        - df : Show disk usage
        - flushdns : Clear DNS cache
        - Get-PubIP : Get public IP address
        - pkill <name> : Kill process by name
        - pgrep <name> : Find process by name
    - Miscellaneous:
        - reload-profile : Reload PowerShell profile
        - nf <name> : Create a new file with <name>
        - mkcd <dir> : Create and navigate to <dir>
        - ep : Edit profile with default editor
        - sync-profile : Manually sync profile from GitHub
#>

# User Configurable Variables
$profileUrl = "https://raw.githubusercontent.com/Yanai-Klugman/dotfiles/main/powershell/Microsoft.PowerShell_profile.ps1"
$useStarship = $true
$editor = ""
$fontDownloadUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip"

# Function to check for command existence
function Test-CommandExists {
    param ($command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Function to set the default editor
function Set-DefaultEditor {
    $global:editor = if (Test-CommandExists nvim) { 'nvim' }
                     elseif (Test-CommandExists code) { 'code' }
                     elseif (Test-CommandExists cursor) { 'cursor' }
                     elseif ($IsWindows) { 'notepad' }
                     else { 'nano' }
}

# Set default editor
Set-DefaultEditor

# Function to ensure the script is running with elevated privileges
function Ensure-Admin {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Administrator privileges are required for some actions. Please run this script with 'sudo'!"
        exit
    }
}

# Function to sync profile from GitHub
function Sync-Profile {
    try {
        $remoteContent = Invoke-RestMethod -Uri $profileUrl -ErrorAction Stop
        if (Test-Path -Path $PROFILE -PathType Leaf) {
            $localContent = Get-Content -Path $PROFILE -Raw
            if ($remoteContent -ne $localContent) {
                $remoteContent | Set-Content -Path $PROFILE -Force
                Write-Host "Profile has been synced with the latest version from GitHub."
                Write-Host "Please restart your PowerShell session to apply the changes."
            } else {
                Write-Host "Profile is already up to date."
            }
        } else {
            $remoteContent | Set-Content -Path $PROFILE -Force
            Write-Host "Profile has been created with the latest version from GitHub."
            Write-Host "Please restart your PowerShell session to apply the changes."
        }
    } catch {
        Write-Warning "Failed to sync profile from GitHub. Error: $_"
    }
}

# Function to install missing dependencies
function Install-Dependencies {
    if (-not (Test-CommandExists winget)) {
        Write-Warning "winget is not installed. Please install it manually."
        exit
    }

    if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
        try {
            Install-Module -Name PowerShellGet -Force -Scope CurrentUser
        } catch {
            Write-Error "Failed to install PowerShellGet. Error: $_"
            exit
        }
    }

    if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
        try {
            Install-Module -Name PackageManagement -Force -Scope CurrentUser
        } catch {
            Write-Error "Failed to install PackageManagement. Error: $_"
            exit
        }
    }

    if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
        try {
            Install-Module -Name PSReadLine -Force -Scope CurrentUser
        } catch {
            Write-Error "Failed to install PSReadLine. Error: $_"
            exit
        }
    }

    if (-not (Test-CommandExists starship)) {
        try {
            winget install -e --id Starship.Starship
        } catch {
            Write-Error "Failed to install Starship. Error: $_"
        }
    }

    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        try {
            Install-Module -Name Terminal-Icons -Repository PSGallery -Force -Scope CurrentUser
        } catch {
            Write-Error "Failed to install Terminal Icons module. Error: $_"
        }
    }

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
    if ($fontFamilies -notcontains "CaskaydiaCove NF") {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile((New-Object System.Uri($fontDownloadUrl)), ".\CascadiaCode.zip")

            Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path ".\CascadiaCode" -Recurse -Force
            Remove-Item -Path ".\CascadiaCode.zip" -Force
        } catch {
            Write-Error "Failed to download or install the Cascadia Code font. Error: $_"
        }
    }
}

# Install dependencies
Install-Dependencies

# Function to initialize prompt with starship and enable transient prompt
function Initialize-Prompt {
    if ($useStarship) {
        if (Test-CommandExists starship) {
            Invoke-Expression (&starship init powershell)
            function Invoke-Starship-TransientFunction {
                &starship module character
            }
            Enable-TransientPrompt
        }
    }
}

# Utility Functions
function touch {
    param ($file)
    "" | Out-File $file -Encoding ASCII
}

function ff {
    param ($name)
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.Directory)\$($_.Name)"
    }
}

function grep {
    param ($regex, $dir)
    if ($dir) {
        Get-ChildItem $dir | Select-String $regex
    } else {
        $input | Select-String $regex
    }
}

function sed {
    param ($file, $find, $replace)
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which {
    param ($name)
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export {
    param ($name, $value)
    Set-Item -Force -Path "env:$name" -Value $value
}

function head {
    param ($path, $n = 10)
    Get-Content $path -Head $n
}

function tail {
    param ($path, $n = 10)
    Get-Content $path -Tail $n
}

function la {
    Get-ChildItem -Path . -Force | Format-Table -AutoSize
}

function ll {
    Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize
}

function gs { git status }
function ga { git add . }
function gc {
    param ($m)
    git commit -m "$m"
}
function gp { git push }
function g { z Github }
function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

function cpy {
    param ($text)
    Set-Clipboard $text
}

function pst { Get-Clipboard }

function docs { Set-Location -Path $HOME\Documents }
function dtop { Set-Location -Path $HOME\Desktop }
function dev { Set-Location -Path D:\ }

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function reload-profile { & $profile }

function unzip {
    param ($file)
    Expand-Archive -Path $file -DestinationPath $pwd
}

function pkill {
    Get-Process $args[0] -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep {
    Get-Process $args[0]
}

function nf {
    param ($name)
    New-Item -ItemType "file" -Path . -Name $name
}

function mkcd {
    param ($dir)
    mkdir $dir -Force
    Set-Location $dir
}

function sysinfo { Get-ComputerInfo }

function df { get-volume }

function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

function flushdns { Clear-DnsClientCache }

function k9 { Stop-Process -Name $args[0] }

function ep { & $editor $PROFILE }

# Enable transient prompt and other PSReadLine options
try {
    Set-PSReadLineOption -ContinuationPrompt '>> ' -HistorySearchCursorMovesToEnd $true -HistorySaveStyle SaveIncrementally -HistoryNoDuplicates $true -HistorySearchCaseSensitive $false -HistorySavePath (Join-Path -Path $HOME -ChildPath '.config\powershell\PSReadline\PSReadlineHistory.txt') -Colors @{
        Command = 'Yellow'
        Parameter = 'Green'
        String = 'DarkCyan'
    }
} catch {
    Write-Warning "PSReadLine option not supported. Ensure you have the latest version installed."
}

# Set window title after initializing tools
$Host.UI.RawUI.WindowTitle = "PowerShell"

# Import Terminal-Icons module (if not already imported)
if (-not (Get-Module -Name Terminal-Icons)) {
    Import-Module -Name Terminal-Icons
}

# Sync profile silently
Sync-Profile

# Ensure a new line after each prompt
$function:prompt = {
    "$((Get-Location) -replace $HOME, '~')`n> "
}

# Alias Definitions
Set-Alias -Name docs -Value { Set-Location -Path $HOME\Documents }
Set-Alias -Name dtop -Value { Set-Location -Path $HOME\Desktop }
Set-Alias -Name dev -Value { Set-Location -Path D:\ }

# Manual Sync Command with Progress Output
function sync-profile {
    $animationFrames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    $frameCount = $animationFrames.Count
    $i = 0

    try {
        $remoteContent = Invoke-RestMethod -Uri $profileUrl -ErrorAction Stop
        Write-Host -NoNewline -ForegroundColor Cyan "`r${($animationFrames[$i % $frameCount])} Syncing profile..."
        if (Test-Path -Path $PROFILE -PathType Leaf) {
            $localContent = Get-Content -Path $PROFILE -Raw
            if ($remoteContent -ne $localContent) {
                $remoteContent | Set-Content -Path $PROFILE -Force
                Write-Host "`rProfile has been synced with the latest version from GitHub."
                Write-Host "Please restart your PowerShell session to apply the changes."
            } else {
                Write-Host "`rProfile is already up to date."
            }
        } else {
            $remoteContent | Set-Content -Path $PROFILE -Force
            Write-Host "`rProfile has been created with the latest version from GitHub."
            Write-Host "Please restart your PowerShell session to apply the changes."
        }
    } catch {
        Write-Warning "`rFailed to sync profile from GitHub. Error: $_"
    }
}

# Initialize deferred loading and animation
function Initialize-DeferredLoading {
    $jobs = @()
    $jobs += Start-Job -ScriptBlock { LazyLoad-TerminalIcons }
    $jobs += Start-Job -ScriptBlock { LazyLoad-Zoxide }
    $jobs += Start-Job -ScriptBlock { LazyLoad-Font }
    $jobs += Start-Job -ScriptBlock { LazyLoad-Starship }

    $loadingJob = Start-Job -ScriptBlock { Show-LoadingAnimation }
    Wait-Job -Job $jobs
    Stop-Job -Job $loadingJob
    Remove-Job -Job $loadingJob
    Clear-Host

    Initialize-Prompt
}

# Start deferred loading
Initialize-DeferredLoading
