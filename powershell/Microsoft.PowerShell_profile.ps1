# Set the base path for your PowerShell profile scripts
$basePath = "$HOME\Documents\PowerShell"
$PSScriptRoot = "$HOME\Documents\PowerShell"

# Lazy loading modules
function Load-Environment {
    . "$basePath/config/environment.ps1"
    Remove-Item -Path function:Load-Environment
}
function Load-Utilities {
    . "$basePath/functions/core.ps1"
    Remove-Item -Path function:Load-Utilities
}
function Load-Editor {
    . "$basePath/functions/editor.ps1"
    Remove-Item -Path function:Load-Editor
}
function Load-SystemNetwork {
    . "$basePath/functions/system_network.ps1"
    Remove-Item -Path function:Load-SystemNetwork
}

# Load configuration scripts
. "$basePath/config/update.ps1"
. "$basePath/config/theme.ps1"

# Set up admin check and prompt customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Configure lazy loading
function vim { Load-Editor; vim $args }
function touch { Load-Utilities; touch $args }
function ff { Load-Utilities; ff $args }
function Get-PubIP { Load-SystemNetwork; Get-PubIP $args }
function uptime { Load-SystemNetwork; uptime $args }
function reload-profile { Load-SystemNetwork; reload-profile $args }
function unzip { Load-SystemNetwork; unzip $args }
function hb { Load-Utilities; hb $args }
function grep { Load-Utilities; grep $args }
function df { Load-SystemNetwork; df $args }
function sed { Load-Utilities; sed $args }
function which { Load-Utilities; which $args }
function export { Load-Utilities; export $args }
function pkill { Load-SystemNetwork; pkill $args }
function pgrep { Load-SystemNetwork; pgrep $args }
function head { Load-Utilities; head $args }
function tail { Load-Utilities; tail $args }
function nf { Load-SystemNetwork; nf $args }
function mkcd { Load-SystemNetwork; mkcd $args }

# Quality of Life Aliases
function docs { Load-Utilities; docs $args }
function dtop { Load-Utilities; dtop $args }
function ep { Load-Editor; ep $args }
function k9 { Load-SystemNetwork; k9 $args }
function la { Load-Utilities; la $args }
function ll { Load-Utilities; ll $args }
function gs { Load-Utilities; gs $args }
function ga { Load-Utilities; ga $args }
function gc { Load-Utilities; gc $args }
function gp { Load-Utilities; gp $args }
function g { Load-Utilities; g $args }
function gcom { Load-Utilities; gcom $args }
function lazyg { Load-Utilities; lazyg $args }
function sysinfo { Load-SystemNetwork; sysinfo $args }
function flushdns { Load-SystemNetwork; flushdns $args }
function cpy { Load-Utilities; cpy $args }
function pst { Load-Utilities; pst $args }

