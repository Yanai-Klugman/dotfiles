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
#>

# Function to check for command existence
function Test-CommandExists {
    param ($command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Function to ensure the script is running with elevated privileges
function Ensure-Admin {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Administrator privileges are required for some actions. Please run this script with 'sudo'!"
        exit
    }
}

# Function to sync profile from GitHub
function Sync-Profile {
    $profileUrl = "https://raw.githubusercontent.com/Yanai-Klugman/dotfiles/main/powershell/Microsoft.PowerShell_profile.ps1"
    $localProfile = $PROFILE
    try {
        $remoteContent = Invoke-RestMethod -Uri $profileUrl -ErrorAction Stop
        if (Test-Path -Path $localProfile -PathType Leaf) {
            $localContent = Get-Content -Path $localProfile -Raw
            if ($remoteContent -ne $localContent) {
                $remoteContent | Set-Content -Path $localProfile -Force
                Write-Host "Profile has been synced with the latest version from GitHub."
                Write-Host "Please restart your PowerShell session to apply the changes."
            }
        } else {
            $remoteContent | Set-Content -Path $localProfile -Force
            Write-Host "Profile has been created with the latest version from GitHub."
            Write-Host "Please restart your PowerShell session to apply the changes."
        }
    } catch {
        Write-Warning "Failed to sync profile from GitHub. Error: $_"
    }
}

# Function to set editor alias
function Set-EditorAlias {
    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
              elseif (Test-CommandExists pvim) { 'pvim' }
              elseif (Test-CommandExists vim) { 'vim' }
              elseif (Test-CommandExists vi) { 'vi' }
              elseif (Test-CommandExists code) { 'code' }
              elseif (Test-CommandExists notepad++) { 'notepad++' }
              elseif (Test-CommandExists sublime_text) { 'sublime_text' }
              else { 'notepad' }
    Set-Alias -Name vim -Value $EDITOR
}

# Editor Configuration
Set-EditorAlias

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

function ep { vim $PROFILE }

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
