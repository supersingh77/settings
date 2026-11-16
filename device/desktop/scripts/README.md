# Desktop Scripts

> Updated: 16 Nov 2026 | Run PowerShell scripts with **PowerShell 7**.
> Everything here is safe to read before running: `audit-state.ps1` writes nothing, and the maintenance scripts accept `-DryRun`.

| Script | Purpose | Status |
|--------|---------|--------|
| `verify.ps1` | **Read-only** check of the repo against its own rules from [`STYLE.md`](../../../STYLE.md): scripts parse, no comments outside `#Requires`, writers expose `-DryRun`, `declared/*.json` is valid, every script is listed in its folder README. Exit 1 on failure; `-Strict` also fails on the aspirational rules. | Active — run before committing |
| `audit-state.ps1` | **Read-only** snapshot of every fact the desktop docs claim: OS/build, board/BIOS/CPU, RAM (SMBIOS SPD: size, type, rated **and** configured speed, part numbers), GPU + VRAM + monitor driver, live display modes, problem devices, volumes, ARP inventory, taskbar pin order, Steam libraries, "looks installed but isn't" traps, recordings parked on C:. Supports `-OutFile`, `-Since <date>`. | Active — run this before editing any desktop doc |
| `update-system.ps1` | Refreshes winget sources, lists upgrades, then upgrades them **one package at a time** (a failure no longer aborts the run), with `Microsoft.PowerShell` filtered out (see Notes). Supports `-DryRun`; logs to `%LOCALAPPDATA%\DesktopMaintenance\logs`. | Active |
| `cleanup-system.ps1` | Temp files, DISM component cleanup, Recycle Bin, DNS, Delivery Optimization. Supports `-DryRun`; reports staged-installer size without deleting it. | Active |
| `mic-check.ps1` | Records a few seconds from each microphone and reports mean/peak dB with a verdict. Catches the two failures that silently ruin recordings: a muted/sleeping device (digital silence) and one that is alive but far too quiet. Read-only, no admin. | Active — run before trusting any mic |
| `voice-compare.ps1` | Objective A/B of voice recordings: noise floor, voice level, SNR, integrated loudness, headroom and 3-band spectral balance, with a verdict per file. Needs a 5 s silent lead-in per recording. Read-only. | Active — use to pick a microphone |
| `join-videos.ps1` | Lossless FFmpeg concat of clips in one folder, ordered by filename (chronological for OBS/phone timestamps). `-Folder` required; `-Output` defaults to `joined.mp4`; `-Extensions` overridable. All clips must share codec/resolution/fps/audio — otherwise it fails and you want the re-encode fallback in [`notes/ffmpeg-video-workflow.md`](../../../notes/ffmpeg-video-workflow.md). Supports `-DryRun`. | Active |
| `remux-audio-back.ps1` | Puts a cleaned/noise-reduced audio file back into the original video with `-c:v copy`, then proves the video packets are bit-identical via MD5. Transcodes audio to AAC only when the codec is not MP4-compatible. | Active |

## Reading `mic-check.ps1`

| Mean level | Verdict | Meaning |
|---|---|---|
| −70 dB or lower | SILENT | muted, dead, or blocked — treat as unusable, do not "turn it up" |
| −50 to −70 | very quiet | Windows input level too low |
| −30 to −50 | quiet | usable, raise gain in OBS |
| above −30, peak below −3 | healthy | in range |
| peak above −3 | hot | clipping risk, lower gain |

Target for voice: mean around **−18 dB**, peaks **−12 to −6 dB**. Digital silence (≈ −90 dB) never means a quiet room — a live mic always shows room tone around −45 to −60 dB.

**Known false negative:** a device can read −91 dB on one pass and −40 dB on the next (still opening, or held by another app). Two passes, or one while speaking, before writing a mic off.

## User Aliases (PowerShell 7)

Defined in `C:\Users\amar\Documents\PowerShell\profile.ps1` — **current user only**, no machine-wide PATH changes:

```powershell
update            # refresh sources, list, then upgrade all winget packages
update -DryRun    # list available upgrades only
cleanup           # run maintenance
cleanup -DryRun   # show what cleanup would delete
audit             # no alias yet: run the script directly
```

Windows PowerShell 5.1 is left alone: its execution policy is `Restricted`, so a profile there would not load. Use PowerShell 7.

## Notes

- **audit-state.ps1 exists because of a real mistake.** The 23 Oct 2026 doc pass wrote drive letters (`E:`/`D:`) from memory; the machine has only `C:`, `V:`, `Z:`, and six files were wrong for three weeks. The script now prints the measured values so the docs can be checked against them in one command. It is written for agent sandboxes, where WMI/CIM, `Get-Volume`, `Get-AppxPackage`, UI Automation and `Export-StartLayout` are all blocked — it uses registry reads, .NET, and on-disk files instead.
- **winget dies inside a sandboxed agent session** with `0x8A150001` on every verb, including `--info`. Run winget (install *and* uninstall) from a normal elevated shell; machine-wide packages need UAC either way.
- **PowerShell itself is excluded from `update`.** The PowerShell MSI replaces the binaries of the running engine, so Windows Installer closes `pwsh` mid-install and rolls back with MSI 1603 (failed 24 Oct, 1 Nov, 3 Nov 2026; the transcript ends at `The pipeline has been stopped.`). Run the PowerShell upgrade from **Command Prompt**, not from PowerShell:

  ```bat
  winget upgrade --id Microsoft.PowerShell --exact --accept-package-agreements --accept-source-agreements
  ```

  Every open PowerShell window closes during the install — that is the installer, not a crash. Re-run `update` afterwards to confirm the rest is current.
- **One package at a time.** winget 1.29.380 has no `--exclude` option for `upgrade`, so the script parses the `winget upgrade` table itself, drops the guarded ids, and runs `winget upgrade --id <id> --exact` per package. A failure is listed at the end instead of aborting the rest of the run.
- **Downloads go through WinINET, not Delivery Optimization.** On 4 Nov 2026 `update` sat on `Downloading …gh_2.103.3_windows_amd64.msi` for 4 minutes: winget's diag log shows `DeliveryOptimization downloading from url:` and then nothing at all. `%LOCALAPPDATA%\Microsoft\WinGet\Settings\settings.json` now sets `network.downloader` to `wininet` (schema: [aka.ms/winget-settings.schema.json](https://aka.ms/winget-settings.schema.json)). If a download ever looks frozen again, check that file first.
- **Winget output is not piped, so it is not in the transcript.** winget only draws its progress bar when stdout is a console; piping hid a stalled download. Per-package winget text therefore goes straight to the terminal — for diagnostics use `%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir`.
- `cleanup-system.ps1 -DryRun` is the safe first run.
- `join-videos.ps1` expects clips with the same codec/resolution/fps/audio; otherwise use the re-encode fallback in `notes/ffmpeg-video-workflow.md`, or `remux-audio-back.ps1` when only the audio changed.
