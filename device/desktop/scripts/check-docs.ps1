[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [double]$FreeSpaceWarnGb = 1,
    [double]$FreeSpaceFailGb = 5,
    [int]$ClaimMaxAgeDays = 14
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\lib\version-match.ps1')

$months = @{ Jan = 1; Feb = 2; Mar = 3; Apr = 4; May = 5; Jun = 6; Jul = 7; Aug = 8; Sep = 9; Oct = 10; Nov = 11; Dec = 12 }
$datedClaim = '(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})'
$freeSpaceClaim = '(?:([A-Z]):\s*)?\**\s*([\d.]+) GB free'

function New-Finding([string]$Rule, [string]$Severity, [string]$Where, [string]$Detail) {
    [pscustomobject]@{ Rule = $Rule; Severity = $Severity; Where = $Where; Detail = $Detail }
}

function Get-LiveBuild {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    "$($cv.CurrentBuild).$($cv.UBR)"
}

function Get-LiveDrives {
    @([System.IO.DriveInfo]::GetDrives() | Where-Object IsReady)
}

function Get-InstalledApplication {
    $root = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    @(foreach ($key in $root) { Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object DisplayName })
}

function Get-DocLines([System.IO.FileInfo]$Doc) {
    Get-Content -LiteralPath $Doc.FullName
}

$findings = [System.Collections.Generic.List[object]]::new()
$docs = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.md' -File |
    Where-Object { $_.FullName -notmatch '\\\.git\\' } | Sort-Object FullName)
$desktopRoot = Join-Path $RepoRoot 'device\desktop'
$machineDocs = @($docs | Where-Object { $_.FullName.StartsWith($desktopRoot, [System.StringComparison]::OrdinalIgnoreCase) })
$liveDrives = Get-LiveDrives
$liveBuild = Get-LiveBuild
$liveLetters = @($liveDrives | ForEach-Object { $_.Name.Substring(0, 2) } | Sort-Object -Unique)

foreach ($doc in $docs) {
    $relative = $doc.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $text = [string](Get-Content -LiteralPath $doc.FullName -Raw)

    foreach ($match in [regex]::Matches($text, '\]\(([^)\s]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?:|mailto:|#|<)') { continue }
        $path = ($target -split '#')[0]
        if (-not $path) { continue }
        $resolved = $null
        try { $resolved = [System.IO.Path]::GetFullPath((Join-Path $doc.DirectoryName $path)) } catch { $resolved = $null }
        if (-not $resolved -or -not (Test-Path -LiteralPath $resolved)) {
            $findings.Add((New-Finding 'links' 'FAIL' $relative "link target does not exist: $target"))
        }
    }

    $outsideFences = [regex]::Replace($text, '(?ms)^\s*```.*?^\s*```\s*$', '')
    foreach ($match in [regex]::Matches($outsideFences, '`([^`]+)`')) {
        $claim = $match.Groups[1].Value.Trim().TrimEnd('/')
        if ($claim -notmatch '^(device|notes|inbox|outbox)/' -and $claim -notin @('README.md', 'CONTEXT.md')) { continue }
        if ($claim -notmatch '^[\w./\-]+$') { continue }
        $candidate = $null
        try { $candidate = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $claim)) } catch { $candidate = $null }
        if (-not $candidate -or -not (Test-Path -LiteralPath $candidate)) {
            $findings.Add((New-Finding 'paths' 'FAIL' $relative "names a repo path that does not exist: $claim"))
        }
    }
}

foreach ($doc in $machineDocs) {
    $relative = $doc.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $text = [string](Get-Content -LiteralPath $doc.FullName -Raw)

    foreach ($match in [regex]::Matches($text, 'build\s+\**(\d{5}\.\d+)')) {
        if ($match.Groups[1].Value -ne $liveBuild) {
            $findings.Add((New-Finding 'os-build' 'FAIL' $relative "claims build $($match.Groups[1].Value), machine reports $liveBuild"))
        }
    }
}

$documentedLetters = @{}
foreach ($doc in $machineDocs) {
    $relative = $doc.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $text = [string](Get-Content -LiteralPath $doc.FullName -Raw)
    foreach ($match in [regex]::Matches($text, '(?m)^\|\s*\*\*([A-Z]):\*\*\s*\|')) {
        $letter = $match.Groups[1].Value + ':'
        if (-not $documentedLetters.ContainsKey($letter)) { $documentedLetters[$letter] = @() }
        $documentedLetters[$letter] += $relative
    }
}
foreach ($letter in $documentedLetters.Keys) {
    if ($liveLetters -notcontains $letter) {
        $where = ($documentedLetters[$letter] | Select-Object -Unique) -join ', '
        $findings.Add((New-Finding 'drive-letters' 'FAIL' $where "documents drive $letter, which is not present on this machine"))
    }
}
foreach ($letter in $liveLetters) {
    if (-not $documentedLetters.ContainsKey($letter)) {
        $findings.Add((New-Finding 'drive-letters' 'WARN' 'device/desktop/' "drive $letter is present but documented nowhere"))
    }
}

foreach ($doc in $machineDocs) {
    $relative = $doc.FullName.Substring($RepoRoot.Length).TrimStart('\')
    foreach ($line in (Get-DocLines $doc)) {
        if ($line -notmatch 'GB free') { continue }
        if ($line -notmatch $datedClaim) { continue }

        $measured = [datetime]::new([int]$Matches[3], $months[$Matches[2]], [int]$Matches[1])
        if (((Get-Date).Date - $measured.Date).Days -gt $ClaimMaxAgeDays) {
            $findings.Add((New-Finding 'free-space' 'WARN' $relative "free-space claim measured $($measured.ToString('yyyy-MM-dd')) is older than $ClaimMaxAgeDays days"))
            continue
        }

        foreach ($match in [regex]::Matches($line, $freeSpaceClaim)) {
            $letter = if ($match.Groups[1].Value) { $match.Groups[1].Value + ':' } else { 'C:' }
            $drive = $liveDrives | Where-Object { $_.Name -eq "$letter\" } | Select-Object -First 1
            if (-not $drive) {
                $findings.Add((New-Finding 'free-space' 'FAIL' $relative "claims free space on $letter, which is not mounted"))
                continue
            }
            $claimed = [double]$match.Groups[2].Value
            $live = [math]::Round($drive.AvailableFreeSpace / 1GB, 1)
            $delta = [math]::Abs($claimed - $live)
            if ($delta -gt $FreeSpaceFailGb) {
                $findings.Add((New-Finding 'free-space' 'FAIL' $relative "claims $claimed GB free on $letter, machine reports $live GB"))
            }
            elseif ($delta -gt $FreeSpaceWarnGb) {
                $findings.Add((New-Finding 'free-space' 'WARN' $relative "claims $claimed GB free on $letter, machine reports $live GB"))
            }
        }
    }
}

$softwareDoc = Join-Path $RepoRoot 'device\desktop\software.md'
if (Test-Path -LiteralPath $softwareDoc) {
    $installed = Get-InstalledApplication
    $relative = $softwareDoc.Substring($RepoRoot.Length).TrimStart('\')
    foreach ($line in (Get-Content -LiteralPath $softwareDoc)) {
        if ($line -notmatch '^\|\s*\*\*(.+?)\*\*\s*\|\s*([^|]+?)\s*\|') { continue }
        $name = $Matches[1].Trim()
        $claimed = $Matches[2].Trim()
        $problem = Get-VersionMismatch -Name $name -Claimed $claimed -Installed $installed
        if ($problem) {
            $findings.Add((New-Finding 'app-versions' 'WARN' $relative "$name $problem"))
        }
    }
}

$failed = @($findings | Where-Object Severity -eq 'FAIL')
$warned = @($findings | Where-Object Severity -eq 'WARN')
$cFree = $liveDrives | Where-Object { $_.Name -eq 'C:\' } | Select-Object -First 1
$cFreeGb = if ($cFree) { [math]::Round($cFree.AvailableFreeSpace / 1GB, 1) } else { 0 }

Write-Host "check-docs  root=$RepoRoot  docs=$($docs.Count)  build=$liveBuild  drives=$($liveLetters -join ',')  C: free=$cFreeGb GB`n" -ForegroundColor Cyan

if ($findings.Count -eq 0) {
    Write-Host 'every checked claim matches the machine' -ForegroundColor Green
} else {
    $findings | Format-Table -AutoSize -Wrap
}

Write-Host ("{0} failure(s), {1} warning(s)" -f $failed.Count, $warned.Count) -ForegroundColor $(if ($failed.Count) { 'Red' } else { 'Green' })
if ($failed.Count -gt 0) {
    Write-Host 'Fix the doc, not the checker: re-run audit-state.ps1 for the measured value, then update the sentence.' -ForegroundColor Yellow
    exit 1
}
exit 0
