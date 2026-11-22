$InventoryDocs = Join-Path $TestRepoRoot 'device\desktop\lib\inventory-docs.ps1'
$UpdateInventory = Join-Path $TestRepoRoot 'device\desktop\scripts\update-inventory.ps1'

function Test-GeneratedHardwareSectionPreservesHumanNotes {
    . $InventoryDocs
    $document = "# Hardware`n`n## Detected hardware`n`nold`n`n## Network`n`nKeep this note.`n"
    $sections = @([pscustomobject]@{ Name = 'OS'; Lines = [System.Collections.Generic.List[string]]::new([string[]]@('| OS | Windows 11 |')) })
    $replacement = New-InventorySection 'Detected hardware' $sections @()
    $once = Set-GeneratedMarkdownSection $document 'Detected hardware' $replacement
    $twice = Set-GeneratedMarkdownSection $once 'Detected hardware' $replacement
    Assert-Equal $once $twice 'generated hardware must be idempotent'
    Assert-True ($once -match 'Keep this note\.') 'human-authored sections must be preserved'
    Assert-True ($once -match '### OS') 'live audit sections must be nested under the generated section'
}

function Test-SoftwareSectionFormatsInstalledAndPackagedApps {
    . $InventoryDocs
    $apps = [System.Collections.Generic.List[string]]::new()
    $apps.Add('- Example App 2.4.1')
    $packaged = [System.Collections.Generic.List[string]]::new()
    $packaged.Add('| Packaged | com.example.App | 1.0.0 |')
    $additional = [System.Collections.Generic.List[string]]::new()
    $additional.Add('| FFmpeg | 9.0.2 | C:\Program Files\FFmpeg\bin\ffmpeg.exe |')
    $sections = @(
        [pscustomobject]@{ Name = 'Installed apps (registry ARP)'; Lines = $apps },
        [pscustomobject]@{ Name = 'Additional applications (path inventory)'; Lines = $additional },
        [pscustomobject]@{ Name = 'Packaged apps (AppX registry)'; Lines = $packaged }
    )
    $document = New-DetectedSoftwareSection $sections
    Assert-True ($document -match '\| \*\*Example App\*\* \| 2\.4\.1 \|') 'registry app names and versions must become a table'
    Assert-True ($document -match '\| \*\*FFmpeg\*\* \| 9\.0\.2 \| C:\\Program Files') 'explicit executable targets must be included'
    Assert-True ($document -match '\| \*\*com\.example\.App\*\* \| 1\.0\.0 \|') 'packaged app versions must become a table'
}

function Test-HardwareInventoryFormatsVolumesAndOmitsUserFields {
    . $InventoryDocs
    $system = [System.Collections.Generic.List[string]]::new()
    $system.Add('| User | private-user |')
    $volumes = [System.Collections.Generic.List[string]]::new()
    $volumes.Add('| C:\ | _ | Fixed | 126.1 GB | 59.2 GB free |')
    $sections = @(
        [pscustomobject]@{ Name = 'OS'; Lines = $system },
        [pscustomobject]@{ Name = 'Volumes'; Lines = $volumes }
    )
    $document = New-InventorySection 'Detected hardware' $sections @('| User |')
    Assert-False ($document -match 'private-user') 'user details are not part of the hardware inventory'
    Assert-True ($document -match '\| \*\*C:\*\* \| _ \| Fixed \| 126\.1 GB \| 59\.2 GB free \|') 'volume readings must produce a checked Markdown table'
}

function Test-TaskbarInventoryFormatsOrderAndShortcutSet {
    . $InventoryDocs
    $taskbar = [System.Collections.Generic.List[string]]::new()
    $taskbar.Add('1. File Explorer')
    $taskbar.Add('2. Terminal')
    $taskbar.Add('Files in User Pinned\TaskBar:')
    $taskbar.Add('- File Explorer.lnk (2024-04-01)')
    $sections = @([pscustomobject]@{ Name = 'Taskbar pins (left to right)'; Lines = $taskbar })
    $document = New-DetectedTaskbarSection $sections
    Assert-True ($document -match '\| 1 \| File Explorer \|') 'the taskbar order must be retained'
    Assert-True ($document -match 'Desktop shortcut files: File Explorer\.lnk') 'desktop shortcut file names must be listed'
}

function Test-AuditReportParserKeepsNamedSections {
    . $InventoryDocs
    $sections = ConvertFrom-DesktopAuditReport "## OS`n`n| OS | Windows |`n`n## Done`nRead-only: nothing was changed.`n"
    Assert-Equal 1 $sections.Count 'the completion marker is not an inventory section'
    Assert-Equal 'OS' $sections[0].Name 'the report heading identifies the section'
    Assert-Equal '| OS | Windows |' $sections[0].Lines[1] 'the report table line is preserved'
}

function Test-InventoryDryRunDoesNotWriteDocuments {
    $fixture = New-FixtureDirectory 'inventory'
    $desktop = Join-Path $fixture 'device\desktop'
    foreach ($name in 'hardware.md', 'software.md', 'startmenu-taskbar.md') {
        $content = Get-Content -LiteralPath (Join-Path $TestRepoRoot "device\desktop\$name") -Raw
        New-FixtureFile $fixture "device\desktop\$name" $content | Out-Null
    }
    $before = @(
        foreach ($name in 'hardware.md', 'software.md', 'startmenu-taskbar.md') {
            (Get-FileHash -LiteralPath (Join-Path $desktop $name) -Algorithm SHA256).Hash
        }
    )
    $result = Invoke-Script -Path $UpdateInventory -Arguments @('-RepoRoot', $fixture, '-DryRun')
    Assert-True ($result.ExitCode -in @(0, 1)) ("inventory dry run should complete; output:`n" + $result.Output)
    $after = @(
        foreach ($name in 'hardware.md', 'software.md', 'startmenu-taskbar.md') {
            (Get-FileHash -LiteralPath (Join-Path $desktop $name) -Algorithm SHA256).Hash
        }
    )
    Assert-Equal ($before -join ',') ($after -join ',') 'dry run must not change either document'
}
