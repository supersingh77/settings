# Desktop library

Pure functions, extracted so they can be called without running a script. Nothing here reads the registry, touches a file, or calls an external process — every input arrives as a parameter and every output leaves as a return value.

The scripts in `../scripts/` dot-source these files and keep only the effects.

| File | Exposes | Used by |
|---|---|---|
| `winget-table.ps1` | `ConvertFrom-WingetUpgradeTable` — parses the fixed-width `winget upgrade` table into objects. Returns an empty array when no header is recognised, because the caller decides whether that means "no upgrades" or "the output changed shape" | `../scripts/update-system.ps1` |
| `audio-levels.ps1` | `Get-CaptureVerdict` — one verdict string from a mean/peak dB pair, using the thresholds documented in [`../scripts/README.md`](../scripts/README.md) | `../scripts/mic-check.ps1` |
| `version-match.ps1` | `Get-VersionMismatch` — does a version sentence in `software.md` agree with the installed-app list it is given? Returns `$null` when the claim cannot be checked (no digit, an explicit `ARP` note, no matching entry, no version) and a message when it disagrees | `../scripts/check-docs.ps1` |
| `inventory-docs.ps1` | Parses the read-only audit report and replaces generated Markdown sections while preserving the surrounding human-written notes | `../scripts/update-inventory.ps1`; `../tests/inventory-docs.tests.ps1` |

## Why these three and not the rest

Only functions that transform plain data earn a place here. Registry, process, and filesystem access stays in scripts at the edge.

`Get-VersionMismatch` is here rather than inside `check-docs.ps1` because its matching rule is the part most likely to be wrong: exact name first, then a vendor-style suffix (`PotPlayer` → `PotPlayer-64 bit`), never a loose prefix (`Git` must not match `GitHub CLI`). That is a decision about strings, so it belongs with the tested functions, not with the registry reading.

## Tests

[`../tests/run-tests.ps1`](../tests/run-tests.ps1) covers both files with no external dependency. Run it after changing anything here:

```powershell
pwsh device/desktop/tests/run-tests.ps1
```

Keep the files comment-free and side-effect-free. [`verify.ps1`](../scripts/verify.ps1) enforces the repository rules.
