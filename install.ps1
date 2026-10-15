# AMP IRM bootstrap helper
# Recommended: inspect the remote installer before executing it.
# $setup = irm 'https://raw.githubusercontent.com/AMackProjekt/powershell-profile/main/setup.ps1'
# $setup | Set-Content "$env:TEMP\AMP-setup-review.ps1"
# notepad "$env:TEMP\AMP-setup-review.ps1"
# After review:
# irm 'https://raw.githubusercontent.com/AMackProjekt/powershell-profile/main/setup.ps1' | iex
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Write-Host 'AMP installer endpoint:' -ForegroundColor Cyan
Write-Host 'https://raw.githubusercontent.com/AMackProjekt/powershell-profile/main/setup.ps1'
Write-Host 'Review setup.ps1 before executing remote code. See README.md for the IRM workflow.' -ForegroundColor Yellow
