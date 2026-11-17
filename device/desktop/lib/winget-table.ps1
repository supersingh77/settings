function ConvertFrom-WingetUpgradeTable {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $rows = @()
    $headerIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^Name\s+Id\s+Version\s+Available\s+Source\s*$') {
            $headerIndex = $i
            break
        }
    }
    if ($headerIndex -lt 0) { return $rows }

    $header = $Lines[$headerIndex]
    $idCol = $header.IndexOf('Id')
    $verCol = $header.IndexOf('Version')
    $availCol = $header.IndexOf('Available')
    $srcCol = $header.IndexOf('Source')
    if ($idCol -lt 1 -or $verCol -le $idCol -or $availCol -le $verCol -or $srcCol -le $availCol) {
        return $rows
    }

    for ($i = $headerIndex + 1; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^-+\s*$') { continue }
        if ($line.Length -le $srcCol) { break }
        $id = $line.Substring($idCol, $verCol - $idCol).Trim()
        if (-not $id) { break }

        $rows += [pscustomobject]@{
            Name      = $line.Substring(0, $idCol).Trim()
            Id        = $id
            Version   = $line.Substring($verCol, $availCol - $verCol).Trim()
            Available = $line.Substring($availCol, $srcCol - $availCol).Trim()
            Source    = $line.Substring($srcCol).Trim()
        }
    }
    return $rows
}
