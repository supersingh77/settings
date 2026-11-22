# Desktop Scripts

> Run PowerShell scripts with **PowerShell 7**.
> `audit-state.ps1` reads the live desktop. `update-inventory.ps1 -DryRun` previews documentation drift; `-Apply` writes only generated sections in `hardware.md`, `software.md`, and `startmenu-taskbar.md`.
> Before committing, run [`verify.ps1`](verify.ps1) (repo shape), [`../tests/run-tests.ps1`](../tests/run-tests.ps1) (behaviour) and [`check-docs.ps1`](check-docs.ps1) (docs vs machine). Pure functions live in [`../lib/`](../lib/README.md).

| Script | Purpose | Status |
|--------|---------|--------|
| `verify.ps1` | **Read-only** repository check: scripts parse, no comments outside `#Requires`, no global state, writers expose `-DryRun` **and** set an explicit exit code, `declared/*.json` is valid and named by a script or doc, every script is listed in its folder README. Every rule is hard — exit 1 on any failure. Rules live in [`AGENTS.md`](../../../AGENTS.md). | Active — run before committing |
| `check-docs.ps1` | **Read-only** check that the docs still describe this machine. Every relative Markdown link in the repo resolves; every repo path written in backticks (`device/…`, `notes/…`, `inbox/…`, `outbox/…` or a root file) exists, so a doc cannot point at a folder nobody built; every `build **x.y**` claim matches the live build; every drive letter documented in a desktop table is mounted; every free-space claim dated on the same line is within 1 GB (warn) or 5 GB (fail) of the live value; every `software.md` version is compared to its registry ARP entry when the name matches exactly. An **undated** free-space number is treated as history and not compared — that is how the 23 Oct figures survive in these docs. | Active — run before committing |
| `update-inventory.ps1` | Reads the `audit-state.ps1` report and regenerates detected hardware, software, and taskbar sections. Default mode and `-DryRun` are read-only; `-Apply` writes generated Markdown sections and preserves surrounding notes. Review the resulting `git diff`. | Active |
| `audit-state.ps1` | **Read-only** collector for the generated sections: OS/build, firmware/CPU/RAM, GPU/display, volumes, registry apps, packaged apps, taskbar pins, Steam libraries and configured path checks. `-OutFile` writes a Markdown report; its machine-specific paths live in [`../declared/audit-targets.json`](../declared/audit-targets.json). | Active — source for `update-inventory.ps1` |
| `update-system.ps1` | Refreshes winget sources, lists upgrades once, parses that listing, then upgrades them **one package at a time** (a failure no longer aborts the run), with `Microsoft.PowerShell` filtered out (see Notes). Supports `-DryRun`; logs to `%LOCALAPPDATA%\DesktopMaintenance\logs` and degrades to no-transcript rather than failing when that folder is unwritable. Exits 1 if any package failed or the listing could not be parsed. | Active |
| `cleanup-system.ps1` | Temp files, DISM component cleanup, Recycle Bin, DNS, Delivery Optimization. Supports `-DryRun`; reports staged-installer size without deleting it. Exits 1 if DISM or `ipconfig /flushdns` fails. | Active |
| `mic-check.ps1` | Records a few seconds from each microphone and reports mean/peak dB with a verdict. Catches the two failures that silently ruin recordings: a muted/sleeping device (digital silence) and one that is alive but far too quiet. Read-only, no admin. Verdict thresholds live in [`../lib/audio-levels.ps1`](../lib/audio-levels.ps1). | Active — run before trusting any mic |
| `voice-compare.ps1` | Objective A/B of voice recordings: noise floor, voice level, SNR, integrated loudness, headroom and 3-band spectral balance, with a verdict per file. Needs a 5 s silent lead-in per recording. Read-only. | Active — use to pick a microphone |
| `join-videos.ps1` | Lossless FFmpeg concat of clips in one folder, ordered by filename (chronological for OBS/phone timestamps). `-Folder` required; `-Output` defaults to `joined.mp4`; `-Extensions` overridable. A previous output file with the same name is excluded, so re-running in the same folder cannot swallow its own result. All clips must share codec/resolution/fps/audio — otherwise it fails and you want the re-encode fallback in [`notes/ffmpeg-video-workflow.md`](../../../notes/ffmpeg-video-workflow.md). Supports `-DryRun`. | Active |
| `remux-audio-back.ps1` | Puts a cleaned/noise-reduced audio file back into the original video with `-c:v copy`, then proves the video packets are bit-identical via MD5. `-Video` and `-Audio` required; `-Out` defaults to `"<name> (cleaned).mp4"` next to the source; `-Bitrate` defaults to `192k`. Audio is copied when the codec is MP4-friendly (`aac`, `mp3`, `ac3`, `eac3`, `alac`) and transcoded to AAC otherwise (`wav`, `flac`). Supports `-DryRun`. | Active |

## Reading `mic-check.ps1`

| Mean level | Verdict | Meaning |
|---|---|---|
| −70 dB or lower | SILENT | muted, dead, or blocked — treat as unusable, do not "turn it up" |
| −50 to −70 | very quiet | Windows input level too low |
| −30 to −50 | quiet | usable, raise gain in OBS |
| above −30, peak below −3 | healthy | in range |
| peak above −3 | hot | clipping risk, lower gain |

Target for voice: mean around **−18 dB**, peaks **−12 to −6 dB**. Digital silence (≈ −90 dB) never means a quiet room — a live mic always shows room tone around −45 to −60 dB.

The thresholds live in [`../lib/audio-levels.ps1`](../lib/audio-levels.ps1) and [`../tests/audio-levels.tests.ps1`](../tests/audio-levels.tests.ps1) pins both sides of every band edge, so this table cannot drift away from the code without a test failing.

**Known false negative:** a device can read −91 dB on one pass and −40 dB on the next (still opening, or held by another app). Two passes, or one while speaking, before writing a mic off.

## Reading `voice-compare.ps1`

| Column | Meaning |
|---|---|
| `SnrDb` | voice minus noise floor: **30+ clean**, 20–30 usable, <20 hissy |
| `NoiseDb` | room tone during the quiet opening: −60 good, −45 is a noisy room |
| `Lufs` | integrated loudness; aim −16 to −20. Much lower means input gain is too low |
| `BodyDb` / `MidDb` / `HighDb` | mean level per band. Body ≫ Mid = boomy, Mid ≫ Body = thin, High near Mid = bright and clear (harsh once it exceeds Mid) |
| `Verdict` | flags hiss, clipping, boomy, thin, too quiet, and a missing silent lead-in |

It needs the **test pattern** — 5 s of silence, then speech at normal volume — otherwise SNR is meaningless, and the verdict says `no silent lead-in - pattern not followed` rather than pretending.

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

- **audit-state.ps1 prints the measured value for every fact these docs claim**, so a doc can be checked against the machine in one command instead of recalled. It is written for agent sandboxes, where WMI/CIM, `Get-Volume`, `Get-AppxPackage`, UI Automation and `Export-StartLayout` are all blocked — it uses registry reads, .NET, and on-disk files instead.
- **winget dies inside a sandboxed agent session** with `0x8A150001` on every verb, including `--info`. Run winget (install *and* uninstall) from a normal elevated shell; machine-wide packages need UAC either way.
- **PowerShell itself is excluded from `update`.** The PowerShell MSI replaces the binaries of the running engine, so Windows Installer closes `pwsh` mid-install and rolls back with MSI 1603 (failed 24 Oct, 1 Nov, 3 Nov 2026; the transcript ends at `The pipeline has been stopped.`). Run the PowerShell upgrade from **Command Prompt**, not from PowerShell:

  ```bat
  winget upgrade --id Microsoft.PowerShell --exact --accept-package-agreements --accept-source-agreements
  ```

  Every open PowerShell window closes during the install — that is the installer, not a crash. Re-run `update` afterwards to confirm the rest is current.
- **One package at a time.** winget 1.29.380 has no `--exclude` option for `upgrade`, so the script parses the `winget upgrade` table itself, drops the guarded ids, and runs `winget upgrade --id <id> --exact` per package. A failure is listed at the end instead of aborting the rest of the run.
- **Downloads go through WinINET, not Delivery Optimization.** On 4 Nov 2026 `update` sat on `Downloading …gh_2.103.3_windows_amd64.msi` for 4 minutes: winget's diag log shows `DeliveryOptimization downloading from url:` and then nothing at all. `%LOCALAPPDATA%\Microsoft\WinGet\Settings\settings.json` now sets `network.downloader` to `wininet` (schema: [aka.ms/winget-settings.schema.json](https://aka.ms/winget-settings.schema.json)). If a download ever looks frozen again, check that file first.
- **The upgrade listing is parsed once and never trusted blindly.** `update` captures the table, prints it, and runs `ConvertFrom-WingetUpgradeTable` ([`../lib/winget-table.ps1`](../lib/winget-table.ps1)) over it. Two outcomes matter: a recognised-but-empty table with winget's own "nothing to upgrade" text, which is success; and zero parsed rows without that text, which now exits **1** instead of printing "Nothing to upgrade". A fixed-width table changing shape used to look exactly like a clean machine.
- **Per-package winget output is not piped, so it is not in the transcript.** winget only draws its progress bar when stdout is a console; piping hid a stalled download. The package loop therefore streams straight to the terminal — for diagnostics use `%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir`.
- `cleanup-system.ps1 -DryRun` is the safe first run.
- `join-videos.ps1` expects clips with the same codec/resolution/fps/audio; otherwise use the re-encode fallback in `notes/ffmpeg-video-workflow.md`, or `remux-audio-back.ps1` when only the audio changed.
