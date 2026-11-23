# Windows desktop

This folder tracks this desktop's intended configuration, observed state, maintenance procedures, and supporting scripts. It is the device's entry point and file map.

## State workflow

- `declared/` contains deliberate settings: what the desktop should look like.
- `hardware.md`, `software.md`, and `startmenu-taskbar.md` contain generated observations plus any human-maintained notes. `scripts/audit-state.ps1` reads the machine; `scripts/update-inventory.ps1` writes only generated sections.
- Run `pwsh device/desktop/scripts/update-inventory.ps1 -DryRun` to detect drift. If the diff is expected, run with `-Apply`, review `git diff`, and commit the accepted snapshot. If it is unwanted, reconcile the machine and capture again.
- Dry runs for declared registry tweaks are proposals. Nothing should change automatically without review.
- Never store secrets such as OBS stream keys in this repository. Registry exports and other volatile, personal machine state stay outside Git.

## Desktop rules

- C: holds Windows and core apps; V: holds games and streaming software; Z: holds recordings, VODs, and archives.
- Keep the display at 300 Hz. MPRT must be off for Twinkle Tray brightness control.
- The third-party Xbox 360 receiver can open Task View when its controller is off. PXN A7 shifter enumerates separately from the V10 Pro wheel.
- Preview system updates and cleanup with `-DryRun`. Applying cleanup removes temporary files and caches, empties the Recycle Bin, and flushes DNS.

## File map

```text
device/desktop/
├── README.md                         This guide and complete desktop file map
├── desktop.md                        Desktop layout and file placement
├── disk-cleanup.md                   Disk cleanup procedure
├── hardware.md                       Generated hardware inventory and human notes
├── software.md                       Generated software inventory and install policy
├── startmenu-taskbar.md              Generated taskbar pins and Start menu notes
├── declared/
│   ├── associations.json             Intended file-extension and “Open with” handlers
│   ├── audit-targets.json             Paths and labels inspected by the live audit
│   ├── obs.json                       Chosen OBS recording and audio settings
│   ├── tweaks.ps1                     Applies or previews declared registry tweaks
│   └── winget-export.json             Selected packages for Winget import
├── lib/
│   ├── audio-levels.ps1               Audio level analysis helpers
│   ├── inventory-docs.ps1             Parses audit output and builds inventory sections
│   ├── version-match.ps1              Compares documented and installed versions
│   └── winget-table.ps1               Parses Winget output into tables
├── scripts/
│   ├── audit-state.ps1                Collects live hardware, software, and taskbar state
│   ├── check-docs.ps1                 Checks documentation claims against the machine
│   ├── cleanup-system.ps1             Cleans selected temporary files and caches
│   ├── join-videos.ps1                Joins compatible videos without re-encoding
│   ├── mic-check.ps1                  Records a short test from DirectShow microphones
│   ├── remux-audio-back.ps1           Replaces or combines audio on a video
│   ├── update-inventory.ps1           Refreshes generated inventory sections
│   ├── update-system.ps1              Runs Windows update operations
│   ├── verify.ps1                     Checks scripts, declared data, and repo rules
│   └── voice-compare.ps1              Analyzes and compares voice recordings
└── tests/
    ├── audio-levels.tests.ps1         Tests audio analysis helpers
    ├── inventory-docs.tests.ps1       Tests audit parsing and document generation
    ├── repo.tests.ps1                 Tests repository checks and dry-run behavior
    ├── run-tests.ps1                  Runs the desktop test suite
    ├── version-match.tests.ps1        Tests version matching
    └── winget-table.tests.ps1         Tests Winget table parsing
```

## Checks and common commands

Run from the repository root in PowerShell 7. Use `-?` on a script for its parameters.

```powershell
pwsh device/desktop/scripts/update-inventory.ps1 -DryRun
pwsh device/desktop/scripts/check-docs.ps1
pwsh device/desktop/scripts/verify.ps1
pwsh device/desktop/tests/run-tests.ps1
pwsh device/desktop/declared/tweaks.ps1 -DryRun
pwsh device/desktop/scripts/update-system.ps1 -DryRun
pwsh device/desktop/scripts/cleanup-system.ps1 -DryRun
```

Audio and video tools: `mic-check.ps1` records microphones; `voice-compare.ps1 -Path <folder>` compares voice recordings (include five seconds of room tone); `join-videos.ps1 -Folder <folder>` joins compatible clips without re-encoding; `remux-audio-back.ps1 -Video <file> -Audio <file>` replaces a video's audio.
