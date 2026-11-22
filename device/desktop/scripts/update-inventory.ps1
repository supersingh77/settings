[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [switch]$Apply,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\lib\inventory-docs.ps1')

function Get-DesktopAuditReport([string]$AuditScript) {
    $reportFile = New-TemporaryFile
    try {
        & pwsh -NoProfile -File $AuditScript -OutFile $reportFile.FullName
        if ($LASTEXITCODE -ne 0) { throw "audit-state.ps1 failed with exit code $LASTEXITCODE" }
        return Get-Content -LiteralPath $reportFile.FullName -Raw
    }
    finally {
        Remove-Item -LiteralPath $reportFile.FullName -Force -ErrorAction SilentlyContinue
    }
}

function New-ProposedDocuments([hashtable]$Documents, [hashtable]$Paths, [object[]]$Sections) {
    $hardwareNames = @('OS', 'Firmware / CPU', 'GPU / monitor', 'Display modes', 'Problem devices', 'Volumes')
    $hardwareSections = @($Sections | Where-Object { $_.Name -in $hardwareNames })
    $hardware = New-InventorySection 'Detected hardware' $hardwareSections @('| Computer |', '| User |', '| PowerShell |')
    $software = New-DetectedSoftwareSection @($Sections | Where-Object { $_.Name -in @('Installed apps (registry ARP)', 'Additional applications (path inventory)', 'Packaged apps (AppX registry)', 'Steam libraries', 'Looks installed but is not') })
    $taskbar = New-DetectedTaskbarSection $Sections
    $proposed = @{}
    foreach ($name in $paths.Keys) {
        $title = switch ($name) {
            'hardware.md' { 'Detected hardware' }
            'software.md' { 'Detected software' }
            'startmenu-taskbar.md' { 'Detected taskbar pins' }
        }
        $replacement = switch ($name) {
            'hardware.md' { $hardware }
            'software.md' { $software }
            'startmenu-taskbar.md' { $taskbar }
        }
        $proposed[$name] = [pscustomobject]@{
            Path = $paths[$name]
            Before = $Documents[$name]
            After = Set-GeneratedMarkdownSection $Documents[$name] $title $replacement
        }
    }
    return $proposed
}

try {
    $auditScript = Join-Path $PSScriptRoot 'audit-state.ps1'
    $report = Get-DesktopAuditReport $auditScript
    $sections = ConvertFrom-DesktopAuditReport $report
    $paths = @{
        'hardware.md' = Join-Path $RepoRoot 'device\desktop\hardware.md'
        'software.md' = Join-Path $RepoRoot 'device\desktop\software.md'
        'startmenu-taskbar.md' = Join-Path $RepoRoot 'device\desktop\startmenu-taskbar.md'
    }
    $documents = @{}
    foreach ($name in $paths.Keys) { $documents[$name] = Get-Content -LiteralPath $paths[$name] -Raw }
    $proposed = New-ProposedDocuments $documents $paths $sections
    $changed = @($proposed.Keys | Where-Object { $proposed[$_].Before -ne $proposed[$_].After })
    if (-not $changed.Count) {
        Write-Output 'Generated hardware and software sections match live readings.'
        exit 0
    }
    if ($Apply -and -not $DryRun) {
        foreach ($name in $changed) {
            [System.IO.File]::WriteAllText($proposed[$name].Path, $proposed[$name].After, [System.Text.UTF8Encoding]::new($false))
        }
        Write-Output "Updated: $($changed -join ', ')"
        Write-Output 'Review with: git diff device/desktop/hardware.md device/desktop/software.md device/desktop/startmenu-taskbar.md'
        exit 0
    }
    Write-Output "Generated sections differ in: $($changed -join ', ')"
    if ($DryRun) { Write-Output 'Dry run: no repository files were changed.' }
    else { Write-Output 'Run with -Apply to write the generated sections, then review git diff.' }
    exit 1
}
catch {
    Write-Error "Inventory update failed: $($_.Exception.Message)"
    exit 2
}
