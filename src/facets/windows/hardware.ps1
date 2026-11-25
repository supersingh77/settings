$ErrorActionPreference = 'Stop'

function Get-SmbiosTable {
    $raw = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\mssmbios\Data' -Name SMBiosData -ErrorAction SilentlyContinue).SMBiosData
    if (-not $raw) { return $null }
    $i = 8
    $dimms = @()
    $cores = 0
    $threads = 0
    while ($i -lt $raw.Length - 4) {
        $type = $raw[$i]
        $len = $raw[$i + 1]
        if ($type -eq 127 -or $len -lt 4) { break }
        $strs = @()
        $k = $i + $len
        while ($k -lt $raw.Length -and $raw[$k] -ne 0) {
            $s = ''
            while ($k -lt $raw.Length -and $raw[$k] -ne 0) { $s += [char]$raw[$k]; $k++ }
            $strs += $s
            $k++
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
                $sizeMb = [int]$raw[$i + 0x1C] -bor ([int]$raw[$i + 0x1D] -shl 8) -bor ([int]$raw[$i + 0x1E] -shl 16) -bor ([int]$raw[$i + 0x1F] -shl 24)
            }
            if ($sizeMb -gt 0) {
                $tc = $raw[$i + 0x12]
                $tn = switch ($tc) { 0x1A { 'DDR4' } 0x22 { 'DDR5' } 0x18 { 'DDR3' } default { "type-$tc" } }
                $dimms += [pscustomobject]@{
                    locator = [string](& $str $raw[$i + 0x10])
                    bank = [string](& $str $raw[$i + 0x11])
                    sizeMb = $sizeMb
                    type = $tn
                    rated = [int]$raw[$i + 0x15] -bor ([int]$raw[$i + 0x16] -shl 8)
                    configured = if ($len -gt 0x21) { [int]$raw[$i + 0x20] -bor ([int]$raw[$i + 0x21] -shl 8) } else { 0 }
                    manufacturer = [string](& $str $raw[$i + 0x17])
                    partNumber = ([string](& $str $raw[$i + 0x1A])).Trim()
                }
            }
        }
        $j = $i + $len
        while ($j -lt $raw.Length - 1 -and -not ($raw[$j] -eq 0 -and $raw[$j + 1] -eq 0)) { $j++ }
        $i = $j + 2
    }
    [pscustomobject]@{ cores = $cores; threads = $threads; dimms = $dimms }
}

$bios = Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -ErrorAction SilentlyContinue
$cpu = Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -ErrorAction SilentlyContinue
$smb = Get-SmbiosTable

$cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$gpus = @(Get-ChildItem -LiteralPath $cls -ErrorAction SilentlyContinue | ForEach-Object {
    $g = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if (-not $g.DriverDesc) { return }
    $qw = $g.'HardwareInformation.qwMemorySize'
    [pscustomobject]@{
        name = [string]$g.DriverDesc
        version = if ($null -ne $g.DriverVersion) { [string]$g.DriverVersion } else { '' }
        date = if ($null -ne $g.DriverDate) { [string]$g.DriverDate } else { '' }
        vramMb = if ($qw) { [long][math]::Round([double]$qw / 1MB) } else { 0 }
    }
})

$names = [System.Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY' -ErrorAction SilentlyContinue | ForEach-Object {
    Get-ChildItem -LiteralPath $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
        $desc = [string](Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DeviceDesc
        if (-not $desc) { return }
        $name = if ($desc.Contains(';')) { $desc.Substring($desc.LastIndexOf(';') + 1) } else { $desc }
        $name = $name.Trim()
        if (-not $name -or $name -match '^Generic ') { return }
        if (-not $names.Contains($name)) { [void]$names.Add($name) }
    }
}
$monitors = @(foreach ($name in ($names | Sort-Object)) {
    $vendor = ($name -split '\s+')[0]
    $inf = @(Select-String -Path 'C:\Windows\INF\oem*.inf' -Pattern $name -SimpleMatch -List -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Filename)
    $icm = @(Get-ChildItem -LiteralPath 'C:\Windows\System32\spool\drivers\color' -Filter "*$vendor*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    [pscustomobject]@{ name = $name; inf = $inf; icm = $icm }
})

[pscustomobject]@{
    bios = [pscustomobject]@{
        vendor = if ($bios) { [string]$bios.BIOSVendor } else { '' }
        version = if ($bios) { [string]$bios.BIOSVersion } else { '' }
        date = if ($bios) { [string]$bios.BIOSReleaseDate } else { '' }
    }
    board = [pscustomobject]@{
        manufacturer = if ($bios) { [string]$bios.BaseBoardManufacturer } else { '' }
        product = if ($bios -and $bios.BaseBoardProduct) { [string]$bios.BaseBoardProduct } elseif ($bios) { [string]$bios.SystemProductName } else { '' }
    }
    cpu = [pscustomobject]@{
        name = if ($cpu) { ([string]$cpu.ProcessorNameString).Trim() } else { '' }
        mhz = if ($cpu) { [int]$cpu.'~MHz' } else { 0 }
        cores = if ($smb) { [int]$smb.cores } else { 0 }
        threads = if ($smb) { [int]$smb.threads } else { 0 }
    }
    dimms = if ($smb) { @($smb.dimms) } else { @() }
    gpus = $gpus
    monitors = $monitors
} | ConvertTo-Json -Compress -Depth 6
