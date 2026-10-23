# Desktop Scripts

> Updated: 23 Oct 2026 | Run PowerShell scripts with **PowerShell 7**.

| Script | Purpose | Status |
|--------|---------|--------|
| `update-system.ps1` | Refreshes winget sources, lists upgrades, then runs `winget upgrade --all`. Supports `-DryRun`; logs to `%LOCALAPPDATA%\DesktopMaintenance\logs`. | Active |
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

- **AutoHotkey v2 is not installed.** The `.ahk` scripts are dormant unless you install it; they are kept for the old mouse workaround.
- `cleanup-system.ps1 -DryRun` is the safe first run.
- `join-videos.ps1` expects clips with the same codec/resolution/fps/audio; otherwise use the re-encode fallback in `notes/ffmpeg-video-workflow.md`.
