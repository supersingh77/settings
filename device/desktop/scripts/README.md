# Desktop Scripts

> Updated: 4 Nov 2026 | Run PowerShell scripts with **PowerShell 7**.

| Script | Purpose | Status |
|--------|---------|--------|
| `update-system.ps1` | Refreshes winget sources, lists upgrades, then upgrades them **one package at a time** (a failure no longer aborts the run), with `Microsoft.PowerShell` filtered out (see Notes). Supports `-DryRun`; logs to `%LOCALAPPDATA%\DesktopMaintenance\logs`. | Active |
| `cleanup-system.ps1` | Temp files, DISM component cleanup, Recycle Bin, DNS, Delivery Optimization. Supports `-DryRun`; reports staged-installer size without deleting it. | Active |
| `join-videos.ps1` | Lossless FFmpeg concat of clips in a folder, ordered by filename. Resolves `ffmpeg` from PATH or `C:\Program Files\FFmpeg\bin`. | Active |
| `disable-scroll.ahk` | Blocks mouse-wheel events; exit with `Ctrl+Alt+Q`. | Legacy — workaround for the old faulty Logitech wheel. Not needed with the MCHOSE L7 Pro. |
| `enable-scroll.ahk` | Closes the `disable-scroll.ahk` instance. | Legacy |
| `enable-autostart.ahk` | Adds `disable-scroll.ahk` to the Startup folder. | Legacy |
| `disable-autostart.ahk` | Removes that Startup shortcut. | Legacy |

## User Aliases (PowerShell 7)

Defined in `C:\Users\amar\Documents\PowerShell\profile.ps1` — **current user only**, no machine-wide PATH changes:

```powershell
update            # refresh sources, list, then upgrade all winget packages
update -DryRun    # list available upgrades only
cleanup           # run maintenance
cleanup -DryRun   # show what cleanup would delete
```

Windows PowerShell 5.1 is left alone: its execution policy is `Restricted`, so a profile there would not load. Use PowerShell 7.

## Notes

- **PowerShell itself is excluded from `update`.** The PowerShell MSI replaces the binaries of the running engine, so Windows Installer closes `pwsh` mid-install and rolls back with MSI 1603 (failed 24 Oct, 1 Nov, 3 Nov 2026; the transcript ends at `The pipeline has been stopped.`). Run the PowerShell upgrade from **Command Prompt**, not from PowerShell:

  ```bat
  winget upgrade --id Microsoft.PowerShell --exact --accept-package-agreements --accept-source-agreements
  ```

  Every open PowerShell window closes during the install — that is the installer, not a crash. Re-run `update` afterwards to confirm the rest is current. (This is how 7.6.9 went in on 4 Nov 2026.)
- **One package at a time.** winget 1.29.380 has no `--exclude` option for `upgrade`, so the script parses the `winget upgrade` table itself, drops the guarded ids, and runs `winget upgrade --id <id> --exact` per package. A failure is listed at the end instead of aborting the rest of the run.
- **Downloads go through WinINET, not Delivery Optimization.** On 4 Nov 2026 `update` sat on `Downloading …gh_2.103.3_windows_amd64.msi` for 4 minutes: winget's diag log shows `DeliveryOptimization downloading from url:` and then nothing at all. `%LOCALAPPDATA%\Microsoft\WinGet\Settings\settings.json` now sets `network.downloader` to `wininet` (schema: [aka.ms/winget-settings.schema.json](https://aka.ms/winget-settings.schema.json)). If a download ever looks frozen again, check that file first.
- **Winget output is not piped, so it is not in the transcript.** winget only draws its progress bar when stdout is a console; piping hid a stalled download. Per-package winget text therefore goes straight to the terminal — for diagnostics use `%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir`.
- **AutoHotkey v2 is not installed.** The `.ahk` scripts are dormant unless you install it; they are kept for the old mouse workaround.
- `cleanup-system.ps1 -DryRun` is the safe first run.
- `join-videos.ps1` expects clips with the same codec/resolution/fps/audio; otherwise use the re-encode fallback in `notes/ffmpeg-video-workflow.md`.
