# -------------------------------------------------------------------

# MACKPROJEKT-COMMANDCENTER :: MasterMack PowerShell Profile

# MasterMack PowerShell Profile 6.1 (MACKPROJEKT-COMMANDCENTER edition)

# -------------------------------------------------------------------

$global:debug_Override            = $null

$global:repo_root_Override        = $null

$global:timeFilePath_Override     = $null

$global:updateInterval_Override   = $null

$global:EDITOR_Override           = $null

$script:repo_root        = "C:\AdminOps"

$script:timeFilePath     = "C:\AdminOps\Logs\\.profile_last_run.txt"

$script:updateInterval   = 1440

$script:OpsPath          = "C:\AdminOps"

$script:ToolsPath        = "C:\AdminOps\Tools"

Set-StrictMode -Version Latest

$ErrorActionPreference = "Continue"

$Global:MackProfileMeta = @{

    Author        = "Donyale Mack"

    Version       = [version]"6.1"

    Organization  = "Mack Studio Enterprises"

    Environment   = "MACKPROJEKT-COMMANDCENTER"

    Mode          = "CommandCenter"

    ProfilePath   = $PROFILE

    HashFile      = "$PROFILE.hash.txt"

    Symlink       = "C:\MackGodModeLink.ps1"

}


function Test-IsAdmin {

    $current = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = New-Object Security.Principal.WindowsPrincipal($current)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

}

function Ensure-Elevated {

    param([string]$Purpose = "This action", [switch]$Relaunch)

    if (Test-IsAdmin) { return $true }

    Write-Host ""

    Write-Host "[!] Elevation required: $Purpose" -ForegroundColor Yellow

    if ($Relaunch) { Start-Process -FilePath "pwsh.exe" -Verb RunAs }

    return $false

}

function Write-Section([string]$Title) {

    Write-Host ""

    Write-Host ("=" * 78) -ForegroundColor DarkGray

    Write-Host $Title -ForegroundColor Cyan

    Write-Host ("=" * 78) -ForegroundColor DarkGray

}

$script:AdminOpsLogRoot = Join-Path $env:ProgramData "MackStudio\EnterpriseAdminDevice"

$script:AdminOpsLogFile = Join-Path $script:AdminOpsLogRoot ("AdminOpsMode_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

try {

    New-Item -Path $script:AdminOpsLogRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null

} catch {

    $script:AdminOpsLogRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) "MackStudio\EnterpriseAdminDevice"

    $script:AdminOpsLogFile = Join-Path $script:AdminOpsLogRoot ("AdminOpsMode_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

    New-Item -Path $script:AdminOpsLogRoot -ItemType Directory -Force | Out-Null

}

function Write-MackLog([string]$Message) {

    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message

    Add-Content -LiteralPath $script:AdminOpsLogFile -Value $line -Encoding utf8

}

# ===================================================================

# MAXIMUM SYSTEM CONTROLS & RECLAIM LAYER

# ===================================================================

function Invoke-SafeDriveCleanup {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param()

    <#

*    .SYNOPSIS*

*        Aggressively purges multi-gigabyte system-generated trash, delivery*

*        optimization stores, windows error reports, and user-space cache nests.*

*    #>*

    if (-not (Test-IsAdmin)) { Write-Warning "Administrative elevation required for deep system cleanup."; return }

    Write-Section "Executing Safe System Drive Cleanup (C:)"

    $StartSpace = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace

    Write-Host "[*] Triggering silent Windows Native Storage Cleanmgr..." -ForegroundColor Cyan

    $null = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -Wait

    $JunkTargets = @(

        "$env:windir\Temp", "$env:LOCALAPPDATA\Temp",

        "$env:ProgramData\Microsoft\Windows\WER",

        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\Cache_Data",

        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data"

    )

    foreach ($Path in $JunkTargets) {

        if ((Test-Path -LiteralPath $Path) -and $PSCmdlet.ShouldProcess($Path, 'Remove cache contents')) {

            Write-Host "[*] Flushing allocations from: $Path" -ForegroundColor DarkGray

            Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |

                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

        }

    }

    $EndSpace = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace

    $SpaceSaved = [Math]::Round(($EndSpace - $StartSpace) / 1GB, 2)

    Write-Section "Cleanup Complete: Instantly Recovered $SpaceSaved GB on C:"

}

function Invoke-Sledgehammer {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    param([Parameter(Mandatory)][string]$ProcessName)

    if (-not (Test-IsAdmin)) { Write-Warning "Sledgehammer requires administrative elevation."; return }

    Write-Section "Invoking Sledgehammer Process Termination: $ProcessName"

    $escapedName = $ProcessName.Replace("'", "''")

    $Targets = Get-CimInstance Win32_Process -Filter "Name LIKE '%$escapedName%'"

    if (-not $Targets) { Write-Host "[-] No matching processes found." -ForegroundColor Yellow; return }

    foreach ($Proc in $Targets) {

        Write-Host "[!] Target Found: $($Proc.Name) [PID: $($Proc.ProcessId)]" -ForegroundColor Red

        try {

            if (-not $PSCmdlet.ShouldProcess("$($Proc.Name) (PID $($Proc.ProcessId))", 'Terminate process')) { continue }

            $Result = Invoke-CimMethod -InputObject $Proc -MethodName "Terminate"

            if ($Result.ReturnValue -eq 0) { Write-Host "[OK] Terminated PID $($Proc.ProcessId)" -ForegroundColor Green }

        } catch { Write-Error "Failed to terminate: $($_.Exception.Message)" }

    }

}

function Clear-NetworkFabric {

    if (-not (Test-IsAdmin)) { Write-Warning "Network Fabric flushing requires elevation."; return }

    Write-Section "Purging and Rebuilding Local Network Fabric"

    Clear-DnsClientCache

    Remove-NetNeighbor -AddressFamily IPv4, IPv6 -Confirm:$false -ErrorAction SilentlyContinue

    Update-SmbBinding -ErrorAction SilentlyContinue | Out-Null

    cmd.exe /c "ipconfig /release && ipconfig /renew"

    netsh int ip reset | Out-Null

    netsh winsock reset | Out-Null

    Write-Host "[OK] Network Fabric reset complete." -ForegroundColor Green

}

function Optimize-StorageFabric {

    if (-not (Test-IsAdmin)) { Write-Warning "Storage optimization requires administrative access."; return }

    Write-Section "Optimizing Storage Subsystem & Volume Geometry"

    $Volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.FileSystemLabel -notmatch 'Recovery' }

    foreach ($Vol in $Volumes) {

        Write-Host "[*] Optimizing Volume $($Vol.DriveLetter): [$($Vol.FileSystemType)]..." -ForegroundColor Cyan

        try {

            Optimize-Volume -DriveLetter $Vol.DriveLetter -Verbose

            Write-Host "[✓] Volume $($Vol.DriveLetter): optimization completed." -ForegroundColor Green

        } catch { Write-Warning "Could not optimize volume $($Vol.DriveLetter): $($_.Exception.Message)" }

    }

}

function Get-HardwareFabric {

    Write-Section "Hardware Fabric & Motherboard Telemetry"

    Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber, Version | Format-List

    Get-CimInstance Win32_BIOS | Select-Object Manufacturer, Name, Version, ReleaseDate, SMBIOSBIOSVersion | Format-List

    Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, DeviceLocator, Capacity, Speed, Manufacturer | Format-Table -AutoSize

}

function Get-ProcessFabric {

    if (-not (Test-IsAdmin)) { Write-Warning "Deep process profiling requires elevated access."; return }

    Write-Section "Advanced Process Tree and Allocation Telemetry"

    Get-CimInstance Win32_Process | Sort-Object WorkingSetSize -Descending | Select-Object -First 10 | ForEach-Object {

        [PSCustomObject]@{ PID = $_.ProcessId; Name = $_.Name; MemoryMB = [Math]::Round($_.WorkingSetSize / 1MB, 2); ParentPID = $_.ParentProcessId; Executable = $_.ExecutablePath }

    } | Format-Table -AutoSize

}

function Get-SystemFaults {

    Write-Section "Recent System Log Errors and Infrastructure Faults"

    $Faults = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2 } -MaxEvents 15 -ErrorAction SilentlyContinue

    if ($Faults) {

        $Faults | ForEach-Object {

            [PSCustomObject]@{ TimeGenerated = $_.TimeCreated; Provider = $_.ProviderName; EventID = $_.Id; Summary = ($_.Message -replace "[\`r\`n]+", " ") }

        } | Format-Table -Wrap

    } else { Write-Host "[-] No critical hardware defaults or system faults found." -ForegroundColor Green }

}

function Invoke-SystemShell {

    if (-not (Test-IsAdmin)) { Write-Warning "Requires Administrator."; return }

    Write-Section "Escalating Session to NT AUTHORITY\SYSTEM"

    $PsExecPaths = @("psexec.exe", "C:\AdminOps\psexec.exe", "C:\AdminOps\Tools\PsExec.exe", "C:\AdminOps\Tools\psexec.exe")

    $FoundPath = $null

    foreach ($Path in $PsExecPaths) {

        $cmd = Get-Command $Path -ErrorAction SilentlyContinue

        if ($cmd) { $FoundPath = $cmd.Source; break }

        if (Test-Path $Path) { $FoundPath = $Path; break }

    }

    if (-not $FoundPath) { Write-Warning "PsExec.exe not found."; return }

    Start-Process -FilePath $FoundPath -ArgumentList "-accepteula -i -s pwsh.exe -NoExit -ExecutionPolicy Bypass" -Verb RunAs

}

function Get-SystemDiagnostics {

    if (-not (Test-IsAdmin)) { Write-Warning "Requires Administrator."; return }

    Write-Section "System Performance & Hardware Fabric"

    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, Id, CPU, WorkingSet | Format-Table -AutoSize

    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,

        @{Name="SizeGB";Expression={[Math]::Round($_.Size/1GB,2)}}, @{Name="FreeGB";Expression={[Math]::Round($_.FreeSpace/1GB,2)}} | Format-Table -AutoSize

    Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture, LastBootUpTime | Format-List

}

function Get-NetworkFabric {

    Write-Section "Network Interface and Active Listener Profile"

    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed | Format-Table -AutoSize

    Get-NetTCPConnection -State Listen,Established -ErrorAction SilentlyContinue |

        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess -First 25 | Format-Table -AutoSize

}

function Invoke-DeepSessionAudit {

    if (-not (Test-IsAdmin)) { Write-Warning "Requires elevation."; return }

    Write-Section "Active Interactive Session Audit"

    Get-CimInstance Win32_LogonSession | Where-Object {$_.LogonType -eq 2 -or $_.LogonType -eq 10} | ForEach-Object {

        $logon = $_

        $user = Get-CimInstance -Query "Associators of {Win32_LogonSession.LogonId='$($logon.LogonId)'} Where AssocClass=Win32_LoggedOnUser" -ErrorAction SilentlyContinue

        [PSCustomObject]@{ LogonId = $logon.LogonId; StartTime = $logon.StartTime; LogonType = $logon.LogonType; User = $user.Name; Domain = $user.Domain }

    } | Format-Table -AutoSize

}

function Initialize-SQLStorageFabric {

    param([Parameter(Mandatory)][ValidatePattern('^[a-zA-Z]$')][string]$DriveLetter)

    if (-not (Test-IsAdmin)) { Write-Warning "Storage fabric provisioning requires elevation."; return }

    $TargetRoot = "$($DriveLetter):\SQLData"

    $Directories = @($TargetRoot, "$TargetRoot\Data", "$TargetRoot\Logs", "$TargetRoot\TempDB", "$TargetRoot\Backup")

    Write-Section "Provisioning SQL Server Storage Fabric on Volume $($DriveLetter):"

    foreach ($Dir in $Directories) {

        if (-not (Test-Path $Dir)) { New-Item -Path $Dir -ItemType Directory -Force | Out-Null }

    }

    foreach ($Dir in $Directories) {

        $Folder = Get-CimInstance Win32_Directory -Filter "Name='$($Dir -replace '\\\\', '\\\\\\\\')'"

        if ($Folder.Compressed) { $null = Invoke-CimMethod -InputObject $Folder -MethodName "Uncompress" }

    }

    Write-Host "[✓] SQL Storage fabric prepared at $TargetRoot." -ForegroundColor Green

}

# ===================================================================

# MASTER FABRIC ADD-ON LAYER

# Storage / Services / Defender / Boot / Token / VHD / SQL / Aliases

# ===================================================================

function mm-volumes {

    Write-Section "Volume Fabric"

    Get-Volume |

    Where-Object DriveLetter |

    Sort-Object DriveLetter |

    Select-Object DriveLetter,

                  FileSystemLabel,

                  FileSystem,

                  HealthStatus,

                  OperationalStatus,

                  @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}},

                  @{N='FreeGB';E={[math]::Round($_.SizeRemaining/1GB,2)}} |

    Format-Table -AutoSize

}

function Get-ServiceFabric {

    Write-Section "Service Fabric"

    Get-Service |

    Sort-Object Status,DisplayName |

    Select-Object Status,Name,DisplayName |

    Format-Table -AutoSize

}

function Get-DefenderFabric {

    Write-Section "Microsoft Defender Fabric"

    if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {

        Write-Warning "Microsoft Defender cmdlets are not available."

        return

    }

    Get-MpComputerStatus |

    Select-Object AMServiceEnabled,

                  AntivirusEnabled,

                  AntispywareEnabled,

                  RealTimeProtectionEnabled,

                  BehaviorMonitorEnabled,

                  IoavProtectionEnabled,

                  NISEnabled,

                  IsTamperProtected,

                  QuickScanAge,

                  FullScanAge |

    Format-List

}

function Get-BootFabric {

    Write-Section "Boot / Shutdown / Kernel Power Fabric"

    Get-WinEvent -FilterHashtable @{

        LogName = 'System'

        Id      = 41,6005,6006,6008,1074

    } -MaxEvents 40 -ErrorAction SilentlyContinue |

    Select-Object TimeCreated,

                  Id,

                  ProviderName,

                  LevelDisplayName,

                  Message |

    Format-Table -Wrap -AutoSize

}

function Get-TokenFabric {

    Write-Section "Current Security Token Fabric"

    whoami /all

}

function Get-VHDFabric {

    Write-Section "Mounted VHD / Disk Image Fabric"

    if (-not (Get-Command Get-DiskImage -ErrorAction SilentlyContinue)) {

        Write-Warning "Get-DiskImage is unavailable. Hyper-V PowerShell module may not be present."

        return

    }

    Get-DiskImage |

    Where-Object Attached |

    Select-Object ImagePath,

                  Attached,

                  StorageType,

                  DevicePath |

    Format-Table -AutoSize

}

function Get-DiskFabric {

    Write-Section "Physical Disk / Partition Fabric"

    Get-Disk |

    Select-Object Number,

                  FriendlyName,

                  SerialNumber,

                  BusType,

                  PartitionStyle,

                  OperationalStatus,

                  HealthStatus,

                  @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}} |

    Format-Table -AutoSize

    Write-Host ""

    Write-Host "--- Partitions ---" -ForegroundColor Cyan

    Get-Partition |

    Select-Object DiskNumber,

                  PartitionNumber,

                  DriveLetter,

                  Type,

                  @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}} |

    Format-Table -AutoSize

}

function Get-PathFabric {

    param(

        [string]$Path = "C:\\"

    )

    Write-Section "Path Fabric Size Map: $Path"

    if (-not (Test-Path $Path)) {

        Write-Warning "Path not found: $Path"

        return

    }

    Get-ChildItem $Path -Force -ErrorAction SilentlyContinue |

    ForEach-Object {

        $size = if ($_.PSIsContainer) {
            $measure = Get-ChildItem -LiteralPath $_.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
            if ($measure -and $null -ne $measure.Sum) { [double]$measure.Sum } else { 0 }
        } else {
            if ($null -ne $_.Length) { [double]$_.Length } else { 0 }
        }

        [PSCustomObject]@{

            Name   = $_.Name

            Path   = $_.FullName

            Type   = if ($_.PSIsContainer) { "Folder" } else { "File" }

            SizeGB = [math]::Round(($size / 1GB), 2)

        }

    } |

    Sort-Object SizeGB -Descending |

    Format-Table -AutoSize

}

function Get-StartupFabric {

    Write-Section "Startup Fabric"

    Get-CimInstance Win32_StartupCommand |

    Select-Object Name,

                  Command,

                  Location,

                  User |

    Format-Table -Wrap -AutoSize

}

function Get-TaskFabric {

    Write-Section "Scheduled Task Fabric"

    Get-ScheduledTask |

    Where-Object State -ne 'Disabled' |

    Select-Object TaskName,

                  TaskPath,

                  State |

    Sort-Object TaskPath,TaskName |

    Format-Table -AutoSize

}

function Get-NetworkRouteFabric {

    Write-Section "Network Route / DNS Fabric"

    Write-Host "--- DNS Servers ---" -ForegroundColor Cyan

    Get-DnsClientServerAddress |

    Where-Object AddressFamily -eq 2 |

    Select-Object InterfaceAlias,ServerAddresses |

    Format-Table -AutoSize

    Write-Host ""

    Write-Host "--- Routes ---" -ForegroundColor Cyan

    Get-NetRoute -AddressFamily IPv4 |

    Sort-Object RouteMetric |

    Select-Object DestinationPrefix,

                  NextHop,

                  InterfaceAlias,

                  RouteMetric |

    Format-Table -AutoSize

}

function Get-SQLFabric {

    Write-Section "SQL Server Fabric"

    Get-Service |

    Where-Object {

        $_.Name -match '^MSSQL|^SQL' -or

        $_.DisplayName -match 'SQL Server'

    } |

    Select-Object Status,

                  Name,

                  DisplayName |

    Format-Table -AutoSize

}

function Backup-SQLFabric {

    param(

        [string]$BackupRoot = "C:\AdminOps\SQLBackups"

    )

    Write-Section "SQL Backup Fabric"

    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

    Write-Host "Backup root prepared:" -ForegroundColor Green

    Write-Host $BackupRoot

    Write-Warning "This prepares the backup folder only. Actual database backup requires sqlcmd/dbatools and database names."

}

function Move-TempDBFabric {

    param(

        [Parameter(Mandatory)]

        [ValidatePattern('^[a-zA-Z]$')]

        [string]$DriveLetter

    )

    Write-Section "SQL TempDB Move Fabric"

    $Target = "$($DriveLetter):\SQLData\TempDB"

    New-Item -ItemType Directory -Path $Target -Force | Out-Null

    Write-Host "TempDB target prepared:" -ForegroundColor Green

    Write-Host $Target

    Write-Warning "This prepares the TempDB path only. SQL ALTER DATABASE commands still need to be run for your SQL instance."

}

function Test-MasterMackProfile {

    Write-Section "MasterMack Profile Self-Test"

    $Checks = @(

        "Test-IsAdmin",

        "Ensure-Elevated",

        "Write-Section",

        "AdminOpsMode",

        "Invoke-SafeDriveCleanup",

        "Optimize-StorageFabric",

        "Get-SystemDiagnostics",

        "Get-NetworkFabric",

        "Invoke-DeepSessionAudit",

        "Invoke-DeepFileAudit",

        "Get-HardwareFabric",

        "Get-ProcessFabric",

        "Get-SystemFaults",

        "Invoke-SystemShell",

        "Initialize-SQLStorageFabric",

        "mm-volumes",

        "Get-ServiceFabric",

        "Get-DefenderFabric",

        "Get-BootFabric",

        "Get-TokenFabric",

        "Get-VHDFabric",

        "Get-DiskFabric",

        "Get-PathFabric",

        "Get-StartupFabric",

        "Get-TaskFabric",

        "Get-NetworkRouteFabric",

        "Get-SQLFabric"

    )

    $Checks | ForEach-Object {

        $Name = $_

        $exists = Get-Command $Name -ErrorAction SilentlyContinue

        [PSCustomObject]@{

            Command = $Name

            Loaded  = [bool]$exists

            Type    = if ($exists) { $exists.CommandType } else { "Missing" }

        }

    } | Format-Table -AutoSize

}

# ---------------------------

# Add-on aliases

# ---------------------------

Set-Alias vol mm-volumes

Set-Alias sys Get-SystemDiagnostics

Set-Alias netfab Get-NetworkFabric

Set-Alias procfab Get-ProcessFabric

Set-Alias faults Get-SystemFaults

Set-Alias defender Get-DefenderFabric

Set-Alias bootlog Get-BootFabric

Set-Alias token Get-TokenFabric

Set-Alias vhd Get-VHDFabric

Set-Alias disks Get-DiskFabric

Set-Alias paths Get-PathFabric

Set-Alias startup Get-StartupFabric

Set-Alias tasks Get-TaskFabric

Set-Alias routes Get-NetworkRouteFabric

Set-Alias sqlfab Get-SQLFabric

Set-Alias selftest Test-MasterMackProfile

function Invoke-DeepFileAudit {

    if (-not (Test-IsAdmin)) { Write-Warning "Deep file auditing requires raw system access tokens."; return }

    Write-Section "LOW-LEVEL ARTIFACT INSPECTION: FILE TRANSFERS & EGRESS"

    $JournalInfo = fsutil usn queryjournal C:

    $FirstUsn = ($JournalInfo | Select-String "First USN" | ForEach-Object { $_.ToString().Split(':')[-1].Trim() })

    if ($FirstUsn) {

        $RawJournal = fsutil usn readjournal C: startusn=$FirstUsn csv 2>$null | Select-Object -First 200

        $ParsedEntries = foreach ($Line in $RawJournal) {

            if ($Line -match "^[0-9a-fA-FxX]+,") {

                $Fields = $Line.Split(',')

                if ($Fields.Count -ge 6) {

                    $ReasonReadable = switch -regex ($Fields[4].Trim()) { "0x00000001" { "File Created" } "0x00000002" { "Data Extended" } "0x00000004" { "Data Overwritten" } "0x00002000" { "File Renamed" } "0x00008000" { "File Deleted" } default { "Modified" } }

                    [PSCustomObject]@{ Timestamp = $Fields[3].Trim(); Action = $ReasonReadable; FileName = $Fields[5].Trim().Replace('"', '') }

                }

            }

        }

        if ($ParsedEntries) { $ParsedEntries | Where-Object { $_.FileName -notmatch '\\.(tmp|log|ini|inf|evtx|pf)$' -and $_.FileName -notmatch '^(NTUSER|UsrClass|SystemVolumeInformation)' } | Select-Object -First 20 | Format-Table -AutoSize }

    }

}

function AdminOpsMode {

    [CmdletBinding(DefaultParameterSetName = "Status")]

    param(

        [Parameter(ParameterSetName = "Enable")] [switch]$Enable,

        [Parameter(ParameterSetName = "Disable")] [switch]$Disable,

        [Parameter(ParameterSetName = "Status")] [switch]$Status,

        [Parameter()] [string]$OpsPath = "C:\AdminOps",

        [Parameter()] [string[]]$ExclusionProcesses = @(),

        [Parameter()] [switch]$IncludeExtensionExclusions,

        [Parameter()] [string[]]$ExclusionExtensions = @()

    )

    if (-not (Ensure-Elevated -Purpose "AdminOpsMode")) { return }

    $script:OpsPath = $OpsPath

    Write-Section "Admin Ops Mode - Controlled Defender Exclusions"

    Write-MackLog "AdminOpsMode invoked. ParameterSet=$($PSCmdlet.ParameterSetName)"

    try { $null = Get-MpComputerStatus -ErrorAction Stop } catch { Write-Error "Windows Defender unavailable."; return }

    New-Item -Path $OpsPath -ItemType Directory -Force | Out-Null

    function Show-Status {

        Write-Section "Current Defender & Exclusion Status"

        $s = Get-MpComputerStatus; $p = Get-MpPreference

        Write-Host ("ComputerName              : {0}" -f $env:COMPUTERNAME)

        Write-Host ("RealTimeProtectionEnabled : {0}" -f $s.RealTimeProtectionEnabled)

        Write-Host ("TamperProtection          : {0}" -f $s.IsTamperProtected)

        Write-Host ""

        Write-Host "Exclusion Paths:"

        if ($p.ExclusionPath) { $p.ExclusionPath | ForEach-Object { Write-Host "  - $_" } } else { Write-Host "  (none)" }

    }

    function Add-Exclusions {

        $pref = Get-MpPreference

        if ($pref.ExclusionPath -notcontains $OpsPath) { Add-MpPreference -ExclusionPath $OpsPath }

        foreach ($proc in $ExclusionProcesses) {

            $pref = Get-MpPreference

            if ($pref.ExclusionProcess -notcontains $proc) { Add-MpPreference -ExclusionProcess $proc }

        }

        if ($IncludeExtensionExclusions) {

            foreach ($ext in $ExclusionExtensions) {

                $pref = Get-MpPreference

                if ($pref.ExclusionExtension -notcontains $ext.TrimStart(".")) { Add-MpPreference -ExclusionExtension $ext.TrimStart(".") }

            }

        }

    }

    function Remove-Exclusions {

        $pref = Get-MpPreference

        if ($pref.ExclusionPath -contains $OpsPath) { Remove-MpPreference -ExclusionPath $OpsPath }

    }

    switch ($PSCmdlet.ParameterSetName) {

        "Enable"  { Add-Exclusions; Show-Status }

        "Disable" { Remove-Exclusions; Show-Status }

        "Status"  { Show-Status }

    }

}

function mm-admin { Start-Process pwsh -Verb RunAs }

function mm-edit-profile { notepad $PROFILE }

function mm-reload-profile { . $PROFILE }

function mm-profile-path { $PROFILE | Select-Object * }

function mm-home { Set-Location $HOME }

function mm-tools { Set-Location "C:\MackTools" }

function mm-adminops { Set-Location "C:\AdminOps" }

function mm-c { Set-Location "C:\\" }

function mm-ip { Get-NetIPAddress | Where-Object AddressFamily -eq IPv4 | Select-Object InterfaceAlias,IPAddress,PrefixLength | Format-Table -AutoSize }

function mm-flushdns { ipconfig /flushdns }

function mm-path { $env:Path -split ';' | Sort-Object }

function mm-which { param([Parameter(Mandatory)][string]$Name) Get-Command $Name -ErrorAction SilentlyContinue | Select-Object Source,Version,CommandType }

function mm-size {
    param([string]$Path = ".")

    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        if ($_.PSIsContainer) {
            $measure = Get-ChildItem -LiteralPath $_.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
            $size = if ($measure -and $null -ne $measure.Sum) { [double]$measure.Sum } else { 0 }
        }
        else {
            $size = if ($null -ne $_.Length) { [double]$_.Length } else { 0 }
        }

        [PSCustomObject]@{
            Name   = $_.Name
            Path   = $_.FullName
            SizeGB = [math]::Round(($size / 1GB), 2)
        }
    } |
    Sort-Object SizeGB -Descending |
    Format-Table -AutoSize
}

function mm-croot { Get-ChildItem C:\ -Directory -Force | Sort-Object Name | Select-Object Name,FullName }

function mm-vbox { $VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"; if (Test-Path $VBoxManage) { & $VBoxManage list vms } }

function mm-tail { if (Get-Command tailscale -ErrorAction SilentlyContinue) { tailscale status; tailscale ip -4 } }

function mm-git-status { git status }

Set-Alias ll Get-ChildItem

Set-Alias admin mm-admin

Set-Alias editp mm-edit-profile

Set-Alias reloadp mm-reload-profile

Set-Alias croot mm-croot

Set-Alias flushdns mm-flushdns

if (Get-Module -ListAvailable -Name Terminal-Icons) { Import-Module Terminal-Icons }

if (Get-Command zoxide -ErrorAction SilentlyContinue) {

    try {

        $zoxideInit = zoxide init powershell 2>$null | Out-String

        if ($zoxideInit) { Invoke-Expression $zoxideInit }

    } catch { Write-Verbose "zoxide initialization skipped: $($_.Exception.Message)" }

}

# Prompt initialization is performed after the Command Center functions load.

try {

    $hashPath   = $Global:MackProfileMeta.HashFile

    $profilePath = $Global:MackProfileMeta.ProfilePath

    if ((Test-Path -LiteralPath $profilePath) -and -not (Test-Path -LiteralPath $hashPath)) {

        (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash | Out-File -LiteralPath $hashPath

    }

} catch {}

function Get-VBoxFabric {

    Write-Section "VirtualBox Network Fabric"

    Get-NetAdapter |

    Where-Object {

        $_.Name -match "VirtualBox|VBox"

    } |

    Format-Table Name,Status,LinkSpeed -AutoSize

}

function Get-DriverFaultFabric {

    Write-Section "Driver Fault Fabric"

    Get-WinEvent -FilterHashtable @{

        LogName='System'

        Level=1,2

    } -MaxEvents 50 -ErrorAction SilentlyContinue |

    Where-Object {

        $_.ProviderName -match "VBox|Kernel|Service Control|NDIS"

    } |

    Select-Object TimeCreated,

                  ProviderName,

                  Id,

                  Message |

    Format-Table -Wrap -AutoSize

}

function Get-BugcheckFabric {

    Write-Section "Bugcheck Fabric"

    Get-WinEvent -FilterHashtable @{

        LogName='System'

        Id=41,1001

    } -MaxEvents 20 -ErrorAction SilentlyContinue |

    Format-Table TimeCreated,ProviderName,Id,Message -Wrap

}

function Get-EventFabric {

    Write-Section "Recent Event Fabric"

    Get-WinEvent -LogName System -MaxEvents 100 |

    Select-Object TimeCreated,

                  ProviderName,

                  Id,

                  LevelDisplayName |

    Format-Table -AutoSize

}

function Get-USBFabric {

    Write-Section "USB Device Fabric"

    Get-PnpDevice |

    Where-Object InstanceId -match "^USB" |

    Select-Object Status,

                  Class,

                  FriendlyName,

                  InstanceId |

    Format-Table -Wrap -AutoSize

}

function Get-VMFabric {

    Write-Section "Virtual Machine Fabric"

    if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {

        VBoxManage list vms

    }

}

function Get-MemoryFabric {

    Write-Section "Memory Fabric"

    Get-Counter '\Memory\Available MBytes',

                '\Memory\Committed Bytes' |

    Select -Expand CounterSamples |

    Format-Table Path,CookedValue -Auto

}

function Get-PagefileFabric {

    Write-Section "Pagefile Fabric"

    Get-CimInstance Win32_PageFileUsage |

    Format-Table Name,

                 AllocatedBaseSize,

                 CurrentUsage,

                 PeakUsage -Auto

}

function Get-DefenderThreatFabric {

    Write-Section "Defender Threat Fabric"

    Get-MpThreatDetection -ErrorAction SilentlyContinue |

    Select InitialDetectionTime,

           ThreatName,

           Resources |

    Format-Table -Wrap

}

function Get-UpdateFabric {

    Write-Section "Windows Update Fabric"

    Get-HotFix |

    Sort InstalledOn -Descending |

    Select -First 25 |

    Format-Table InstalledOn,

                 HotFixID,

                 Description -Auto

}

Set-Alias vboxfab Get-VBoxFabric

Set-Alias drvfab Get-DriverFaultFabric

Set-Alias bugfab Get-BugcheckFabric

Set-Alias eventfab Get-EventFabric

Set-Alias usbfab Get-USBFabric

Set-Alias vmfab Get-VMFabric

Set-Alias memfab Get-MemoryFabric

Set-Alias pagefab Get-PagefileFabric

Set-Alias threatfab Get-DefenderThreatFabric

Set-Alias updatefab Get-UpdateFabric



# Optional modules are imported only when already installed. Profiles should never

# perform network installs or require elevation during shell startup.

if (Get-Module -ListAvailable -Name Az.Tools.Migration) {

    Import-Module Az.Tools.Migration -ErrorAction SilentlyContinue

}

if (Get-Module -ListAvailable -Name PSReadLine) {

    Import-Module PSReadLine -ErrorAction SilentlyContinue

    if ($Host.Name -eq 'ConsoleHost' -and [Environment]::UserInteractive -and -not [Console]::IsOutputRedirected) {

        Set-PSReadLineOption -HistoryNoDuplicates -PredictionSource History -PredictionViewStyle ListView -ErrorAction SilentlyContinue

        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue

    }

}

# ===================================================================

# MASTERMACK 6.1 COMMAND CENTER

# Dashboard / health score / parallel audit / reports / smart prompt

# ===================================================================

$script:MackStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$script:MackLocations = [ordered]@{

    AdminOps = 'C:\AdminOps'

    Tools    = 'C:\MackTools'

    Profile  = Split-Path -Parent $PROFILE.CurrentUserAllHosts

    Desktop  = [Environment]::GetFolderPath('Desktop')

    Docs     = [Environment]::GetFolderPath('MyDocuments')

}

function Get-MackUptime {

    $os = Get-CimInstance Win32_OperatingSystem

    $elapsed = (Get-Date) - $os.LastBootUpTime

    [PSCustomObject]@{

        BootTime = $os.LastBootUpTime

        Days     = $elapsed.Days

        Hours    = $elapsed.Hours

        Minutes  = $elapsed.Minutes

        Display  = '{0}d {1}h {2}m' -f $elapsed.Days, $elapsed.Hours, $elapsed.Minutes

    }

}

function Get-MackCommand {

    [CmdletBinding()]

    param([string]$Name = '*')

    Get-Command -Name $Name -ErrorAction SilentlyContinue |

        Where-Object { $_.Name -match '^(Get|Set|Test|Invoke|Clear|Initialize|Backup|Move|Start|Export)-.*Fabric|^mm-' } |

        Sort-Object Name |

        Select-Object Name, CommandType, ModuleName

}

function Get-MackHealth {

    [CmdletBinding()]

    param()

    $os = Get-CimInstance Win32_OperatingSystem

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    $defender = if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {

        Get-MpComputerStatus -ErrorAction SilentlyContinue

    }

    $diskFree = if ($disk.Size) { [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1) } else { 0 }

    $memoryFree = if ($os.TotalVisibleMemorySize) {

        [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 1)

    } else { 0 }

    $pendingReboot = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or

        (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')

    $defenderRealTime = if ($null -ne $defender) { [bool]$defender.RealTimeProtectionEnabled } else { $false }

    $signatureAge = if ($null -ne $defender) { $defender.AntivirusSignatureAge } else { $null }

    $checks = @(

        [PSCustomObject]@{ Check='System drive free'; Passed=($diskFree -ge 15); Detail="$diskFree% free"; Weight=25 }

        [PSCustomObject]@{ Check='Available memory'; Passed=($memoryFree -ge 15); Detail="$memoryFree% free"; Weight=15 }

        [PSCustomObject]@{ Check='Defender real-time'; Passed=$defenderRealTime; Detail=[string]$defenderRealTime; Weight=25 }

        [PSCustomObject]@{ Check='Defender signatures'; Passed=($null -ne $signatureAge -and $signatureAge -le 3); Detail="Age: $signatureAge day(s)"; Weight=20 }

        [PSCustomObject]@{ Check='Pending reboot'; Passed=(-not $pendingReboot); Detail=[string]$pendingReboot; Weight=15 }

    )

    $score = ($checks | Where-Object Passed | Measure-Object Weight -Sum).Sum

    [PSCustomObject]@{ Score=[int]$score; Grade=$(if($score -ge 90){'A'}elseif($score -ge 80){'B'}elseif($score -ge 70){'C'}else{'Needs attention'}); Checks=$checks }

}

function Show-MackDashboard {

    [CmdletBinding()]

    param([switch]$Detailed)

    $health = Get-MackHealth

    $uptime = Get-MackUptime

    $os = Get-CimInstance Win32_OperatingSystem

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    $admin = Test-IsAdmin

    Write-Section "MACKPROJEKT-COMMANDCENTER | MasterMack 6.1"

    Write-Host (' Health     : {0}/100 ({1})' -f $health.Score,$health.Grade) -ForegroundColor $(if($health.Score -ge 90){'Green'}elseif($health.Score -ge 70){'Yellow'}else{'Red'})

    Write-Host (' Identity   : {0}\\{1}  |  Admin: {2}' -f $env:USERDOMAIN,$env:USERNAME,$admin)

    Write-Host (' Platform   : {0}  |  PowerShell {1}' -f $os.Caption,$PSVersionTable.PSVersion)

    Write-Host (' Processor  : {0}' -f $cpu.Name)

    Write-Host (' Memory     : {0:N1} GB free / {1:N1} GB' -f ($os.FreePhysicalMemory/1MB),($os.TotalVisibleMemorySize/1MB))

    Write-Host (' System C:  : {0:N1} GB free / {1:N1} GB' -f ($disk.FreeSpace/1GB),($disk.Size/1GB))

    Write-Host (' Uptime     : {0}' -f $uptime.Display)

    Write-Host (' Location   : {0}' -f (Get-Location))

    if ($Detailed) { $health.Checks | Format-Table Check,Passed,Detail -AutoSize }

}

function Invoke-MackParallelAudit {

    [CmdletBinding()]

    param()

    $jobs = [ordered]@{

        OS = { Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,LastBootUpTime }

        CPU = { Get-CimInstance Win32_Processor | Select-Object Name,LoadPercentage,NumberOfLogicalProcessors }

        Disks = { Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,Size,FreeSpace }

        Network = { Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object Name,LinkSpeed,MacAddress }

        Faults = { Get-WinEvent -FilterHashtable @{LogName='System';Level=1,2} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,ProviderName,Message }

        Startup = { Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,User }

    }

    $output = [ordered]@{}

    foreach ($entry in $jobs.GetEnumerator()) {

        $output[$entry.Key] = Start-Job -ScriptBlock $entry.Value

    }

    foreach ($entry in @($output.GetEnumerator())) {

        $output[$entry.Key] = Receive-Job -Job $entry.Value -Wait -AutoRemoveJob

    }

    [PSCustomObject]$output

}

function Export-MackSystemReport {

    [CmdletBinding()]

    param(

        [string]$Path = (Join-Path ([Environment]::GetFolderPath('Desktop')) ("Mack-SystemReport-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))

    )

    $parent = Split-Path -Parent $Path

    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    $report = [ordered]@{

        GeneratedAt = (Get-Date).ToString('o')

        ComputerName = $env:COMPUTERNAME

        User = "$env:USERDOMAIN\\$env:USERNAME"

        IsAdmin = Test-IsAdmin

        Health = Get-MackHealth

        Uptime = Get-MackUptime

        Audit = Invoke-MackParallelAudit

    }

    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding utf8

    Get-Item -LiteralPath $Path

}

function Test-MackNetwork {

    [CmdletBinding()]

    param([string]$Target = '1.1.1.1', [string]$DnsName = 'microsoft.com')

    $gateway = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1

    [PSCustomObject]@{

        AdapterUp = [bool](Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1)

        Gateway = $gateway.NextHop

        GatewayReachable = if ($gateway.NextHop) { Test-Connection $gateway.NextHop -Count 1 -Quiet } else { $false }

        InternetReachable = Test-Connection $Target -Count 1 -Quiet

        DnsResolved = [bool](Resolve-DnsName $DnsName -ErrorAction SilentlyContinue | Select-Object -First 1)

    }

}

function Get-MackProfileBenchmark {

    [CmdletBinding()]

    param([ValidateRange(1,20)][int]$Runs = 3)

    $shell = (Get-Process -Id $PID).Path

    $times = for ($i=1; $i -le $Runs; $i++) {

        (Measure-Command { & $shell -NoLogo -NoProfile -Command ". '$PROFILE'; exit" | Out-Null }).TotalMilliseconds

    }

    [PSCustomObject]@{

        Runs=$Runs

        AverageMs=[math]::Round(($times | Measure-Object -Average).Average,1)

        FastestMs=[math]::Round(($times | Measure-Object -Minimum).Minimum,1)

        SlowestMs=[math]::Round(($times | Measure-Object -Maximum).Maximum,1)

    }

}

function Set-MackLocation {

    [CmdletBinding()]

    param([Parameter(Mandatory,Position=0)][string]$Name)

    $match = $script:MackLocations.Keys | Where-Object { $_ -like "$Name*" } | Select-Object -First 1

    if (-not $match) { throw "Unknown location '$Name'. Available: $($script:MackLocations.Keys -join ', ')" }

    $target = $script:MackLocations[$match]

    if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }

    Set-Location -LiteralPath $target

}

function Initialize-MackPowerBar {
    [CmdletBinding()]
    param([switch]$ForceFallback)

    if ($ForceFallback) {
        Enable-MackPrompt
        $script:MackPowerBarLoaded = $false
        return
    }

    $OhMyPosh = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($OhMyPosh) {
        try {
            $init = oh-my-posh init pwsh 2>$null | Out-String
            if ($init) {
                Invoke-Expression $init
                $script:MackPowerBarLoaded = $true
                return
            }
        }
        catch {
            Write-Warning "Oh My Posh initialization failed: $($_.Exception.Message)"
        }
    }

    # Do not silently replace the user's PowerBar. The native Mack prompt
    # remains available explicitly through: powerbar -ForceFallback
    $script:MackPowerBarLoaded = $false
}

function Install-MackPowerBar {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]

    param([switch]$InstallNerdFont)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is required to install Oh My Posh.' }

    if ($PSCmdlet.ShouldProcess('JanDeDobbeleer.OhMyPosh','Install or upgrade with winget')) {

        winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -ne 0) {

            winget upgrade --id JanDeDobbeleer.OhMyPosh --source winget --accept-source-agreements --accept-package-agreements

        }

    }

    if ($InstallNerdFont -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and

        $PSCmdlet.ShouldProcess('Meslo Nerd Font','Install font for PowerBar glyphs')) {

        oh-my-posh font install meslo

    }

    Write-Host 'Restart the terminal, then set its font face to MesloLGM Nerd Font if installed.' -ForegroundColor Cyan

}

function Enable-MackPrompt {

    $promptBlock = {

        $lastExit = $global:LASTEXITCODE

        $admin = if (Test-IsAdmin) { '#' } else { '$' }

        $branch = ''

        if (Get-Command git -ErrorAction SilentlyContinue) {

            $gitBranch = git branch --show-current 2>$null

            if ($gitBranch) { $branch = " git:$gitBranch" }

        }

        $leaf = Split-Path -Leaf (Get-Location)

        if (-not $leaf) { $leaf = (Get-Location).Path }

        $color = if ($lastExit -and $lastExit -ne 0) { 'Red' } else { 'Cyan' }

        Write-Host "[$env:USERNAME@$env:COMPUTERNAME $leaf$branch]" -NoNewline -ForegroundColor $color

        " $admin "

    }

    Set-Item -Path Function:\global:prompt -Value $promptBlock

}

function Update-MackTools {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]

    param([switch]$All)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is not installed.' }

    if ($All -and $PSCmdlet.ShouldProcess('All eligible winget packages','Upgrade')) {

        winget upgrade --all --include-unknown --accept-source-agreements --accept-package-agreements

    } else {

        winget upgrade

    }

}

Register-ArgumentCompleter -CommandName Set-MackLocation -ParameterName Name -ScriptBlock {

    param($commandName,$parameterName,$wordToComplete)

    $script:MackLocations.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {

        [System.Management.Automation.CompletionResult]::new($_,$_,'ParameterValue',$script:MackLocations[$_])

    }

}

Set-Alias dashboard Show-MackDashboard

Set-Alias health Get-MackHealth

Set-Alias nettest Test-MackNetwork

Set-Alias report Export-MackSystemReport

Set-Alias benchp Get-MackProfileBenchmark

Set-Alias cdm Set-MackLocation

Set-Alias updateall Update-MackTools

Set-Alias powerbar Initialize-MackPowerBar

# Jan De Dobbeleer's PowerBar is the default. The native Git-aware prompt is

# installed automatically when Oh My Posh is not yet available.


# ===================================================================
# MASTERMACK 6.1 :: MACKPROJEKT-COMMANDCENTER
# ===================================================================
$script:MackProjectRoot='C:\Users\donyalemack\MackEnterprises\Projekt-PS1'
$script:MackBackupRoot=Join-Path $script:MackProjectRoot 'Backups'
$script:MackReportRoot=Join-Path $script:MackProjectRoot 'Reports'
$script:MackSnapshotRoot=Join-Path $script:MackProjectRoot 'Snapshots'
$script:MackLogRoot=Join-Path $script:MackProjectRoot 'Logs'
$script:MackFastfetch=Join-Path $HOME '.mackprojekt\terminal\fastfetch\config.jsonc'
foreach($d in @($script:MackBackupRoot,$script:MackReportRoot,$script:MackSnapshotRoot,$script:MackLogRoot)){if(-not(Test-Path $d)){New-Item -ItemType Directory $d -Force -ErrorAction SilentlyContinue|Out-Null}}
function Write-MackEvent{param([string]$Area='Core',[string]$Message,[string]$Level='Info');[ordered]@{Time=(Get-Date).ToString('o');Computer=$env:COMPUTERNAME;Area=$Area;Level=$Level;Message=$Message}|ConvertTo-Json -Compress|Add-Content (Join-Path $script:MackLogRoot ("MasterMack-{0}.jsonl"-f(Get-Date -Format yyyy-MM-dd)))}
function Get-MackStorageCenter{param([string]$Path='C:\',[int]$Top=15);Write-Section 'Storage Command Center';Get-Volume|? DriveLetter|select DriveLetter,FileSystemLabel,HealthStatus,@{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}},@{N='FreeGB';E={[math]::Round($_.SizeRemaining/1GB,2)}}|ft -Auto;Get-PathFabric -Path $Path}
function Find-MackDuplicateFile{param([string]$Path=$HOME,[int]$MinMB=25);$f=gci $Path -File -Recurse -Force -ea SilentlyContinue|? Length -ge ($MinMB*1MB);$f|group Length|? Count -gt 1|%{$_.Group|%{try{[pscustomobject]@{Hash=(Get-FileHash $_.FullName).Hash;SizeMB=[math]::Round($_.Length/1MB,1);Path=$_.FullName}}catch{}}}|group Hash|? Count -gt 1|%{$_.Group}}
function Get-MackMemoryCenter{Write-Section 'Memory / Performance';$o=gcim Win32_OperatingSystem;$p=gcim Win32_PageFileUsage -ea SilentlyContinue;[pscustomobject]@{TotalRAMGB=[math]::Round($o.TotalVisibleMemorySize/1MB,2);FreeRAMGB=[math]::Round($o.FreePhysicalMemory/1MB,2);UsedPct=[math]::Round(100*(1-$o.FreePhysicalMemory/$o.TotalVisibleMemorySize),1);PagefileMB=($p|measure AllocatedBaseSize -Sum).Sum}|fl;gps|sort WorkingSet64 -Desc|select -First 15 Name,Id,@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}},Handles,CPU|ft -Auto}
function Get-MackNetworkCenter{Write-Section 'Network Command Center';Get-NetAdapter|? Status -eq Up|select Name,InterfaceDescription,LinkSpeed,MacAddress|ft -Auto;Get-DnsClientServerAddress -AddressFamily IPv4|? ServerAddresses|select InterfaceAlias,ServerAddresses|ft -Auto;Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ea SilentlyContinue|sort RouteMetric|select -First 3 NextHop,InterfaceAlias,RouteMetric|ft -Auto;if(gcm tailscale -ea SilentlyContinue){tailscale status};Get-NetTCPConnection -State Listen -ea SilentlyContinue|select -First 25 LocalAddress,LocalPort,OwningProcess|ft -Auto}
function Get-MackSecurityCenter{
    Write-Section 'Security Command Center'
    if(gcm Get-MpComputerStatus -ea SilentlyContinue){Get-MpComputerStatus|select AntivirusEnabled,RealTimeProtectionEnabled,BehaviorMonitorEnabled,IsTamperProtected,AntivirusSignatureAge|fl}
    $fw=Get-NetFirewallProfile -ea SilentlyContinue|select Name,Enabled,DefaultInboundAction,DefaultOutboundAction
    if($fw){$fw|ft -Auto; if(-not($fw|? Enabled)){Write-Host 'Firewall state: DISABLED (informational; not scored as a MasterMack health fault)' -ForegroundColor Yellow}}
    if(gcm Get-BitLockerVolume -ea SilentlyContinue){Get-BitLockerVolume|select MountPoint,VolumeStatus,ProtectionStatus,EncryptionMethod|ft -Auto}
    [pscustomobject]@{SecureBoot=try{Confirm-SecureBootUEFI -ea Stop}catch{'Unavailable/Disabled'};TPM=try{(Get-Tpm -ea Stop).TpmReady}catch{'Unavailable'};Admin=Test-IsAdmin}|fl
}
function Get-MackDriverCenter{Write-Section 'Driver / PnP Command Center';Get-PnpDevice -PresentOnly -ea SilentlyContinue|? Status -ne OK|select Status,Class,FriendlyName,InstanceId|ft -Wrap -Auto;Get-WinEvent -FilterHashtable @{LogName='System';Id=41,1001,6008} -MaxEvents 15 -ea SilentlyContinue|select TimeCreated,Id,ProviderName,Message|ft -Wrap}
function Resolve-MackTool{param([Parameter(Mandatory)][string]$Name,[string[]]$Candidates=@());$c=gcm $Name -ea SilentlyContinue|select -First 1;if($c){return $c.Source};foreach($x in $Candidates){$e=[Environment]::ExpandEnvironmentVariables($x);if(Test-Path -LiteralPath $e){return $e}};$null}
function Get-MackDevCenter{
    Write-Section 'Developer Toolchain'
    $tools=[ordered]@{
      git=@('%ProgramFiles%\Git\cmd\git.exe','%LOCALAPPDATA%\Programs\Git\cmd\git.exe');
      gh=@('%ProgramFiles%\GitHub CLI\gh.exe'); az=@('%ProgramFiles%\Microsoft SDKs\Azure\CLI2\wbin\az.cmd');
      dotnet=@('%ProgramFiles%\dotnet\dotnet.exe'); node=@('%ProgramFiles%\nodejs\node.exe'); npm=@('%ProgramFiles%\nodejs\npm.cmd');
      python=@('%LOCALAPPDATA%\Programs\Python\Python313\python.exe','%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe');
      pip=@('%LOCALAPPDATA%\Programs\Python\Python313\Scripts\pip.exe'); winget=@('%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe');
      docker=@('%ProgramFiles%\Docker\Docker\resources\bin\docker.exe'); code=@('%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd'); pwsh=@('%ProgramFiles%\PowerShell\7\pwsh.exe')
    }
    foreach($kv in $tools.GetEnumerator()){$path=Resolve-MackTool $kv.Key $kv.Value;[pscustomobject]@{Tool=$kv.Key;Installed=[bool]$path;Path=$path}}
}
function Get-MackCloudCenter{Write-Section 'Azure / Microsoft 365';foreach($n in 'Az.Accounts','Microsoft.Graph','ExchangeOnlineManagement','MicrosoftTeams'){$m=Get-Module -ListAvailable $n|sort Version -Desc|select -First 1;[pscustomobject]@{Module=$n;Installed=[bool]$m;Version=if($m){$m.Version}else{$null}}}}
function Get-MackPackageCenter{Write-Section 'Package Managers';foreach($n in 'winget','choco','scoop','npm','pip','dotnet'){$c=gcm $n -ea SilentlyContinue;[pscustomobject]@{Manager=$n;Available=[bool]$c;Source=if($c){$c.Source}else{$null}}}}
function Repair-MackWindows{[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]param();if(-not(Test-IsAdmin)){Write-Warning 'Run elevated.';return};if($PSCmdlet.ShouldProcess('Windows','DISM RestoreHealth + SFC')){DISM.exe /Online /Cleanup-Image /RestoreHealth;sfc.exe /scannow}}
function Repair-MackExplorer{[CmdletBinding(SupportsShouldProcess)]param();if($PSCmdlet.ShouldProcess('Explorer','Restart')){Stop-Process -Name explorer -Force -ea SilentlyContinue;Start-Process explorer.exe}}
function Repair-MackNetwork{[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]param();if(-not(Test-IsAdmin)){Write-Warning 'Run elevated.';return};if($PSCmdlet.ShouldProcess('Network stack','Reset')){Clear-DnsClientCache -ea SilentlyContinue;netsh winsock reset;netsh int ip reset;Write-Warning 'Restart may be required.'}}
function Repair-MackStore{[CmdletBinding(SupportsShouldProcess)]param();if($PSCmdlet.ShouldProcess('Store cache','Reset')){Start-Process wsreset.exe}}
function Get-MackPendingReboot{[pscustomobject]@{CBS=Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending';WindowsUpdate=Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired';PendingFileRename=[bool](gp 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ea SilentlyContinue)}}
function Backup-MackProfile{$d=Join-Path $script:MackBackupRoot ("Microsoft.PowerShell_profile-{0}.ps1"-f(Get-Date -Format yyyyMMdd-HHmmss));cp $PROFILE $d -Force;gi $d}
function Test-MackProfileSyntax{param([string]$Path=$PROFILE);$t=$null;$e=$null;[System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$t,[ref]$e)|Out-Null;if($e.Count){$e|select Message,@{N='Line';E={$_.Extent.StartLineNumber}},@{N='Text';E={$_.Extent.Text}}|ft -Wrap;return $false};Write-Host 'Profile syntax: VALID' -ForegroundColor Green;$true}
function Restore-MackProfile{[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]param([string]$Path);if(-not $Path){$Path=(gci $script:MackBackupRoot -Filter '*.ps1'|sort LastWriteTime -Desc|select -First 1).FullName};if(-not(Test-Path $Path)){throw 'No backup found.'};if($PSCmdlet.ShouldProcess($PROFILE,"Restore $Path")){cp $Path $PROFILE -Force}}
function New-MackSnapshot{param([string]$Name=(Get-Date -Format yyyyMMdd-HHmmss));$p=Join-Path $script:MackSnapshotRoot "$Name.json";$d=[ordered]@{Generated=(Get-Date).ToString('o');Computer=$env:COMPUTERNAME;OS=gcim Win32_OperatingSystem|select Caption,Version,BuildNumber,LastBootUpTime;System=gcim Win32_ComputerSystem|select Manufacturer,Model,TotalPhysicalMemory;Disks=Get-Disk|select Number,FriendlyName,BusType,HealthStatus,Size;Volumes=Get-Volume|? DriveLetter|select DriveLetter,FileSystemLabel,HealthStatus,Size,SizeRemaining;Network=Get-NetAdapter|select Name,Status,MacAddress,LinkSpeed;Hotfixes=Get-HotFix|select HotFixID,InstalledOn};$d|ConvertTo-Json -Depth 6|sc $p -Encoding utf8;gi $p}
function Compare-MackSnapshot{param([Parameter(Mandatory)][string]$Reference,[Parameter(Mandatory)][string]$Difference);$a=gc $Reference -Raw|ConvertFrom-Json;$b=gc $Difference -Raw|ConvertFrom-Json;Write-Section 'Snapshot Comparison';Compare-Object ($a.Volumes|ConvertTo-Json -Compress) ($b.Volumes|ConvertTo-Json -Compress);Compare-Object ($a.Network|ConvertTo-Json -Compress) ($b.Network|ConvertTo-Json -Compress);Compare-Object ($a.Hotfixes|ConvertTo-Json -Compress) ($b.Hotfixes|ConvertTo-Json -Compress)}
function Show-MackFastfetch{param([ValidateSet('default','minimal','performance','network','admin','recovery')][string]$Mode='default');if(-not(gcm fastfetch -ea SilentlyContinue)){return};$p=Join-Path $HOME ".mackprojekt\terminal\fastfetch\$Mode.jsonc";if(Test-Path $p){fastfetch --config $p}elseif(Test-Path $script:MackFastfetch){fastfetch --config $script:MackFastfetch}else{fastfetch --logo none}}
function Get-MackCommandCenterCommand{
    $names=@('mack','Show-MackDashboard','Get-MackHealth','Get-MackStorageCenter','Find-MackDuplicateFile','Get-MackMemoryCenter','Get-MackNetworkCenter','Get-MackSecurityCenter','Get-MackDriverCenter','Get-MackDevCenter','Get-MackCloudCenter','Get-MackPackageCenter','Repair-MackWindows','Repair-MackExplorer','Repair-MackNetwork','Repair-MackStore','New-MackSnapshot','Compare-MackSnapshot','Backup-MackProfile','Restore-MackProfile','Test-MackProfileSyntax','Show-MackFastfetch')
    $legacy=Get-MackCommand | Select-Object -ExpandProperty Name
    @($names+$legacy)|Sort-Object -Unique|ForEach-Object{$c=gcm $_ -ea SilentlyContinue;if($c){[pscustomobject]@{Name=$c.Name;CommandType=$c.CommandType;ModuleName=$c.ModuleName}}}
}
$script:MackDisplayMode = 'compact'

function Show-MackCommandPanel {
    [CmdletBinding()]
    param(
        [ValidateSet('compact','full','off')]
        [string]$Mode = $script:MackDisplayMode
    )

    $script:MackDisplayMode = $Mode
    if ($Mode -eq 'off') { return }

    Write-Host ''
    Write-Host '── MASTERMACK 6.1 ───────────────────────────────────────────────────' -ForegroundColor DarkCyan

    if ($Mode -eq 'compact') {
        Write-Host ' COMMAND CENTER        SYSTEM              STORAGE' -ForegroundColor Cyan
        Write-Host ' mack help             dashboard           mack storage'
        Write-Host ' mack commands         health              disks / vol'
        Write-Host ' mack report           sys                 paths'
        Write-Host ''
        Write-Host ' NETWORK               SECURITY            OPERATIONS' -ForegroundColor Cyan
        Write-Host ' mack network          mack security       admin'
        Write-Host ' nettest / routes      defender            editp / reloadp'
        Write-Host ''
        Write-Host ' REPAIR                PROFILE             MORE' -ForegroundColor Cyan
        Write-Host ' mack repair           mack profile        mack snapshot'
        Write-Host ' mack memory           mack dev            mack cloud'
        Write-Host ''
        Write-Host ' Type  mack help  for the complete command map.' -ForegroundColor DarkGray
    }
    else {
        Write-Host ' COMMAND CENTER' -ForegroundColor Cyan
        Write-Host '   mack help | commands | dashboard | health | report | snapshot | compare'
        Write-Host ' SYSTEM / PERFORMANCE' -ForegroundColor Cyan
        Write-Host '   sys | faults | mack memory | memfab | pagefab | procfab | bootlog'
        Write-Host ' STORAGE' -ForegroundColor Cyan
        Write-Host '   mack storage | duplicates | vol | disks | paths | vhd'
        Write-Host ' NETWORK' -ForegroundColor Cyan
        Write-Host '   mack network | nettest | netfab | routes | mm-ip | mm-tail | flushdns'
        Write-Host ' SECURITY' -ForegroundColor Cyan
        Write-Host '   mack security | defender | threatfab | token'
        Write-Host ' HARDWARE / DEVICES' -ForegroundColor Cyan
        Write-Host '   drvfab | bugfab | eventfab | usbfab | vboxfab | vmfab'
        Write-Host ' DEVELOPMENT / CLOUD' -ForegroundColor Cyan
        Write-Host '   mack dev | cloud | packages | updates | updateall'
        Write-Host ' REPAIR / PROFILE' -ForegroundColor Cyan
        Write-Host '   mack repair windows|explorer|network|store'
        Write-Host '   mack profile status|backup|rollback'
        Write-Host ' DISPLAY' -ForegroundColor Cyan
        Write-Host '   mack display compact|full|off'
    }

    Write-Host '──────────────────────────────────────────────────────────────────────' -ForegroundColor DarkCyan
}

function Show-MackHelp{Write-Host @'
MACKPROJEKT-COMMANDCENTER :: MasterMack 6.1
mack dashboard | health | storage | duplicates | memory | network | security | drivers
mack dev | cloud | packages | updates | report | snapshot | compare | commands
mack repair windows|explorer|network|store
mack profile status|backup|rollback
mack fastfetch default|minimal|performance|network|admin|recovery
'@ -ForegroundColor Cyan}
function mack{param([Parameter(Position=0)][string]$Area='help',[Parameter(Position=1)][string]$Action,[Parameter(ValueFromRemainingArguments)][string[]]$Args);switch($Area.ToLower()){display{Show-MackCommandPanel $(if($Action){$Action}else{'compact'})};help{Show-MackHelp};commands{Get-MackCommandCenterCommand};dashboard{Show-MackDashboard -Detailed:($Action -eq 'detailed')};health{Get-MackHealth};storage{Get-MackStorageCenter};duplicates{Find-MackDuplicateFile};memory{Get-MackMemoryCenter};network{Get-MackNetworkCenter};security{Get-MackSecurityCenter};drivers{Get-MackDriverCenter};dev{Get-MackDevCenter};cloud{Get-MackCloudCenter};packages{Get-MackPackageCenter};updates{Get-UpdateFabric};report{Export-MackSystemReport};snapshot{New-MackSnapshot -Name $(if($Action){$Action}else{Get-Date -Format yyyyMMdd-HHmmss})};compare{if($Action -and $Args){Compare-MackSnapshot $Action $Args[0]}else{Write-Warning 'mack compare <old.json> <new.json>'}};repair{switch($Action){windows{Repair-MackWindows};explorer{Repair-MackExplorer};network{Repair-MackNetwork};store{Repair-MackStore};default{Write-Warning 'windows|explorer|network|store'}}};profile{switch($Action){status{Test-MackProfileSyntax};backup{Backup-MackProfile};rollback{Restore-MackProfile};default{Write-Warning 'status|backup|rollback'}}};fastfetch{Show-MackFastfetch $(if($Action){$Action}else{'default'})};default{Show-MackHelp}}}

# Single startup path: PowerShell 7 + PowerBar + Fastfetch
try{$Host.UI.RawUI.WindowTitle='MACKPROJEKT-COMMANDCENTER | PowerShell 7'}catch{}
Initialize-MackPowerBar
if([Environment]::UserInteractive -and -not $env:MACK_PROFILE_QUIET){Show-MackFastfetch default; Show-MackCommandPanel compact}