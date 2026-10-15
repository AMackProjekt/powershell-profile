#requires -Version 5.1
<#
.SYNOPSIS
    Installs the AMackProjekt Supreme PowerShell Profile / MasterMack 6.1.
.DESCRIPTION
    Backs up the current profile, validates downloaded profile syntax, and
    installs optional tools and modules. Elevation is not required by default.
#>
[CmdletBinding()]
param(
    [switch]$SkipTools,
    [switch]$SkipModules,
    [switch]$SkipProfile,
    [switch]$WhatIf,
    [string]$RepositoryRef = 'main'
)
$ErrorActionPreference = 'Stop'
$RepoRaw = "https://raw.githubusercontent.com/AMackProjekt/powershell-profile/$RepositoryRef"
$ProfileUri = "$RepoRaw/profiles/MasterMack-6.1-DISPLAY.ps1"
$ProfilePath = $PROFILE.CurrentUserCurrentHost
$ProfileDir = Split-Path -Parent $ProfilePath
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $HOME '.mackprojekt\backups\powershell-profile'
$TempProfile = Join-Path $env:TEMP "MasterMack-6.1-$Stamp.ps1"

function Write-Step([string]$Message) { Write-Host "[AMP] $Message" -ForegroundColor Cyan }
function Test-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Install-WingetPackage([string]$Id) {
    if (-not (Test-Command 'winget')) { Write-Warning "winget unavailable; skipped $Id."; return }
    Write-Step "Checking/installing $Id"
    winget install --id $Id --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { Write-Warning "winget returned exit code $LASTEXITCODE for $Id (it may already be installed or unavailable)." }
}

Write-Step "PowerShell: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
Write-Step "Target profile: $ProfilePath"
if (-not $SkipProfile) {
    Write-Step 'Downloading the MasterMack profile.'
    Invoke-WebRequest -Uri $ProfileUri -OutFile $TempProfile -UseBasicParsing
    $tokens = $null; $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($TempProfile, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -gt 0) {
        $parseErrors | ForEach-Object { Write-Error ("Parse error line {0}: {1}" -f $_.Extent.StartLineNumber, $_.Message) }
        throw 'Profile failed syntax validation. Existing profile was not changed.'
    }
    if ($WhatIf) {
        Write-Host "WHATIF: would back up existing profile and deploy validated profile to $ProfilePath"
    } else {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        if (Test-Path -LiteralPath $ProfilePath) {
            $backup = Join-Path $BackupDir "Microsoft.PowerShell_profile-$Stamp.ps1"
            Copy-Item -LiteralPath $ProfilePath -Destination $backup
            Write-Host "Backed up current profile: $backup" -ForegroundColor Yellow
        }
        Copy-Item -LiteralPath $TempProfile -Destination $ProfilePath -Force
        Unblock-File -LiteralPath $ProfilePath -ErrorAction SilentlyContinue
        Write-Host 'MasterMack profile installed and syntax-validated.' -ForegroundColor Green
    }
}
if (-not $SkipModules) {
    try { if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) { Register-PSRepository -Default -ErrorAction SilentlyContinue } } catch {}
    foreach ($module in @('Terminal-Icons','PSReadLine','posh-git','Pester')) {
        try {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                if ($WhatIf) { Write-Host "WHATIF: would install module $module" }
                else {
                    Install-Module -Name $module -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
                    Write-Host "Installed module: $module" -ForegroundColor Green
                }
            } else { Write-Host "Module available: $module" -ForegroundColor DarkGreen }
        } catch { Write-Warning "Module '$module' could not be installed: $($_.Exception.Message)" }
    }
}
if (-not $SkipTools) {
    foreach ($package in @('JanDeDobbeleer.OhMyPosh','ajeetdsouza.zoxide','Fastfetch-cli.Fastfetch','Git.Git','Microsoft.PowerShell')) {
        if ($WhatIf) { Write-Host "WHATIF: would check/install $package" }
        else { Install-WingetPackage -Id $package }
    }
    if ((Test-Command 'oh-my-posh') -and -not $WhatIf) {
        try { oh-my-posh font install meslo } catch { Write-Warning "Nerd Font setup skipped: $($_.Exception.Message)" }
    }
}
Remove-Item -LiteralPath $TempProfile -Force -ErrorAction SilentlyContinue
Write-Host ''
Write-Host 'Supreme PowerShell Profile setup finished. Restart PowerShell to load it.' -ForegroundColor Green
