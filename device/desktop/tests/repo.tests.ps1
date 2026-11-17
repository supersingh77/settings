$VerifyScript = Join-Path $TestRepoRoot 'device\desktop\scripts\verify.ps1'
$AuditScript = Join-Path $TestRepoRoot 'device\desktop\scripts\audit-state.ps1'
$JoinScript = Join-Path $TestRepoRoot 'device\desktop\scripts\join-videos.ps1'
$TweaksScript = Join-Path $TestRepoRoot 'device\desktop\declared\tweaks.ps1'

function Test-VerifyPassesOnThisRepo {
    $result = Invoke-Script -Path $VerifyScript -Arguments @('-RepoRoot', $TestRepoRoot)
    Assert-Equal 0 $result.ExitCode ("verify must pass on the committed repo; output:`n" + $result.Output)
}

function Test-VerifyRejectsAComment {
    $fixture = New-FixtureDirectory 'comment'
    New-FixtureFile $fixture 'README.md' 'bad.ps1 is listed in this index' | Out-Null
    New-FixtureFile $fixture 'bad.ps1' "`$value = 1`n# stale explanation`n" | Out-Null

    $result = Invoke-Script -Path $VerifyScript -Arguments @('-RepoRoot', $fixture)
    Assert-Equal 1 $result.ExitCode 'a comment must fail the build'
    Assert-True ($result.Output -match 'no-comments') 'the failure must name the no-comments rule'
    Assert-False ($result.Output -match 'indexed') 'the fixture is indexed, so only the comment rule may fail'
}

function Test-VerifyRejectsInvalidDeclaredJson {
    $fixture = New-FixtureDirectory 'json'
    New-FixtureFile $fixture 'declared\broken.json' '{ "declared": broken' | Out-Null

    $result = Invoke-Script -Path $VerifyScript -Arguments @('-RepoRoot', $fixture)
    Assert-Equal 1 $result.ExitCode 'invalid declared JSON must fail the build'
    Assert-True ($result.Output -match 'json-valid') 'the failure must name the json-valid rule'
}

function Test-AuditDryRunWritesNoOutFile {
    $fixture = New-FixtureDirectory 'audit'
    $target = Join-Path $fixture 'audit.md'

    $result = Invoke-Script -Path $AuditScript -Arguments @('-OutFile', $target, '-DryRun')
    Assert-Equal 0 $result.ExitCode 'the audit must succeed without writing'
    Assert-False (Test-Path -LiteralPath $target) 'a dry run must not create the report'
}

function Test-JoinVideosDryRunWritesNothing {
    $fixture = New-FixtureDirectory 'join'
    New-FixtureFile $fixture 'a.mp4' 'clip' | Out-Null
    New-FixtureFile $fixture 'b.mp4' 'clip' | Out-Null
    New-FixtureFile $fixture 'joined.mp4' 'output of an earlier run' | Out-Null

    $result = Invoke-Script -Path $JoinScript -Arguments @('-Folder', $fixture, '-DryRun')
    Assert-Equal 0 $result.ExitCode ("the join must succeed in dry run; output:`n" + $result.Output)
    Assert-False (Test-Path -LiteralPath (Join-Path $fixture 'clips.txt')) 'a dry run must not write the concat list'
    Assert-False (Test-Path -LiteralPath (Join-Path $fixture 'joined.mp4.bak')) 'a dry run must not back anything up'

    if (Get-FFmpegOrNull) {
        Assert-True ($result.Output -match 'Found 2 clips') 'a previous joined.mp4 must not be counted as a source clip'
    }
}

function Test-DeclaredTweaksAreConverged {
    $result = Invoke-Script -Path $TweaksScript -Arguments @('-DryRun')
    Assert-Equal 0 $result.ExitCode ("the declared dry run must succeed; output:`n" + $result.Output)
    Assert-True ($result.Output -match 'summary: 0 change\(s\)') ("the machine is not at declared state - run tweaks.ps1 -DryRun to see the diff. output:`n" + $result.Output)
}
