function ConvertFrom-DesktopAuditReport([string]$Report) {
    $sections = [System.Collections.Generic.List[object]]::new()
    $current = $null
    foreach ($line in ($Report -split "`r?`n")) {
        if ($line -match '^## (.+)$') {
            if ($Matches[1] -eq 'Done') {
                $current = $null
                continue
            }
            $current = [pscustomobject]@{ Name = $Matches[1]; Lines = [System.Collections.Generic.List[string]]::new() }
            $sections.Add($current)
            continue
        }
        if ($current -and $line -ne 'Read-only: nothing was changed.') { $current.Lines.Add($line) }
    }
    return ,$sections.ToArray()
}

function New-InventorySection([string]$Title, [object[]]$Sections, [string[]]$ExcludedLines = @()) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("## $Title")
    $lines.Add('')
    $lines.Add('> Generated from live desktop readings by `update-inventory.ps1`. Run it with `-Apply` to refresh this section.')
    foreach ($section in $Sections) {
        $sectionLines = [System.Collections.Generic.List[string]]::new()
        foreach ($line in $section.Lines) {
            if ($ExcludedLines | Where-Object { $line.StartsWith($_) }) { continue }
            $sectionLines.Add($line)
        }
        while ($sectionLines.Count -and $sectionLines[0] -eq '') { $sectionLines.RemoveAt(0) }
        while ($sectionLines.Count -and $sectionLines[$sectionLines.Count - 1] -eq '') { $sectionLines.RemoveAt($sectionLines.Count - 1) }
        if (-not $sectionLines.Count) { continue }
        $lines.Add('')
        $lines.Add("### $($section.Name)")
        $lines.Add('')
        if ($section.Name -eq 'Volumes') {
            $lines.Add('| Drive | Label | Type | Capacity | Free |')
            $lines.Add('|---|---|---|---|---|')
            foreach ($line in $sectionLines) {
                $values = @($line.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
                if ($values.Count -ne 5) { continue }
                $drive = $values[0].TrimEnd('\')
                $lines.Add("| **$drive** | $($values[1]) | $($values[2]) | $($values[3]) | $($values[4]) |")
            }
            continue
        }
        $lines.Add('```text')
        $lines.AddRange([string[]]$sectionLines)
        $lines.Add('```')
    }
    return ($lines -join "`n").TrimEnd() + "`n"
}

function New-DetectedSoftwareSection([object[]]$Sections) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('## Detected software')
    $lines.Add('')
    $lines.Add('> Generated from live desktop readings by `update-inventory.ps1`. Run it with `-Apply` to refresh this section.')
    $lines.Add('> Sources: uninstall and per-user package registries plus executable targets in `declared/audit-targets.json`. Portable apps outside those targets are not included.')
    foreach ($section in $Sections) {
        if ($section.Name -eq 'Installed apps (registry ARP)') {
            $lines.Add('')
            $lines.Add('### Registry applications')
            $lines.Add('')
            $lines.Add('| Application | Version |')
            $lines.Add('|---|---|')
            foreach ($line in $section.Lines) {
                if ($line -notmatch '^- (.+)$') { continue }
                $entry = $Matches[1]
                if ($entry -match '^(.+?)\s+([0-9][^\s]*)$') {
                    $name = $Matches[1].Trim()
                    $version = $Matches[2]
                }
                else {
                    $name = $entry.Trim()
                    $version = 'unreported'
                }
                $lines.Add("| **$name** | $version |")
            }
        }
        if ($section.Name -eq 'Packaged apps (AppX registry)') {
            $lines.Add('')
            $lines.Add('### Packaged applications')
            $lines.Add('')
            $lines.Add('| Application | Version |')
            $lines.Add('|---|---|')
            foreach ($line in $section.Lines) {
                if ($line -match '^\| Packaged \| (.+?) \| (.+?) \|$') {
                    $lines.Add("| **$($Matches[1])** | $($Matches[2]) |")
                }
            }
        }
        if ($section.Name -eq 'Additional applications (path inventory)') {
            $lines.Add('')
            $lines.Add('### Additional applications')
            $lines.Add('')
            $lines.Add('| Application | Version | Location |')
            $lines.Add('|---|---|---|')
            foreach ($line in $section.Lines) {
                if ($line -match '^\| (.+?) \| (.+?) \| (.+?) \|$') {
                    $lines.Add("| **$($Matches[1])** | $($Matches[2]) | $($Matches[3]) |")
                }
            }
        }
        if ($section.Name -in @('Steam libraries', 'Looks installed but is not')) {
            $sectionLines = [System.Collections.Generic.List[string]]::new([string[]]$section.Lines)
            while ($sectionLines.Count -and $sectionLines[0] -eq '') { $sectionLines.RemoveAt(0) }
            while ($sectionLines.Count -and $sectionLines[$sectionLines.Count - 1] -eq '') { $sectionLines.RemoveAt($sectionLines.Count - 1) }
            $heading = if ($section.Name -eq 'Steam libraries') { 'Steam libraries' } else { 'Folders that are not installed apps' }
            $lines.Add('')
            $lines.Add("### $heading")
            $lines.Add('')
            $lines.Add('```text')
            $lines.AddRange([string[]]$sectionLines)
            $lines.Add('```')
        }
    }
    return ($lines -join "`n").TrimEnd() + "`n"
}

function New-DetectedTaskbarSection([object[]]$Sections) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('## Detected taskbar pins')
    $lines.Add('')
    $lines.Add('> Generated from the live Taskband data by `update-inventory.ps1`. Run it with `-Apply` to refresh this section.')
    $taskbar = $Sections | Where-Object Name -eq 'Taskbar pins (left to right)' | Select-Object -First 1
    if (-not $taskbar) { return ($lines -join "`n") + "`n" }
    $lines.Add('')
    $lines.Add('| Order | Pin |')
    $lines.Add('|---|---|')
    $filesStarted = $false
    foreach ($line in $taskbar.Lines) {
        if ($line -eq 'Files in User Pinned\TaskBar:') {
            $filesStarted = $true
            continue
        }
        if ($line -match '^(\d+)\. (.+)$' -and -not $filesStarted) {
            $lines.Add("| $($Matches[1]) | $($Matches[2]) |")
        }
    }
    $files = @($taskbar.Lines | Where-Object { $_ -match '^- .+\.lnk(?: \(\d{4}-\d{2}-\d{2}\))?$' } | ForEach-Object { $_ -replace '^\- ', '' -replace ' \(\d{4}-\d{2}-\d{2}\)$', '' })
    if ($files.Count) {
        $lines.Add('')
        $lines.Add('Desktop shortcut files: ' + ($files -join ', '))
    }
    return ($lines -join "`n").TrimEnd() + "`n"
}

function Set-GeneratedMarkdownSection([string]$Document, [string]$Title, [string]$Replacement) {
    $lines = @($Document -split "`r?`n")
    $heading = "## $Title"
    $start = [Array]::IndexOf($lines, $heading)
    if ($start -lt 0) { return ($Document.TrimEnd() + "`n`n" + $Replacement).TrimEnd() + "`n" }
    $end = $lines.Length
    for ($index = $start + 1; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -match '^## ') {
            $end = $index
            break
        }
    }
    $before = @()
    if ($start -gt 0) { $before = @($lines[0..($start - 1)]) }
    $after = @()
    if ($end -lt $lines.Length) { $after = @($lines[$end..($lines.Length - 1)]) }
    $inserted = @($Replacement.TrimEnd() -split "`r?`n")
    $result = @($before) + $inserted
    if ($after.Count -and $result.Count -gt 0 -and $result[$result.Count - 1] -ne '') { $result += '' }
    $result += @($after)
    return ($result -join "`n").TrimEnd() + "`n"
}
