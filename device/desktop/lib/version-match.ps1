function Get-VersionMismatch {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Claimed,
        [AllowNull()][AllowEmptyCollection()]$Installed
    )

    $claim = $Claimed.Trim()
    if ($claim -notmatch '^\d') { return $null }
    if ($claim -match '\bARP\b') { return $null }

    $entries = @($Installed | Where-Object { $_.DisplayName })
    $exact = @($entries | Where-Object { $_.DisplayName -eq $Name })
    if ($exact.Count -gt 0) { $candidates = $exact }
    else {
        $candidates = @($entries | Where-Object {
            $_.DisplayName.StartsWith($Name + ' ') -or
            $_.DisplayName.StartsWith($Name + '-') -or
            $_.DisplayName.StartsWith($Name + ':')
        })
    }
    if ($candidates.Count -eq 0) { return $null }

    $versions = @($candidates | ForEach-Object { [string]$_.DisplayVersion } | Where-Object { $_ })
    if ($versions.Count -eq 0) { return $null }
    if ($versions | Where-Object { $_ -eq $claim -or $_.StartsWith($claim) }) { return $null }

    "claims $claim, installed reports $($versions -join ', ')"
}
