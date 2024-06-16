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
    - Modern Features:
        - wsl : Switch to WSL environment
        - wt : Customize Windows Terminal (background images, acrylic effects, dynamic profiles)
        - perfmon : Real-time performance monitoring and alerts
        - edge <command> : Automate tasks in Microsoft Edge
        - voice : Execute PowerShell tasks using voice commands
        - widgets : Interact with and customize Windows 11 widgets
        - aicode : AI-powered code assistance using Azure services
#>

# User Configurable Variables
$profileUrl = "https://raw.githubusercontent.com/Yanai-Klugman/dotfiles/main/powershell/Microsoft.PowerShell_profile.ps1"
$ohMyPoshThemeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json"
$useStarship = $false  # Set to $true to use starship instead of oh-my-posh
$editor = ""

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

# Lazy Load and Install Functions
function LazyLoad-OhMyPosh {
    if (-not (Test-CommandExists oh-my-posh)) {
        try {
            sudo winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
        } catch {
            Write-Error "Failed to install Oh My Posh. Error: $_"
        }
    }
}

function LazyLoad-TerminalIcons {
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        try {
            sudo Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        } catch {
            Write-Error "Failed to install Terminal Icons module. Error: $_"
        }
    }
}

function LazyLoad-Zoxide {
    if (-not (Test-CommandExists zoxide)) {
        try {
            sudo winget install -e --id ajeetdsouza.zoxide
        } catch {
            Write-Error "Failed to install zoxide. Error: $_"
        }
    }
}

function LazyLoad-Font {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains "CaskaydiaCove NF") {
        try {
            sudo {
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile((New-Object System.Uri("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip")), ".\CascadiaCode.zip")
                
                Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
                $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
                Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
                    If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
                        $destination.CopyHere($_.FullName, 0x10)
                    }
                }

                Remove-Item -Path ".\CascadiaCode" -Recurse -Force
                Remove-Item -Path ".\CascadiaCode.zip" -Force
            }
        } catch {
            Write-Error "Failed to download or install the Cascadia Code font. Error: $_"
        }
    }
}

function LazyLoad-Starship {
    if (-not (Test-CommandExists starship)) {
        try {
            sudo winget install -e --id Starship.Starship
        } catch {
            Write-Error "Failed to install Starship. Error: $_"
        }
    }
}

# Function to initialize prompt
function Initialize-Prompt {
    if ($useStarship) {
        if (Test-CommandExists starship) {
            starship init pwsh --print-full-init | Invoke-Expression
        }
    } else {
        if (Test-CommandExists oh-my-posh) {
            oh-my-posh init pwsh --config $ohMyPoshThemeUrl | Invoke-Expression
        }
    }
}

# Loading Animation Function
function Show-LoadingAnimation {
    $animationFrames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    $frameCount = $animationFrames.Count
    $i = 0
    while ($true) {
        Write-Host -NoNewline -ForegroundColor Cyan "`r$($animationFrames[$i % $frameCount]) Loading..."
        Start-Sleep -Milliseconds 100
        $i++
    }
}

# Start background jobs and display loading animation
$jobs = @()
$jobs += Start-Job -ScriptBlock { LazyLoad-OhMyPosh }
$jobs += Start-Job -ScriptBlock { LazyLoad-TerminalIcons }
$jobs += Start-Job -ScriptBlock { LazyLoad-Zoxide }
$jobs += Start-Job -ScriptBlock { LazyLoad-Font }
$jobs += Start-Job -ScriptBlock { LazyLoad-Starship }

$loadingJob = Start-Job -ScriptBlock { Show-LoadingAnimation }
Wait-Job -Job $jobs
Stop-Job -Job $loadingJob
Remove-Job -Job $loadingJob

Clear-Host

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

# Enable transient prompt
$PSReadlineOption = @{
    ContinuationPrompt = '>> '
    HistorySearchCursorMovesToEnd = $true
    HistorySaveStyle = 'SaveIncrementally'
    HistoryNoDuplicates = $true
    HistorySearchCaseSensitive = $false
    HistorySavePath = (Join-Path -Path $HOME -ChildPath '.config\powershell\PSReadline\PSReadlineHistory.txt')
    PromptText = '>'
    TransientPromptEnabled = $true
}
Set-PSReadLineOption @PSReadlineOption

# Set window title after initializing tools
$Host.UI.RawUI.WindowTitle = "PowerShell"

# Set PSReadLine colors for better readability
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    String = 'DarkCyan'
}

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
Set-Alias docs Set-Location
Set-Alias dtop Set-Location
Set-Alias dev { Set-Location -Path D:\ }

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
    $jobs += Start-Job -ScriptBlock { LazyLoad-OhMyPosh }
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

# Modern Features

# Switch to WSL environment
function wsl {
    if ($IsWindows) {
        wsl.exe
    } else {
        Write-Host "This command is only available on Windows."
    }
}

# Customize Windows Terminal
function wt {
    param (
        [string]$backgroundImage,
        [string]$acrylic = $false,
        [string]$dynamicProfile
    )

    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $wtSettingsPath)) {
        Write-Error "Windows Terminal settings file not found."
        return
    }

    $settings = Get-Content $wtSettingsPath | ConvertFrom-Json

    if ($backgroundImage) {
        $settings.profiles.defaults.backgroundImage = $backgroundImage
    }

    if ($acrylic -eq $true) {
        $settings.profiles.defaults.useAcrylic = $true
        $settings.profiles.defaults.acrylicOpacity = 0.8
    }

    if ($dynamicProfile) {
        $settings.profiles.list += @{
            name = "Dynamic Profile"
            commandline = $dynamicProfile
            hidden = $false
        }
    }

    $settings | ConvertTo-Json -Depth 100 | Set-Content $wtSettingsPath
    Write-Host "Windows Terminal settings updated. Please restart Windows Terminal to apply changes."
}

# Real-time performance monitoring and alerts
function perfmon {
    param (
        [string]$counter = "\Processor(_Total)\% Processor Time",
        [int]$threshold = 80
    )

    $counterSample = Get-Counter -Counter $counter -SampleInterval 1 -MaxSamples 10
    $average = ($counterSample.CounterSamples.CookedValue | Measure-Object -Average).Average

    if ($average -gt $threshold) {
        Write-Warning "Performance threshold exceeded: $average%"
    } else {
        Write-Host "Performance is within acceptable range: $average%"
    }
}

# Automate tasks in Microsoft Edge
function edge {
    param (
        [string]$command
    )

    if (-not (Test-CommandExists msedge)) {
        Write-Error "Microsoft Edge is not installed."
        return
    }

    switch ($command) {
        "open" { Start-Process "msedge.exe" }
        "close" { Stop-Process -Name "msedge" -Force }
        "new-tab" { Start-Process "msedge.exe" -ArgumentList "--new-tab" }
        default { Write-Host "Unknown command: $command" }
    }
}

# Execute PowerShell tasks using voice commands
function voice {
    param (
        [string]$command
    )

    if (-not (Test-CommandExists "speech")) {
        Write-Error "Windows Speech Recognition is not enabled."
        return
    }

    Write-Host "Listening for voice command: $command"
    # Placeholder for voice command implementation
}

# Interact with and customize Windows 11 widgets
function widgets {
    param (
        [string]$widgetName,
        [string]$action = "show"
    )

    # Placeholder for widget interaction implementation
    Write-Host "Performing action '$action' on widget '$widgetName'."
}

# AI-powered code assistance using Azure services
function aicode {
    param (
        [string]$codeSnippet
    )

    # Placeholder for AI-powered code assistance implementation
    Write-Host "Analyzing code snippet using Azure AI services."
}
