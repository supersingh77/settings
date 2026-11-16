# =============================================================================
# audit-state.ps1 - READ-ONLY snapshot of every fact the desktop docs claim.
#
# Prints: OS/build, CPU/board/BIOS, GPU driver, volumes, monitor INF, installed
# apps (ARP), taskbar pin order, Steam libraries, and "looks installed but isn't"
# traps. Writes nothing, changes nothing, needs no elevation.
#
# Written for sessions where WMI/CIM, Get-Volume, Get-AppxPackage, UI Automation
# and Export-StartLayout are blocked (agent sandboxes) - everything here uses
# registry reads, .NET, and the on-disk Steam/pin files instead.
#
# Usage:
#   pwsh device/desktop/scripts/audit-state.ps1
#   pwsh device/desktop/scripts/audit-state.ps1 -OutFile .\state.md
#   pwsh device/desktop/scripts/audit-state.ps1 -Since 2026-10-23
# =============================================================================

[CmdletBinding()]
param(
    [string]$OutFile,
    [datetime]$Since
)

$ErrorActionPreference = 'Continue'
$lines = [System.Collections.Generic.List[string]]::new()

function Out-Line([string]$text = '') {
    $lines.Add($text)
    Write-Host $text
}
function Section([string]$title) {
    Out-Line ''
    Out-Line "## $title"
    Out-Line ''
}
function Try-Get([scriptblock]$sb) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { & $sb } catch { $null } finally { $ErrorActionPreference = $prev }
}

# ---------------------------------------------------------------- OS --------
Section 'OS'

$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
$build = if ($cv.CurrentBuild) { "$($cv.CurrentBuild).$($cv.UBR)" } else { 'needs-review' }
Out-Line "| OS | $($cv.ProductName) $($cv.DisplayVersion) build $build |"
if ($cv.ProductName -notmatch '11') {
    Out-Line "| ⚠ ProductName | reads '$($cv.ProductName)' - stale on ReviOS images; trust DisplayVersion + build |"
}
Out-Line "| Computer | $env:COMPUTERNAME |"
Out-Line "| User | $env:USERNAME |"
Out-Line "| PowerShell | $($PSVersionTable.PSVersion) |"

# ------------------------------------------------------------- hardware -----
Section 'Firmware / CPU'

$bios = Try-Get { Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' }
if ($bios) {
    Out-Line "| Board | $($bios.BaseBoardManufacturer) $($bios.BaseBoardProduct) |"
    Out-Line "| BIOS | $($bios.BIOSVendor) $($bios.BIOSVersion) $($bios.BIOSReleaseDate) |"
}
$cpu = Try-Get { Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' }
if ($cpu) { Out-Line "| CPU | $($cpu.ProcessorNameString.Trim()) @ $($cpu.'~MHz') MHz |" }
Out-Line '| Cores / RAM / refresh | needs a non-sandboxed session (WMI blocked) |'

Section 'GPU / monitor'

$cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$gpus = Try-Get {
    Get-ChildItem $cls -ErrorAction SilentlyContinue | ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
        Where-Object DriverDesc
}
foreach ($g in $gpus) { Out-Line "| GPU | $($g.DriverDesc) - $($g.DriverVersion) ($($g.DriverDate)) |" }

$monInf = Try-Get {
    Select-String -Path 'C:\Windows\INF\oem*.inf' -Pattern 'MSI MAG 255XF' -List -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Filename
}
if ($monInf) { Out-Line "| Monitor INF | $($monInf -join ', ') |" }
$icm = Try-Get { Get-ChildItem 'C:\Windows\System32\spool\drivers\color' -Filter '*MSI*' -ErrorAction SilentlyContinue }
if ($icm) { Out-Line "| Monitor ICM | $($icm.Name -join ', ') |" }

$displays = Try-Get {
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY' -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
            (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DeviceDesc
        }
    } | Where-Object { $_ } | Sort-Object -Unique
}
foreach ($d in $displays) { Out-Line "| Display | $d |" }

# -------------------------------------------------------------- volumes -----
Section 'Volumes'

foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
    if (-not $d.IsReady) { continue }
    $label = if ($d.VolumeLabel) { $d.VolumeLabel } else { '_' }
    Out-Line ("| {0} | {1} | {2} | {3:N1} GB | {4:N1} GB free |" -f $d.Name, $label, $d.DriveType, ($d.TotalSize / 1GB), ($d.TotalFreeSpace / 1GB))
}
$missing = @('D:', 'E:') | Where-Object { -not (Test-Path "$_\") }
if ($missing) { Out-Line ''; Out-Line "Drive letters absent on this machine: $($missing -join ', ') - docs must not reference them." }

# ---------------------------------------------------------------- apps ------
Section 'Installed apps (registry ARP)'

$arp = @()
foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*') {
    $arp += Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object DisplayName
}
$arp = $arp | Sort-Object DisplayName -Unique
Out-Line "$($arp.Count) ARP entries."
foreach ($a in $arp) { Out-Line "- $($a.DisplayName) $($a.DisplayVersion)" }

if ($Since) {
    Section "Installed since $($Since.ToString('yyyy-MM-dd'))"
    $recent = $arp | Where-Object { $_.InstallDate -and $_.InstallDate -gt $Since.ToString('yyyyMMdd') }
    foreach ($r in $recent) { Out-Line "- $($r.DisplayName) $($r.DisplayVersion) ($($r.InstallDate))" }
    foreach ($base in 'C:\Program Files', 'C:\Program Files (x86)', "$env:LOCALAPPDATA\Programs") {
        Get-ChildItem $base -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.CreationTime -gt $Since } |
            ForEach-Object { Out-Line "- [dir] $($_.FullName) $($_.CreationTime.ToString('yyyy-MM-dd'))" }
    }
}

# ------------------------------------------------------------- taskbar -----
Section 'Taskbar pins (left to right)'

$blob = Try-Get { (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' -ErrorAction SilentlyContinue).Favorites }
if ($blob) {
    function Find-Offset([byte[]]$hay, [string]$needle, [bool]$utf16) {
        $pat = if ($utf16) { [Text.Encoding]::Unicode.GetBytes($needle) } else { [Text.Encoding]::GetEncoding(28591).GetBytes($needle) }
        for ($i = 0; $i -le $hay.Length - $pat.Length; $i++) {
            $ok = $true
            for ($j = 0; $j -lt $pat.Length; $j++) { if ($hay[$i + $j] -ne $pat[$j]) { $ok = $false; break } }
            if ($ok) { return $i }
        }
        return [int]::MaxValue
    }

    $candidates = @()
    $pinDir = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    Get-ChildItem $pinDir -Filter '*.lnk' -ErrorAction SilentlyContinue | ForEach-Object {
        $candidates += [pscustomobject]@{ Label = $_.BaseName; Needle = $_.Name; Utf16 = $false }
    }

    $utf16Text = [Text.Encoding]::Unicode.GetString($blob)
    # Packaged pins appear as an AppId ("Vendor.App_hash!App") or a package family
    # name ("Vendor.App_hash"); versioned package paths must be skipped.
    $alias = @{ 'Files' = 'File Explorer'; 'WindowsStore' = 'Microsoft Store'; 'WindowsTerminal' = 'Terminal' }
    [regex]::Matches($utf16Text, '[A-Za-z0-9][A-Za-z0-9._-]*_[a-z0-9]{13}!?[A-Za-z0-9._-]*') |
        ForEach-Object { $_.Value } | Sort-Object -Unique |
        Where-Object { $_ -notmatch '_\d+\.\d+' } |
        ForEach-Object {
            $family = $_ -replace '_[a-z0-9]{13}!?.*$', ''
            $leaf = ($family -split '\.')[-1]
            if (-not $leaf) { return }
            $label = if ($alias.ContainsKey($leaf)) { $alias[$leaf] }
                     else { $leaf.Substring(0, 1).ToUpper() + $leaf.Substring(1) }
            $candidates += [pscustomobject]@{ Label = $label; Needle = $_; Utf16 = $true }
        }

    $ordered = $candidates | ForEach-Object {
        $off = Find-Offset -hay $blob -needle $_.Needle -utf16 $_.Utf16
        if ($off -ne [int]::MaxValue) { [pscustomobject]@{ Label = $_.Label; Offset = $off } }
    } | Group-Object Offset | ForEach-Object { $_.Group | Select-Object -First 1 } | Sort-Object Offset

    # A packaged pin and its .lnk describe the same button - keep one.
    $seen = @{}
    $n = 0
    foreach ($o in $ordered) {
        if ($seen.ContainsKey($o.Label)) { continue }
        $seen[$o.Label] = $true
        $n++
        Out-Line "$n. $($o.Label)"
    }
    Out-Line ''
    Out-Line 'Files in User Pinned\TaskBar:'
    Get-ChildItem $pinDir -Filter '*.lnk' -ErrorAction SilentlyContinue | ForEach-Object { Out-Line "- $($_.Name) ($($_.LastWriteTime.ToString('yyyy-MM-dd')))" }
}
else { Out-Line 'needs-review - no Taskband blob readable' }

# -------------------------------------------------------------- steam ------
Section 'Steam libraries'

$vdf = 'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf'
if (Test-Path $vdf) {
    $registered = Select-String -Path $vdf -Pattern '"path"\s+"(.+)"' -AllMatches |
        ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value -replace '\\\\', '\' }
    foreach ($r in $registered) {
        $apps = @(Get-ChildItem (Join-Path $r 'steamapps') -Filter 'appmanifest_*.acf' -ErrorAction SilentlyContinue).Count
        Out-Line "| registered | $r | $apps apps |"
    }
}
else { Out-Line 'needs-review - libraryfolders.vdf not found (Steam not launched yet)' }

foreach ($lib in 'V:\Games\SteamLibrary', 'Z:\Games\SteamLibrary') {
    if (Test-Path $lib) {
        $apps = @(Get-ChildItem (Join-Path $lib 'steamapps') -Filter 'appmanifest_*.acf' -ErrorAction SilentlyContinue).Count
        $isReg = $registered -and ($registered | Where-Object { $_ -like "*$lib*" })
        Out-Line "| on disk | $lib | $apps manifests | registered: $([bool]$isReg) |"
    }
}

# -------------------------------------------------------------- traps ------
Section 'Looks installed but is not'

$traps = @(
    'C:\Program Files\DroidCam',
    'C:\tools\php84',
    'C:\AMD\Chipset_Software'
)
foreach ($t in $traps) {
    if (-not (Test-Path $t)) { continue }
    $files = @(Get-ChildItem $t -Recurse -File -Force -ErrorAction SilentlyContinue)
    $size = ($files | Measure-Object Length -Sum).Sum
    $verdict = if ($files.Count -eq 0) { 'EMPTY - not an install' }
               elseif ($size -lt 1MB) { 'STUB - config/log only, not an install' }
               else { 'real content' }
    Out-Line ("| {0} | {1} files | {2:N2} MB | {3} |" -f $t, $files.Count, ($size / 1MB), $verdict)
}

$videos = Join-Path $env:USERPROFILE 'Videos'
if (Test-Path $videos) {
    $v = @(Get-ChildItem $videos -File -Force -ErrorAction SilentlyContinue | Where-Object Extension -in '.mp4', '.mkv', '.m4a', '.mov')
    if ($v.Count) {
        $sum = ($v | Measure-Object Length -Sum).Sum / 1GB
        Out-Line ''
        Out-Line ("⚠ {0:N2} GB of recordings sit in {1} - out of policy, they belong on Z:." -f $sum, $videos)
    }
}

Section 'Done'
Out-Line 'Read-only: nothing was changed.'

if ($OutFile) {
    $lines -join "`r`n" | Set-Content -LiteralPath $OutFile -Encoding UTF8
    Write-Host "`nWritten to $OutFile"
}
