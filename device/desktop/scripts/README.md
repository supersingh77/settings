# Desktop script commands

Run from the repository root in PowerShell 7. Use `-?` on a script for its parameters.

## Inventory and checks

```powershell
pwsh device/desktop/scripts/update-inventory.ps1 -DryRun
pwsh device/desktop/scripts/update-inventory.ps1 -Apply
pwsh device/desktop/scripts/verify.ps1
pwsh device/desktop/scripts/check-docs.ps1
pwsh device/desktop/tests/run-tests.ps1
```

Review the inventory diff before keeping generated changes. `-Apply` only updates marked sections in the hardware, software, and taskbar documents.

## Maintenance

```powershell
pwsh device/desktop/scripts/update-system.ps1 -DryRun
pwsh device/desktop/scripts/update-system.ps1
pwsh device/desktop/scripts/cleanup-system.ps1 -DryRun
pwsh device/desktop/scripts/cleanup-system.ps1
```

Run cleanup with `-DryRun` first. Applying it deletes temporary files and caches, empties the Recycle Bin, and flushes DNS. The update script skips PowerShell itself; update PowerShell from Command Prompt because its installer closes the running PowerShell session.

## Audio and video utilities

- `mic-check.ps1` records every DirectShow microphone for five seconds by default; `-Seconds` changes the duration.
- `voice-compare.ps1 -Path <folder>` compares recordings. Include five seconds of room tone before speaking in each recording.
- `join-videos.ps1 -Folder <folder>` joins compatible clips without re-encoding.
- `remux-audio-back.ps1 -Video <file> -Audio <file>` replaces a video's audio track.
