# Desktop library

Pure functions, extracted so they can be called without running a script. Nothing here reads the registry, touches a file, or calls an external process — every input arrives as a parameter and every output leaves as a return value.

The scripts in `../scripts/` dot-source these files and keep only the effects.

| File | Exposes | Used by |
|---|---|---|
| `winget-table.ps1` | `ConvertFrom-WingetUpgradeTable` — parses the fixed-width `winget upgrade` table into objects. Returns an empty array when no header is recognised, because the caller decides whether that means "no upgrades" or "the output changed shape" | `../scripts/update-system.ps1` |
| `audio-levels.ps1` | `Get-CaptureVerdict` — one verdict string from a mean/peak dB pair, using the thresholds documented in [`../scripts/README.md`](../scripts/README.md) | `../scripts/mic-check.ps1` |

## Why these two and not the rest

Only functions that decide something from plain data earn a place here. `Get-SmbiosTable` parses a registry blob and `Get-ClipFiles` walks a directory, so both keep their single call site until a second consumer or a test needs them.

## Tests

[`../tests/run-tests.ps1`](../tests/run-tests.ps1) covers both files with no external dependency. Run it after changing anything here:

```powershell
pwsh device/desktop/tests/run-tests.ps1
```

Keep the files comment-free and side-effect-free; [`../../../STYLE.md`](../../../STYLE.md) explains why, and `verify.ps1` enforces it.
