. (Join-Path $TestRepoRoot 'device\desktop\lib\audio-levels.ps1')

function Test-UnreadableDeviceFails {
    Assert-Equal 'FAILED to open' (Get-CaptureVerdict -MeanDb $null -PeakDb $null) 'no measurement means the device did not open'
}

function Test-DigitalSilenceIsNotQuiet {
    Assert-True ((Get-CaptureVerdict -MeanDb -91 -PeakDb -88) -match '^SILENT') 'digital silence is a dead device, not a quiet room'
    Assert-True ((Get-CaptureVerdict -MeanDb -70 -PeakDb -60) -match '^SILENT') 'exactly -70 dB is still silent'
    Assert-True ((Get-CaptureVerdict -MeanDb -69.9 -PeakDb -60) -match '^very quiet') 'one step above -70 is quiet, not silent'
}

function Test-QuietBands {
    Assert-True ((Get-CaptureVerdict -MeanDb -50 -PeakDb -30) -match '^very quiet') '-50 belongs to the very quiet band'
    Assert-True ((Get-CaptureVerdict -MeanDb -49.9 -PeakDb -30) -match '^quiet') '-49.9 belongs to the quiet band'
    Assert-True ((Get-CaptureVerdict -MeanDb -30 -PeakDb -20) -match '^quiet') '-30 belongs to the quiet band'
    Assert-True ((Get-CaptureVerdict -MeanDb -29.9 -PeakDb -20) -match '^healthy') '-29.9 with headroom is healthy'
}

function Test-ClippingOutranksLevel {
    Assert-True ((Get-CaptureVerdict -MeanDb -12 -PeakDb -2) -match '^hot') 'a loud mean that clips is hot'
    Assert-True ((Get-CaptureVerdict -MeanDb -18 -PeakDb -3) -match '^healthy') 'a peak at -3 is not yet clipping'
}

function Test-MissingPeakDoesNotThrow {
    Assert-True ((Get-CaptureVerdict -MeanDb -18 -PeakDb $null) -match '^healthy') 'a missing peak falls back to the level verdict'
}

function Test-NumericStringsCoerce {
    Assert-True ((Get-CaptureVerdict -MeanDb '-91' -PeakDb '-88') -match '^SILENT') 'a negative dB string is still silence, not a lexicographic comparison'
    Assert-True ((Get-CaptureVerdict -MeanDb '-18' -PeakDb '-6') -match '^healthy') 'a healthy string pair must not fall through to hot'
}
