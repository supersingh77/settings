# Desktop tests

Invariants, not unit-test ceremony. The runner uses plain PowerShell and temporary fixtures; it does not need a module download.

```powershell
pwsh device/desktop/tests/run-tests.ps1
pwsh device/desktop/tests/run-tests.ps1 -DryRun           # list the suites, create nothing
pwsh device/desktop/tests/run-tests.ps1 -Filter 'repo*'   # one suite
```

Exit 1 on any failure, so it can gate a commit next to `verify.ps1`.

| File | Covers |
|---|---|
| `run-tests.ps1` | The runner: discovers `*.tests.ps1`, provides `Assert-Equal` / `Assert-True` / `Assert-False` and temp-fixture helpers, runs every `Test-*` function it finds, removes fixtures, exits 1 if anything failed |
| `winget-table.tests.ps1` | `ConvertFrom-WingetUpgradeTable` against aligned tables: column extraction, dotted ids, separator and blank lines, trailing text, empty input |
| `audio-levels.tests.ps1` | `Get-CaptureVerdict` at the band boundaries the README documents: −70 dB is silent, −69.9 is very quiet, −50/−30 band edges, clipping outranks level |
| `version-match.tests.ps1` | `Get-VersionMismatch`: exact match, prefix versions (`7.6.10` vs `7.6.10.0`), vendor suffixes, `Git` not poaching `GitHub CLI`, and every un-checkable claim returning nothing rather than guessing |
| `repo.tests.ps1` | The repo's own contracts: `verify.ps1` passes and rejects a comment or invalid declared JSON; `check-docs.ps1` passes here and rejects broken links, stale claims and unmounted drives; `audit-state.ps1` reads `declared/audit-targets.json`; dry runs do not write; video joins exclude their own prior output; declared-state preview reports changes separately from failures |
| `inventory-docs.tests.ps1` | Generated inventory sections replace deterministically, preserve human notes, format registry and explicit app targets, volumes, and taskbar readings, and keep `-DryRun` read-only |

## Conventions

- One behaviour per `Test-*` function. The function name is the failure message, so it must state the property, not the implementation.
- Fixtures come from `New-FixtureDirectory` / `New-FixtureFile`; never write into the repo or a real user folder.
- A test file may only call runner helpers and assert. If it needs a write, add a helper to the runner — that keeps `verify.ps1`'s dry-run rule satisfiable.
- `repo.tests.ps1` is machine-specific by design: it asserts this desktop is at its declared state. On another machine it will fail, correctly, until that machine is converged.
