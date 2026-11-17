function Get-CaptureVerdict {
    param($MeanDb, $PeakDb)
    if ($null -eq $MeanDb) { return 'FAILED to open' }
    $mean = [double]$MeanDb
    $peak = if ($null -eq $PeakDb) { $null } else { [double]$PeakDb }
    if ($mean -le -70) { return 'SILENT - muted, dead, or privacy-blocked' }
    if ($mean -le -50) { return 'very quiet - raise Windows mic level' }
    if ($mean -le -30) { return 'quiet - usable with gain' }
    if ($null -ne $peak -and $peak -gt -3) { return 'hot - close to clipping' }
    return 'healthy'
}
