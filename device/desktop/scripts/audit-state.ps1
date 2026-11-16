
[CmdletBinding()]
param(
    [string]$OutFile,
    [datetime]$Since,
    [switch]$DryRun
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

function Get-SmbiosTable {
    $raw = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\mssmbios\Data' -Name SMBiosData -ErrorAction Stop).SMBiosData
    if (-not $raw) { return $null }
    $i = 8
    $dimms = @()
    $cores = 0; $threads = 0
    while ($i -lt $raw.Length - 4) {
        $type = $raw[$i]; $len = $raw[$i + 1]
        if ($type -eq 127 -or $len -lt 4) { break }

        $strs = @()
        $k = $i + $len
        while ($k -lt $raw.Length -and $raw[$k] -ne 0) {
            $s = ''
            while ($k -lt $raw.Length -and $raw[$k] -ne 0) { $s += [char]$raw[$k]; $k++ }
            $strs += $s; $k++
        }
        $str = { param($ix) if ($ix -ge 1 -and $ix -le $strs.Count) { $strs[$ix - 1] } else { '' } }

        if ($type -eq 4 -and $len -gt 0x26) {
            $cores = $raw[$i + 0x23]
            $threads = [int]$raw[$i + 0x25] -bor ([int]$raw[$i + 0x26] -shl 8)
            if ($threads -gt 256) { $threads = $raw[$i + 0x25] }
        }

        if ($type -eq 17 -and $len -gt 0x1A) {
            $sizeMb = [int]$raw[$i + 0x0C] -bor ([int]$raw[$i + 0x0D] -shl 8)
            if ($sizeMb -eq 0x7FFF -and $len -ge 0x20) {
                $sizeMb = [int]$raw[$i + 0x1C] -bor ([int]$raw[$i + 0x1D] -shl 8) -bor
                          ([int]$raw[$i + 0x1E] -shl 16) -bor ([int]$raw[$i + 0x1F] -shl 24)
            }
            if ($sizeMb -gt 0) {
                $tc = $raw[$i + 0x12]
                $tn = switch ($tc) { 0x1A { 'DDR4' } 0x22 { 'DDR5' } 0x18 { 'DDR3' } default { "type-$tc" } }
                $dimms += [pscustomobject]@{
                    Locator      = & $str $raw[$i + 0x10]
                    SizeMB       = $sizeMb
                    Type         = $tn
                    Rated        = [int]$raw[$i + 0x15] -bor ([int]$raw[$i + 0x16] -shl 8)
                    Configured   = if ($len -gt 0x21) { [int]$raw[$i + 0x20] -bor ([int]$raw[$i + 0x21] -shl 8) } else { 0 }
                    Manufacturer = & $str $raw[$i + 0x17]
                    PartNumber   = & $str $raw[$i + 0x1A]
                }
            }
        }

        $j = $i + $len
        while ($j -lt $raw.Length - 1 -and -not ($raw[$j] -eq 0 -and $raw[$j + 1] -eq 0)) { $j++ }
        $i = $j + 2
    }
    [pscustomobject]@{ Cores = $cores; Threads = $threads; Dimms = $dimms }
}

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

Section 'Firmware / CPU'

$bios = Try-Get { Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' }
if ($bios) {
    Out-Line "| Board | $($bios.BaseBoardManufacturer) $($bios.BaseBoardProduct) |"
    Out-Line "| BIOS | $($bios.BIOSVendor) $($bios.BIOSVersion) $($bios.BIOSReleaseDate) |"
}
$cpu = Try-Get { Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' }
if ($cpu) { Out-Line "| CPU | $($cpu.ProcessorNameString.Trim()) @ $($cpu.'~MHz') MHz |" }

$smb = Try-Get { Get-SmbiosTable }
if ($smb) {
    if ($smb.Cores) { Out-Line "| Cores / threads | $($smb.Cores)C / $($smb.Threads)T |" }
    $totalMb = 0
    foreach ($d in $smb.Dimms) {
        $totalMb += $d.SizeMB
        Out-Line "| DIMM | $($d.SizeMB) MB $($d.Type) | rated $($d.Rated) / configured $($d.Configured) MT/s | $($d.Manufacturer) | $($d.PartNumber.Trim()) |"
    }
    if ($totalMb) { Out-Line "| RAM total | $([math]::Round($totalMb / 1024, 1)) GB |" }
}

Section 'GPU / monitor'

$cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$gpus = Try-Get {
    Get-ChildItem $cls -ErrorAction SilentlyContinue | ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
        Where-Object DriverDesc
}
foreach ($g in $gpus) { Out-Line "| GPU | $($g.DriverDesc) - $($g.DriverVersion) ($($g.DriverDate)) |" }

$vram = Try-Get { (Get-ItemProperty (Join-Path $cls '0000')).'HardwareInformation.qwMemorySize' }
if ($vram) { Out-Line "| VRAM | $([math]::Round($vram / 1GB, 2)) GB (qwMemorySize; the 32-bit MemorySize field under-reports) |" }

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

Section 'Display modes'

try {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Disp {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
  public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;
    public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
    public int dmFields;
    public int dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
    public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
    public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
  }
  [DllImport("user32.dll", CharSet=CharSet.Unicode)]
  public static extern bool EnumDisplaySettings(string device, int modeNum, ref DEVMODE devMode);
}
'@ -ErrorAction Stop

    foreach ($dev in @($null, '\\.\DISPLAY1', '\\.\DISPLAY2', '\\.\DISPLAY3')) {
        $dm = New-Object Disp+DEVMODE
        $dm.dmSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'Disp+DEVMODE')
        if ([Disp]::EnumDisplaySettings($dev, -1, [ref]$dm)) {
            $lbl = if ($dev) { $dev } else { 'current' }
            Out-Line "| $lbl | $($dm.dmPelsWidth)x$($dm.dmPelsHeight) @ $($dm.dmDisplayFrequency) Hz, $($dm.dmBitsPerPel) bpp |"
        }
    }
}
catch { Out-Line '| display modes | needs-review - EnumDisplaySettings unavailable |' }

Section 'Problem devices'

$pnp = Try-Get { & pnputil.exe /enum-devices /problem 2>&1 | Out-String }
if ($pnp -match 'No devices were found') { Out-Line 'None.' }
elseif ($pnp) { Out-Line $pnp.Trim() }
else { Out-Line 'needs-review - pnputil unavailable' }

Section 'Volumes'

foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
    if (-not $d.IsReady) { continue }
    $label = if ($d.VolumeLabel) { $d.VolumeLabel } else { '_' }
    Out-Line ("| {0} | {1} | {2} | {3:N1} GB | {4:N1} GB free |" -f $d.Name, $label, $d.DriveType, ($d.TotalSize / 1GB), ($d.TotalFreeSpace / 1GB))
}
$missing = @('D:', 'E:') | Where-Object { -not (Test-Path "$_\") }
if ($missing) { Out-Line ''; Out-Line "Drive letters absent on this machine: $($missing -join ', ') - docs must not reference them." }

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

foreach ($ini in (Get-ChildItem "$env:APPDATA\obs-studio\basic\profiles\*\basic.ini" -ErrorAction SilentlyContinue)) {
    $text = Get-Content $ini.FullName -Raw -ErrorAction SilentlyContinue
    if ($text -match 'FilePath=([A-Za-z]:\\\\[^\r\n]+)') {
        $rec = ($Matches[1] -replace '\\\\', '\')
        $flag = if ($rec -match '^C:') { 'ON C: - move it to Z:' } else { 'ok' }
        Out-Line "| OBS profile '$($ini.Directory.Name)' | records to $rec | $flag |"
    }
}

Section 'Done'
Out-Line 'Read-only: nothing was changed.'

if ($OutFile) {
    if ($DryRun) {
        Write-Host "`nDry run - would write to $OutFile. Nothing changed." -ForegroundColor Yellow
    }
    else {
        $lines -join "`r`n" | Set-Content -LiteralPath $OutFile -Encoding UTF8
        Write-Host "`nWritten to $OutFile"
    }
}
