# Microsoft.PowerShell_profile.ps1

# Set the base path for your PowerShell profile scripts
$basePath = "$HOME\Documents\PowerShell"

# Function to check for command existence
function Test-CommandExists {
    param ($command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
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

# Core utility functions
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

function hb {
    param ($filePath)
    if (-not (Test-Path $filePath)) {
        Write-Error "File path does not exist."
        return
    }
    
    $content = Get-Content $filePath -Raw
    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Write-Output $url
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
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

function gs {
    git status
}

function ga {
    git add .
}

function gc {
    param ($m)
    git commit -m "$m"
}

function gp {
    git push
}

function g {
    z Github
}

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

function pst {
    Get-Clipboard
}

function docs {
    Set-Location -Path $HOME\Documents
}

function dtop {
    Set-Location -Path $HOME\Desktop
}

# System and network functions
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function reload-profile {
    & $profile
}

function unzip ($file) {
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

function sysinfo {
    Get-ComputerInfo
}

function df {
    get-volume
}

function Get-PubIP {
    (Invoke-WebRequest http://ifconfig.me/ip).Content
}

function flushdns {
    Clear-DnsClientCache
}

# Quality of Life Aliases
function k9 { Stop-Process -Name $args[0] }
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }
function gs { git status }
function ga { git add . }
function gc { param ($m) git commit -m "$m" }
function gp { git push }
function g { z Github }
function gcom { git add .; git commit -m "$args" }
function lazyg { git add .; git commit -m "$args"; git push }
function sysinfo { Get-ComputerInfo }
function flushdns { Clear-DnsClientCache }
function cpy { param ($text) Set-Clipboard $text }
function pst { Get-Clipboard }
function docs { Set-Location -Path $HOME\Documents }
function dtop { Set-Location -Path $HOME\Desktop }
function ep { vim $PROFILE }

# Load configuration scripts
. "$basePath/config/theme.ps1"

# Admin check and prompt customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Initialize zoxide
if (Test-CommandExists zoxide) {
    Invoke-Expression (& { (zoxide init pwsh | Out-String) })
}

