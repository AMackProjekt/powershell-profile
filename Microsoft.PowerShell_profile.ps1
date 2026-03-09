# ================================
# MackDavinci God Profile / Divine Edition
# When Vision Meets Word
# ================================

# =========================================================
# A MACK PROJEKT - Cyberpunk Splash
# Drop into profile, then call: Show-AMPStartupSplash
# =========================================================

function Write-Centered {
    param(
        [string]$Text,
        [string]$Color = "Cyan",
        [int]$YOffset = 0
    )

    try {
        $width = $Host.UI.RawUI.WindowSize.Width
        $x = [Math]::Max(0, [int](($width - $Text.Length) / 2))
        $y = [Math]::Max(0, $Host.UI.RawUI.CursorPosition.Y + $YOffset)
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($x, $y)
        Write-Host $Text -ForegroundColor $Color
    } catch {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Show-AMPAsciiFrame {
    param(
        [string[]]$Art,
        [string[]]$Palette
    )

    Clear-Host

    $height = $Host.UI.RawUI.WindowSize.Height
    $width  = $Host.UI.RawUI.WindowSize.Width
    $topPad = [Math]::Max(1, [int](($height - $Art.Count - 8) / 2))

    for ($i = 0; $i -lt $topPad; $i++) {
        Write-Host ""
    }

    for ($i = 0; $i -lt $Art.Count; $i++) {
        $color = $Palette[$i % $Palette.Count]
        Write-Centered -Text $Art[$i] -Color $color
    }

    Write-Host ""
    Write-Centered "████ CYBERPUNK BOOT SEQUENCE INITIALIZING ████" "Magenta"
    Write-Centered "A MACK PROJEKT // SYSTEM READYING..." "Cyan"
    Write-Centered "NEON GRID :: ACTIVE" "Blue"
}

function Show-AMPImagePopup {
    param(
        [string]$ImagePath,
        [int]$Milliseconds = 2200
    )

    if (-not (Test-Path $ImagePath)) {
        return
    }

    try {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase

        $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None"
        ResizeMode="NoResize"
        AllowsTransparency="True"
        Background="Black"
        Topmost="True"
        ShowInTaskbar="False"
        Width="860"
        Height="620"
        WindowStartupLocation="CenterScreen">
    <Grid Background="#020617">
        <Border CornerRadius="18" BorderThickness="2" BorderBrush="#22D3EE" Margin="12">
            <Grid>
                <Image Name="LogoImage" Stretch="Uniform" Margin="20"/>
                <Border Background="#2200FFFF" CornerRadius="18" Margin="12"/>
                <TextBlock Text="A MACK PROJEKT"
                           Foreground="#67E8F9"
                           FontSize="28"
                           FontWeight="Bold"
                           HorizontalAlignment="Center"
                           VerticalAlignment="Bottom"
                           Margin="0,0,0,22"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

        [xml]$xml = $xaml
        $reader = New-Object System.Xml.XmlNodeReader $xml
        $window = [Windows.Markup.XamlReader]::Load($reader)
        $img = $window.FindName("LogoImage")

        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.UriSource = [Uri]::new($ImagePath)
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $img.Source = $bitmap

        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds($Milliseconds)
        $timer.Add_Tick({
            $timer.Stop()
            $window.Close()
        })

        $window.Add_Loaded({
            $timer.Start()
        })

        $null = $window.ShowDialog()
    } catch {
        # Silent fallback
    }
}

function Show-AMPStartupSplash {
    param(
        [string]$LogoPath = "C:\AMP\AMP LOGO.jpeg",
        [switch]$UseImageFirst
    )

    $ascii = @(
'                         /\                                  ',
'                        /  \                                 ',
'                       / /\ \                                ',
'                      / /  \ \                               ',
'                     /_/____\_\                              ',
'                     \ \    / /                              ',
'                      \ \  / /                               ',
'                       \ \/ /                                ',
'                        \  /                                 ',
'                         \/                                  ',
'                                                             ',
'            █████╗     ███╗   ███╗  █████╗   ██████╗  ██╗  ██╗',
'           ██╔══██╗    ████╗ ████║ ██╔══██╗ ██╔════╝ ██║ ██╔╝',
'           ███████║    ██╔████╔██║ ███████║ ██║      █████╔╝ ',
'           ██╔══██║    ██║╚██╔╝██║ ██╔══██║ ██║      ██╔═██╗ ',
'           ██║  ██║    ██║ ╚═╝ ██║ ██║  ██║ ╚██████╗ ██║  ██╗',
'           ╚═╝  ╚═╝    ╚═╝     ╚═╝ ╚═╝  ╚═╝  ╚═════╝ ╚═╝  ╚═╝',
'                                                             ',
'                   ██████╗ ██████╗  ██████╗      ██╗███████╗',
'                   ██╔══██╗██╔══██╗██╔═══██╗     ██║██╔════╝',
'                   ██████╔╝██████╔╝██║   ██║     ██║█████╗  ',
'                   ██╔═══╝ ██╔══██╗██║   ██║██   ██║██╔══╝  ',
'                   ██║     ██║  ██║╚██████╔╝╚█████╔╝███████╗',
'                   ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚══════╝',
'                                                             ',
'                                 ██╗  ██╗████████╗          ',
'                                 ██║ ██╔╝╚══██╔══╝          ',
'                                 █████╔╝    ██║             ',
'                                 ██╔═██╗    ██║             ',
'                                 ██║  ██╗   ██║             ',
'                                 ╚═╝  ╚═╝   ╚═╝             '
    )

    $palettes = @(
        @('Cyan','Blue','Magenta','White'),
        @('Magenta','Cyan','Blue','White'),
        @('Blue','Magenta','Cyan','White'),
        @('White','Cyan','Magenta','Blue'),
        @('DarkCyan','Cyan','Magenta','DarkBlue')
    )

    $bannerLines = @(
        '▓▓▓ BOOTING MACK PROJEKT INTERFACE ▓▓▓',
        '▓▓▓ LOADING GRID ▓▓▓',
        '▓▓▓ CHARGING CYBER CORE ▓▓▓',
        '▓▓▓ AUTH STATUS: ONLINE ▓▓▓'
    )

    $oldTitle = $Host.UI.RawUI.WindowTitle

    try {
        if ($UseImageFirst) {
            Show-AMPImagePopup -ImagePath $LogoPath -Milliseconds 2200
        }

        $frames = 8
        for ($f = 0; $f -lt $frames; $f++) {
            $Host.UI.RawUI.WindowTitle = "A MACK PROJEKT :: CYBERPUNK INIT [$($f+1)/$frames]"
            Show-AMPAsciiFrame -Art $ascii -Palette $palettes[$f % $palettes.Count]

            Write-Host ""
            Write-Centered $bannerLines[$f % $bannerLines.Count] (($palettes[$f % $palettes.Count])[0])
            Start-Sleep -Milliseconds 140
        }

        for ($i = 0; $i -lt 3; $i++) {
            Clear-Host
            Start-Sleep -Milliseconds 70
            Show-AMPAsciiFrame -Art $ascii -Palette @('Magenta','Cyan','White','Blue')
            Write-Host ""
            Write-Centered ">>> JACKING INTO MACK GRID <<<" "Magenta"
            Start-Sleep -Milliseconds 90
        }

        Write-Host ""
        Write-Centered "[OK] Neon shell initialized" "Green"
        Write-Centered "[OK] Visual layer loaded" "Green"
        Write-Centered "[OK] A MACK PROJEKT online" "Green"
        Start-Sleep -Milliseconds 500
        Clear-Host
    }
    finally {
        $Host.UI.RawUI.WindowTitle = $oldTitle
    }
}

# -----------------------------
# CALL THIS ON PROFILE STARTUP
# -----------------------------
Show-AMPStartupSplash -LogoPath "C:\AMP\AMP LOGO.jpeg" -UseImageFirst

# ----------------
# Override toggles
# ----------------
$debug_Override           = $false
$repo_root_Override       = $null
$timeFilePath_Override    = $null
$updateInterval_Override  = $null
$EDITOR_Override          = $null

### PowerShell Profile Refactor
### Version 1.05 - Divine Edition

$debug = if ($null -ne $debug_Override) { [bool]$debug_Override } else { $false }

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                       https://github.com/ChrisTitusTech/powershell-profile.git.                         ############
############                                                                                                         ############
############                      TO ADD YOUR OWN CODE OR OVERRIDES, USE Edit-Profile                                ############
############                                                                                                         ############
#################################################################################################################################

# ----------------
# Core defaults
# ----------------
if ($null -ne $repo_root_Override -and $repo_root_Override -ne '') {
    $repo_root = $repo_root_Override
} else {
    $repo_root = "https://raw.githubusercontent.com/ChrisTitusTech"
}

function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return ([Environment]::GetFolderPath("MyDocuments") + "\PowerShell")
    } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        return ([Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell")
    } else {
        throw "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
    }
}

if ($null -ne $timeFilePath_Override -and $timeFilePath_Override -ne '') {
    $timeFilePath = $timeFilePath_Override
} else {
    $profileDir = Get-ProfileDir
    $timeFilePath = Join-Path $profileDir "LastExecutionTime.txt"
}

if ($null -ne $updateInterval_Override) {
    $updateInterval = [int]$updateInterval_Override
} else {
    $updateInterval = 7
}

function Debug-Message {
    if (Get-Command -Name "Debug-Message_Override" -ErrorAction SilentlyContinue) {
        Debug-Message_Override
    } else {
        Write-Host "#######################################" -ForegroundColor Red
        Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
        Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
        Write-Host "#                                     #" -ForegroundColor Red
        Write-Host "#       IF YOU ARE NOT DEVELOPING     #" -ForegroundColor Red
        Write-Host "#       JUST RUN `Update-Profile`     #" -ForegroundColor Red
        Write-Host "#        to discard all changes       #" -ForegroundColor Red
        Write-Host "#   and update to the latest profile  #" -ForegroundColor Red
        Write-Host "#               version               #" -ForegroundColor Red
        Write-Host "#######################################" -ForegroundColor Red
    }
}

if ($debug) {
    Debug-Message
}

# Opt-out of telemetry before doing anything, only if PowerShell is run as SYSTEM
try {
    if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
        [System.Environment]::SetEnvironmentVariable(
            'POWERSHELL_TELEMETRY_OPTOUT',
            'true',
            [System.EnvironmentVariableTarget]::Machine
        )
    }
} catch {
    Write-Verbose "Unable to set telemetry opt-out: $_"
}

# ----------------
# Connectivity
# ----------------
function Test-GitHubConnection {
    try {
        if ($PSVersionTable.PSEdition -eq "Core") {
            return Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
        } else {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $result = $ping.Send("github.com", 1000)
            return ($result.Status -eq "Success")
        }
    } catch {
        return $false
    }
}
$global:canConnectToGitHub = Test-GitHubConnection

# ----------------
# Modules / External Profiles
# ----------------
try {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
    } else {
        Write-Verbose "Terminal-Icons not installed; skipping import."
    }
} catch {
    Write-Verbose "Terminal-Icons import skipped: $_"
}

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    try {
        Import-Module $ChocolateyProfile -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Chocolatey profile import skipped: $_"
    }
}

# Safely read last execution date
$lastExecRaw = if (Test-Path $timeFilePath) {
    try {
        (Get-Content -Path $timeFilePath -Raw -ErrorAction Stop).Trim()
    } catch {
        $null
    }
} else {
    $null
}

[Nullable[datetime]]$lastExec = $null
if (-not [string]::IsNullOrWhiteSpace($lastExecRaw)) {
    [datetime]$parsed = [datetime]::MinValue
    if ([datetime]::TryParseExact(
        $lastExecRaw,
        'yyyy-MM-dd',
        $null,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$parsed
    )) {
        $lastExec = $parsed
    }
}

# ----------------
# Profile Updating
# ----------------
function Update-Profile {
    if (Get-Command -Name "Update-Profile_Override" -ErrorAction SilentlyContinue) {
        Update-Profile_Override
    } else {
        try {
            if (-not $global:canConnectToGitHub) {
                Write-Verbose "GitHub unreachable; skipping profile update."
                return
            }

            $url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $tempProfile = Join-Path $env:TEMP "Microsoft.PowerShell_profile.ps1"

            if (-not (Test-Path $PROFILE)) {
                New-Item -ItemType File -Path $PROFILE -Force | Out-Null
            }

            $oldhash = Get-FileHash $PROFILE -ErrorAction SilentlyContinue
            Invoke-RestMethod $url -OutFile $tempProfile -ErrorAction Stop
            $newhash = Get-FileHash $tempProfile -ErrorAction Stop

            if ($null -eq $oldhash -or $newhash.Hash -ne $oldhash.Hash) {
                Copy-Item -Path $tempProfile -Destination $PROFILE -Force
                Write-Host "Profile has been updated. Please restart your shell to reflect changes." -ForegroundColor Magenta
            } else {
                Write-Host "Profile is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Verbose "Unable to check for profile updates: $_"
        } finally {
            Remove-Item (Join-Path $env:TEMP "Microsoft.PowerShell_profile.ps1") -ErrorAction SilentlyContinue
        }
    }
}

if (
    -not $debug -and (
        $updateInterval -eq -1 -or
        -not (Test-Path $timeFilePath) -or
        $null -eq $lastExec -or
        ((Get-Date) - $lastExec).TotalDays -gt $updateInterval
    )
) {
    Update-Profile
    try {
        $currentTime = Get-Date -Format 'yyyy-MM-dd'
        $currentTime | Out-File -FilePath $timeFilePath -Force
    } catch {
        Write-Verbose "Unable to write profile execution timestamp: $_"
    }
} elseif ($debug) {
    Write-Warning "Skipping profile update check in debug mode"
}

function Update-PowerShell {
    if (Get-Command -Name "Update-PowerShell_Override" -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override
    } else {
        try {
            if (-not $global:canConnectToGitHub) {
                Write-Verbose "GitHub unreachable; skipping PowerShell update check."
                return
            }

            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Verbose "winget not found; skipping PowerShell update check."
                return
            }

            Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
            $updateNeeded = $false
            $currentVersion = $PSVersionTable.PSVersion.ToString()
            $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
            $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl -ErrorAction Stop
            $latestVersion = $latestReleaseInfo.tag_name.Trim('v')

            if ([version]$currentVersion -lt [version]$latestVersion) {
                $updateNeeded = $true
            }

            if ($updateNeeded) {
                Write-Host "Updating PowerShell..." -ForegroundColor Yellow
                Start-Process powershell.exe `
                    -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" `
                    -Wait -NoNewWindow
                Write-Host "PowerShell has been updated. Please restart your shell to reflect changes." -ForegroundColor Magenta
            } else {
                Write-Host "Your PowerShell is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Verbose "Failed to update PowerShell: $_"
        }
    }
}

if (
    -not $debug -and (
        $updateInterval -eq -1 -or
        -not (Test-Path $timeFilePath) -or
        $null -eq $lastExec -or
        ((Get-Date).Date - $lastExec.Date).TotalDays -gt $updateInterval
    )
) {
    Update-PowerShell
    try {
        $currentTime = Get-Date -Format 'yyyy-MM-dd'
        $currentTime | Out-File -FilePath $timeFilePath -Force
    } catch {
        Write-Verbose "Unable to write PowerShell execution timestamp: $_"
    }
} elseif ($debug) {
    Write-Warning "Skipping PowerShell update in debug mode"
}

function Clear-Cache {
    if (Get-Command -Name "Clear-Cache_Override" -ErrorAction SilentlyContinue) {
        Clear-Cache_Override
    } else {
        Write-Host "Clearing cache..." -ForegroundColor Cyan

        Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
        Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

        Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
        Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Clearing User Temp..." -ForegroundColor Yellow
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Cache clearing completed." -ForegroundColor Green
    }
}

# ----------------
# Admin Check and Prompt
# ----------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function prompt {
    if ($isAdmin) {
        "[" + (Get-Location) + "] # "
    } else {
        "[" + (Get-Location) + "] $ "
    }
}

$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# ----------------
# Utility Functions
# ----------------
function Test-CommandExists {
    param($command)
    return ($null -ne (Get-Command $command -ErrorAction SilentlyContinue))
}

# ----------------
# Editor Configuration
# ----------------
if ($null -ne $EDITOR_Override -and $EDITOR_Override -ne '') {
    $EDITOR = $EDITOR_Override
} else {
    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
    elseif (Test-CommandExists pvim) { 'pvim' }
    elseif (Test-CommandExists vim) { 'vim' }
    elseif (Test-CommandExists vi) { 'vi' }
    elseif (Test-CommandExists code) { 'code' }
    elseif (Test-CommandExists codium) { 'codium' }
    elseif (Test-CommandExists 'notepad++') { 'notepad++' }
    elseif (Test-CommandExists sublime_text) { 'sublime_text' }
    else { 'notepad' }

    Set-Alias -Name vim -Value $EDITOR -ErrorAction SilentlyContinue
}

function Edit-Profile {
    & $EDITOR $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

function Invoke-Profile {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Write-Host "Note: Some Oh My Posh/PSReadLine limitations may appear in Windows PowerShell 5.1." -ForegroundColor Yellow
    }
    & $PROFILE
}

function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output $_.FullName
    }
}

# ----------------
# Network Utilities
# ----------------
function pubip {
    try {
        (Invoke-WebRequest http://ifconfig.me/ip -UseBasicParsing -ErrorAction Stop).Content
    } catch {
        Write-Error "Unable to retrieve public IP: $_"
    }
}

# ----------------
# WinUtil
# ----------------
function winutil {
    try {
        Invoke-Expression (Invoke-RestMethod https://christitus.com/win)
    } catch {
        Write-Error "Failed to launch winutil: $_"
    }
}

function winutildev {
    if (Get-Command -Name "WinUtilDev_Override" -ErrorAction SilentlyContinue) {
        WinUtilDev_Override
    } else {
        try {
            Invoke-Expression (Invoke-RestMethod https://christitus.com/windev)
        } catch {
            Write-Error "Failed to launch winutildev: $_"
        }
    }
}

# ----------------
# System Utilities
# ----------------
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb RunAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb RunAs
    }
}
Set-Alias -Name su -Value admin

function uptime {
    try {
        $dateFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern
        $timeFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern

        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)
            $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
        } else {
            $bootTime = Get-Uptime -Since
            $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
        }

        $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
        Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray

        $uptime = (Get-Date) - $bootTime
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds) -ForegroundColor Blue
    } catch {
        Write-Error "An error occurred while retrieving system uptime."
    }
}

function unzip($file) {
    Write-Output ("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd -Force
}

function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }

    $FilePath = $args[0]

    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }

    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Set-Clipboard $url
        Write-Output "$url copied to clipboard."
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}

function grep($regex, $dir) {
    if ($dir) {
        Get-ChildItem $dir | Select-String $regex
        return
    }
    $input | Select-String $regex
}

function df { Get-Volume }

function sed($file, $find, $replace) {
    (Get-Content $file).Replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    Set-Item -Force -Path "env:$name" -Value $value
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name -ErrorAction SilentlyContinue
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

function nf { param($name) New-Item -ItemType File -Path . -Name $name }

function mkcd {
    param($dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

function trash($path) {
    try {
        $fullPath = (Resolve-Path -Path $path -ErrorAction Stop).Path

        if (Test-Path $fullPath) {
            $item = Get-Item $fullPath

            if ($item.PSIsContainer) {
                $parentPath = $item.Parent.FullName
            } else {
                $parentPath = $item.DirectoryName
            }

            $shell = New-Object -ComObject 'Shell.Application'
            $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

            if ($shellItem) {
                $shellItem.InvokeVerb('delete')
                Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
            } else {
                Write-Host "Error: Could not find the item '$fullPath' to trash."
            }
        } else {
            Write-Host "Error: Item '$fullPath' does not exist."
        }
    } catch {
        Write-Host "Error: $_"
    }
}

# ----------------
# Quality of Life Aliases
# ----------------
function docs {
    $docs = if ([Environment]::GetFolderPath("MyDocuments")) {
        [Environment]::GetFolderPath("MyDocuments")
    } else {
        "$HOME\Documents"
    }
    Set-Location -Path $docs
}

function dtop {
    $dtop = if ([Environment]::GetFolderPath("Desktop")) {
        [Environment]::GetFolderPath("Desktop")
    } else {
        "$HOME\Documents"
    }
    Set-Location -Path $dtop
}

function k9 { Stop-Process -Name $args[0] -ErrorAction SilentlyContinue }

function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

# ----------------
# Git Shortcuts
# ----------------
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gpush { git push }
function gpull { git pull }

function g {
    if (Get-Command __zoxide_z -ErrorAction SilentlyContinue) {
        __zoxide_z github
    } else {
        Write-Host "zoxide is not available." -ForegroundColor Yellow
    }
}

function gcl { git clone "$args" }

function gcom {
    git add .
    git commit -m "$args"
}

function lazyg {
    git add .
    git commit -m "$args"
    git push
}

function sysinfo { Get-ComputerInfo }

function flushdns {
    Clear-DnsClientCache
    Write-Host "DNS has been flushed"
}

function cpy { Set-Clipboard $args[0] }
function pst { Get-Clipboard }

# ----------------
# PSReadLine Compatibility
# ----------------
function Set-PSReadLineOptionsCompat {
    param([hashtable]$Options)

    if (-not (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)) {
        return
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
        Set-PSReadLineOption @Options
    } else {
        $SafeOptions = $Options.Clone()
        $SafeOptions.Remove('PredictionSource')
        $SafeOptions.Remove('PredictionViewStyle')
        Set-PSReadLineOption @SafeOptions
    }
}

if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    $PSReadLineOptions = @{
        EditMode = 'Windows'
        HistoryNoDuplicates = $true
        HistorySearchCursorMovesToEnd = $true
        Colors = @{
            Command   = '#87CEEB'
            Parameter = '#98FB98'
            Operator  = '#FFB6C1'
            Variable  = '#DDA0DD'
            String    = '#FFDAB9'
            Number    = '#B0E0E6'
            Type      = '#F0E68C'
            Comment   = '#D3D3D3'
            Keyword   = '#8367c7'
            Error     = '#FF6347'
        }
        PredictionSource = 'History'
        PredictionViewStyle = 'ListView'
        BellStyle = 'None'
    }

    Set-PSReadLineOptionsCompat -Options $PSReadLineOptions

    if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
        Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
        Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
        Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
    }

    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match $_ }
        return ($null -eq $hasSensitive)
    }
}

function Set-PredictionSource {
    if (Get-Command -Name "Set-PredictionSource_Override" -ErrorAction SilentlyContinue) {
        Set-PredictionSource_Override
    } elseif (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
        if ($PSVersionTable.PSEdition -eq "Core") {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
            Set-PSReadLineOption -MaximumHistoryCount 10000 -ErrorAction SilentlyContinue
        } else {
            Set-PSReadLineOption -MaximumHistoryCount 10000 -ErrorAction SilentlyContinue
        }
    }
}
Set-PredictionSource

# ----------------
# Argument Completion
# ----------------
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $customCompletions = @{
        'git'    = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
        'npm'    = @('install', 'start', 'run', 'test', 'build')
        'deno'   = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
}
Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock $scriptblock

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $scriptblock = {
        param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition $commandAst.ToString() |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock
}

# ----------------
# Theme Initialization
# ----------------
if (Get-Command -Name "Get-Theme_Override" -ErrorAction SilentlyContinue) {
    Get-Theme_Override
} else {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        $localThemePath = Join-Path (Get-ProfileDir) "cobalt2.omp.json"

        if (-not (Test-Path $localThemePath) -and $global:canConnectToGitHub) {
            $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
            try {
                Invoke-RestMethod -Uri $themeUrl -OutFile $localThemePath -ErrorAction Stop
                Write-Host "Downloaded missing Oh My Posh theme to $localThemePath"
            } catch {
                Write-Verbose "Failed to download theme file. Falling back skipped: $_"
            }
        }

        try {
            if (Test-Path $localThemePath) {
                oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
            }
        } catch {
            Write-Verbose "Oh My Posh init skipped: $_"
        }
    } else {
        Write-Verbose "Oh My Posh not installed; skipping theme init."
    }
}

# ----------------
# zoxide
# ----------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } catch {
        Write-Verbose "zoxide init skipped: $_"
    }
} else {
    Write-Verbose "zoxide not installed; skipping init."
}

# ----------------
# Help
# ----------------
function Show-Help {
    $usePSStyle = $null -ne (Get-Variable PSStyle -ErrorAction SilentlyContinue)

    if ($usePSStyle) {
        $cCyan    = $PSStyle.Foreground.Cyan
        $cYellow  = $PSStyle.Foreground.Yellow
        $cGreen   = $PSStyle.Foreground.Green
        $cMagenta = $PSStyle.Foreground.Magenta
        $cReset   = $PSStyle.Reset
    } else {
        $cCyan = ''
        $cYellow = ''
        $cGreen = ''
        $cMagenta = ''
        $cReset = ''
    }

    $helpText = @"
${cCyan}PowerShell Profile Help${cReset}
${cYellow}=======================${cReset}
${cGreen}Edit-Profile${cReset} - Opens the current user's profile for editing using the configured editor.
${cGreen}Update-Profile${cReset} - Checks for profile updates from a remote repository and updates if necessary.
${cGreen}Update-PowerShell${cReset} - Checks for the latest PowerShell release and updates if a new version is available.

${cCyan}Git Shortcuts${cReset}
${cYellow}=======================${cReset}
${cGreen}g${cReset} - Changes to the GitHub directory.
${cGreen}ga${cReset} - Shortcut for 'git add .'.
${cGreen}gc${cReset} <message> - Shortcut for 'git commit -m'.
${cGreen}gcl${cReset} <repo> - Shortcut for 'git clone'.
${cGreen}gcom${cReset} <message> - Adds all changes and commits with the specified message.
${cGreen}gpull${cReset} - Shortcut for 'git pull'.
${cGreen}gpush${cReset} - Shortcut for 'git push'.
${cGreen}gs${cReset} - Shortcut for 'git status'.

${cCyan}Shortcuts${cReset}
${cYellow}=======================${cReset}
${cGreen}cpy${cReset} <text> - Copies the specified text to the clipboard.
${cGreen}df${cReset} - Displays information about volumes.
${cGreen}docs${cReset} - Changes the current directory to the user's Documents folder.
${cGreen}dtop${cReset} - Changes the current directory to the user's Desktop folder.
${cGreen}ep${cReset} - Opens the profile for editing.
${cGreen}export${cReset} <name> <value> - Sets an environment variable.
${cGreen}ff${cReset} <name> - Finds files recursively with the specified name.
${cGreen}flushdns${cReset} - Clears the DNS cache.
${cGreen}pubip${cReset} - Retrieves the public IP address of the machine.
${cGreen}grep${cReset} <regex> [dir] - Searches for a regex pattern.
${cGreen}hb${cReset} <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.
${cGreen}head${cReset} <path> [n] - Displays the first n lines of a file.
${cGreen}k9${cReset} <name> - Kills a process by name.
${cGreen}la${cReset} - Lists all files in the current directory.
${cGreen}ll${cReset} - Lists all files, including hidden, in the current directory.
${cGreen}mkcd${cReset} <dir> - Creates and changes to a new directory.
${cGreen}nf${cReset} <name> - Creates a new file with the specified name.
${cGreen}pgrep${cReset} <name> - Lists processes by name.
${cGreen}pkill${cReset} <name> - Kills processes by name.
${cGreen}pst${cReset} - Retrieves text from the clipboard.
${cGreen}sed${cReset} <file> <find> <replace> - Replaces text in a file.
${cGreen}sysinfo${cReset} - Displays detailed system information.
${cGreen}tail${cReset} <path> [n] - Displays the last n lines of a file.
${cGreen}touch${cReset} <file> - Creates a new empty file.
${cGreen}unzip${cReset} <file> - Extracts a zip file to the current directory.
${cGreen}uptime${cReset} - Displays the system uptime.
${cGreen}which${cReset} <name> - Shows the path of the command.
${cGreen}winutil${cReset} - Runs the latest WinUtil full-release script.
${cGreen}winutildev${cReset} - Runs the latest WinUtil pre-release script.

Use '${cMagenta}Show-Help${cReset}' to display this help message.
"@
    Write-Host $helpText
}

if (Test-Path "$PSScriptRoot\CTTcustom.ps1") {
    try {
        Invoke-Expression -Command "& `"$PSScriptRoot\CTTcustom.ps1`""
    } catch {
        Write-Verbose "CTTcustom.ps1 failed to load: $_"
    }
}

try {
    if ($null -ne (Get-Variable PSStyle -ErrorAction SilentlyContinue)) {
        Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"
    } else {
        Write-Host "Use 'Show-Help' to display help" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Use 'Show-Help' to display help" -ForegroundColor Yellow
}
