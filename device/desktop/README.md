# Desktop PC — Custom Build

> Active desktop for gaming and streaming.

## Documentation

| Doc | Covers |
|-----|--------|
| [Hardware](hardware.md) | Generated live hardware inventory and human notes on devices and known quirks |
| [Software](software.md) | Generated installed-software inventory and setup policy |
| [Taskbar & Start](startmenu-taskbar.md) | Generated taskbar pins and Start menu verification note |
| [Desktop Layout](desktop.md) | Placement rules for files and shortcuts |
| [Disk Cleanup](disk-cleanup.md) | Recurring cleanup procedures |
| [Declared state](declared/README.md) | Rebuildable intent: package manifest, OBS settings, registry tweaks |

## Setup Rules

1. **Storage:** C: = OS + core apps. Games/streaming software → **V:**. Recordings, VODs, archives → **Z:**. The letters are a deliberate choice; do not renumber them to match a textbook layout.
2. **Software:** follow the install and exclusion policy in [software.md](software.md).
3. **Display:** keep 300 Hz for desktop/gaming. MPRT must be **off** for Twinkle Tray brightness; MPRT has no DDC/CI control.
4. **Controllers:** the third-party Xbox 360 receiver opens Task View when the controller is off — unplug it or keep the controller on. PXN A7 shifter enumerates separately from the V10 Pro wheel.
5. **Inventory:** run `pwsh device/desktop/scripts/update-inventory.ps1 -DryRun` to detect drift. Apply the generated snapshot only when ready to review it with `git diff`; keep wanted changes or reconcile the desktop and rerun. Run `verify.ps1`, `check-docs.ps1` and `tests/run-tests.ps1` before committing.

## Scripts

Run commands from the repository root in PowerShell 7. Use `-?` for script parameters.

```powershell
pwsh device/desktop/scripts/verify.ps1
pwsh device/desktop/scripts/check-docs.ps1
pwsh device/desktop/tests/run-tests.ps1
pwsh device/desktop/scripts/update-inventory.ps1 -DryRun
pwsh device/desktop/scripts/update-system.ps1 -DryRun
pwsh device/desktop/scripts/cleanup-system.ps1 -DryRun
```

Run system updates and cleanup only after reviewing their dry runs. Cleanup deletes temporary files and caches, empties the Recycle Bin, and flushes DNS. The update script skips PowerShell itself; update PowerShell from Command Prompt because its installer closes the current PowerShell session.

Audio and video utilities:

- `mic-check.ps1` records every DirectShow microphone for five seconds by default; `-Seconds` changes the duration.
- `voice-compare.ps1 -Path <folder>` compares recordings. Include five seconds of room tone before speaking.
- `join-videos.ps1 -Folder <folder>` joins compatible clips without re-encoding.
- `remux-audio-back.ps1 -Video <file> -Audio <file>` replaces a video's audio track.
