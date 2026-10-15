# Supreme PowerShell Profile — AMackProjekt

**MasterMack 6.1 | MACKPROJEKT-COMMANDCENTER**

A MackProjekt PowerShell environment for Windows Terminal and PowerShell 7+, with a command profile, system diagnostics, and optional developer/productivity integrations.

## One-line IRM install

Review the installer before executing remote code. Preview locally first:

```powershell
$setup = irm 'https://raw.githubusercontent.com/AMackProjekt/powershell-profile/main/setup.ps1'
$setup | Set-Content "$env:TEMP\AMP-setup-review.ps1"
notepad "$env:TEMP\AMP-setup-review.ps1"
```

After reviewing, run:

```powershell
irm 'https://raw.githubusercontent.com/AMackProjekt/powershell-profile/main/setup.ps1' | iex
```

The installer downloads the MasterMack profile from this repository, validates its PowerShell syntax, backs up an existing profile, then deploys it. It installs optional PowerShell Gallery modules in CurrentUser scope and checks selected winget tools. Run elevated only when a particular package or system-level action requires it.

## Installer options

When running a local clone:

```powershell
.\setup.ps1 -WhatIf
.\setup.ps1 -SkipTools
.\setup.ps1 -SkipModules
.\setup.ps1 -SkipProfile
```

- `-WhatIf`: show intended changes without deploying the profile or installing tools/modules.
- `-SkipTools`: skip winget tools and Nerd Font setup.
- `-SkipModules`: skip PowerShell Gallery modules.
- `-SkipProfile`: skip profile deployment.

## Repository layout

- `Microsoft.PowerShell_profile.ps1`: stable/default profile entry.
- `profiles/MasterMack-6.1-DISPLAY.ps1`: MasterMack 6.1 profile source.
- `setup.ps1`: installer, backup, parser validation, and optional dependencies.
- `install.ps1`: IRM/bootstrap documentation helper.
- `setprofile.ps1`: local profile deployment helper.

## Optional dependencies

Tools checked/installed with winget: Oh My Posh, zoxide, Fastfetch, Git, and PowerShell 7.

PowerShell Gallery modules: Terminal-Icons, PSReadLine, posh-git, and Pester.

Package availability varies by Windows build, PowerShell edition, repository policy, and network access. Review warnings and confirm each dependency installed successfully.

## Updating and backups

Run the reviewed IRM installer again to get the current default-branch profile and installer. Existing profiles are backed up under:

`$HOME\.mackprojekt\backups\powershell-profile`

Keep personal customizations in a separate customization file or your own branch, because deploying an update replaces the active profile after backing it up.

## Safety

- Inspect remote scripts before piping them to `iex`.
- Never commit secrets, tokens, or private machine details to this public repository.
- Review administrative utilities before running cleanup, network-reset, process-termination, or other high-impact commands.
- Keep profile startup behavior predictable; package installation and system modifications belong in the installer, not the shell startup profile.

## Repository

[AMackProjekt/powershell-profile](https://github.com/AMackProjekt/powershell-profile)
