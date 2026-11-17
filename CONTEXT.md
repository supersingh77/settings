# CONTEXT.md — Project Bootup File

> Every new chat reads this first. Update it at the end of each chat.
> **This file is an index, not a database.** Volatile facts (versions, free space, pins, drive letters) live in the device docs — if you paste them here they will rot, and the last time that happened six files were wrong for three weeks.

## What This Is

Personal config + life-log repo covering all devices (Windows desktop, Windows laptop, Fedora laptop, phone). Intentionally organic: raw thoughts → processed into structured modules → clear history across devices.

## Directory Map

| Area | Purpose |
|------|---------|
| `inbox/` | Raw, unsorted ideas — processed into other folders over time |
| `outbox/` | Agent's outgoing work — ready to dispatch to another chat/app/agent |
| `device/` | Per-device setup notes, hardware, software, scripts |
| `notes/` | Long-term reference guides and workflows |

> The `finance/` project has been moved to a separate repo. Do not reference it here.

## Devices

| Device | Entry point |
|--------|-------------|
| Windows Desktop | [`device/desktop/README.md`](device/desktop/README.md) — hardware, software, taskbar, desktop, disk cleanup, audit playbook, scripts |
| Windows Laptop | [`device/laptop/README.md`](device/laptop/README.md) — hardware, software, cleanup script |
| Fedora Laptop | [`device/fedora-laptop/README.md`](device/fedora-laptop/README.md) — full setup, scripts, docs |
| Phone | [`device/phone/README.md`](device/phone/README.md) — hardware, app lists, ADB scripts |

## Key Conventions

- **Inbox pattern**: one small `.md` per idea with title, device metadata, date, core thoughts. Process into canonical folders over time.
- **Outbox pattern**: structured `.md` files ready to dispatch; remove once sent.
- **Scripts**: live inside their owning device folder (e.g. `device/desktop/scripts/`), never at the repo root.
- **Code style**: read [`STYLE.md`](STYLE.md) before writing or editing any script. No comments in code; facts live in `declared/*.json` or in prose docs. Functions pure, side effects at the edges, data separate from code.
- **Shape**: pure functions in `device/<device>/lib/`, invariants in `device/<device>/tests/`, intent in `device/<device>/declared/` (including the machine lists `audit-state.ps1` walks). A script that hardcodes a list is in the wrong shape.
- **Before committing**: `pwsh device/desktop/scripts/verify.ps1` (repo shape), `pwsh device/desktop/tests/run-tests.ps1` (behaviour) and `pwsh device/desktop/scripts/check-docs.ps1` (docs vs machine) must all exit 0. Together they are the lint and test layers — PSScriptAnalyzer cannot be installed here and Pester is 3.4.0.
- **Verify live, never recall**: before editing a device doc, run that device's audit script — for the desktop that is `pwsh device/desktop/scripts/audit-state.ps1`, then read `device/desktop/audit-playbook.md`.
- **No invented values**: mark anything unmeasured as `needs-review`.
- **Git workflow**: `git pull` before starting; `git add . && git commit && git push` after changes.
- **Docs describe what exists.** A path, folder or feature that has not been built does not go in a doc. An idea lives in `inbox/` until it is built; a rejected idea leaves nothing behind. `check-docs.ps1` fails on a `device/…`, `notes/…`, `inbox/…`, `outbox/…` or root-file path written in backticks that is not on disk, so a promise cannot outlive the decision.
- **Commit style**: `area: brief description` (e.g. `desktop: fix stale notes`, `fedora-laptop: add lessons-learned doc`).

## Tech Stack / Package Managers

- **Windows**: winget primary — preference order **winget → vendor installer → scoop**, and **all-users/machine-wide before per-user**. scoop is not installed; Chocolatey is present but unused.
- **Fedora**: bash scripts in `device/fedora-laptop/scripts/`.
- **Phone**: ADB-based scripts in `device/phone/scripts/`.

## Active Threads

- **"Choose another app" is dead on this image** — `OpenWith.exe` / `ShellHost.exe` fail at startup. Video and audio open via PotPlayer (`OpenWithList` + class default); `.md` does not open, despite a correct handler. Symptoms, evidence, what not to do and the repair path: [`notes/windows-shell-repair.md`](notes/windows-shell-repair.md). Unresolved.
- **Desktop streaming stack is being rebuilt** — OBS 33.0.1 is installed but has never been launched, and the old phone-DroidCam webcam path is retired now that a **Kreo Owl Lite** webcam exists (16 Nov 2026). ShareX and input-overlay are still missing. See the gaps section in [`device/desktop/README.md`](device/desktop/README.md).
- Net worth / assets & liabilities feature lives in the separate finance repo now.

## Recent Changes

- **2026-11-17** — `repo:` three gates before a commit: `verify.ps1` (8 hard shape rules over every script), `tests/run-tests.ps1` (behaviour, no Pester) and, for the desktop, `check-docs.ps1` (links, repo paths, build, drive letters, dated free space, app versions). Rules and rationale in [`STYLE.md`](STYLE.md).
- **2026-11-17** — `desktop:` pure functions moved to [`lib/`](device/desktop/lib/README.md), machine lists to [`declared/audit-targets.json`](device/desktop/declared/audit-targets.json), and packaged-app versions are now measured from the AppModel registry. Five silent-failure defects fixed: the mic verdict compared dB as strings, an unparsed winget table read as "nothing to upgrade", failed `tweaks.ps1` writes still exited 0, `cleanup-system.ps1` named a Downloads path that no longer existed, and `join-videos.ps1` could ingest its own output.
- **2026-11-17** — `docs:` the desktop re-measured (C: 67.0 GB free, Chrome 157.0.8103.79, Terminal 1.25.3131.0, Notion 7.44.0.0, 8 taskbar pins), drive-letter history removed, and [`notes/windows-shell-repair.md`](notes/windows-shell-repair.md) cut to the facts and the constraints. **Pending:** `Text Document`'s unquoted GenOffice command is declared as 1 change and needs one elevated `pwsh device/desktop/declared/tweaks.ps1` — the test suite stays red until then.
- **2026-11-16** — `repo:` pruned content that no longer describes the machine: the three Assetto Corsa notes, the OBS/DroidCam/streaming guides (new **Kreo Owl Lite** webcam replaces the phone setup), `music-starter` and `vod-posting-guide`, the whole `games/` config-backup folder, the four dormant AutoHotkey scripts, and the unused root `opencode.jsonc`. Added [`notes/README.md`](notes/README.md) so the remaining notes are reachable. All of it remains in Git history.
- **2026-11-16** — `desktop:` full live re-audit. Corrected free space, app inventory, taskbar pins and desktop layout; recorded the `ProductName` "Windows 10 Pro" quirk. Removed Notepad++ and Obsidian. Added `scripts/audit-state.ps1` and moved `remux-audio-back.ps1` out of the repo root. `CONTEXT.md` itself cut down to an index.
- **2026-11-16** — `notes:` documented the ReviOS shell / "Open with" failure and its repair path.
- **2026-11-04** — `desktop:` fixed `update` (WinINET downloader, per-package upgrades, PowerShell excluded) — details in [`device/desktop/scripts/README.md`](device/desktop/scripts/README.md).
- **2026-10-23** — `desktop:` 26H2 rebuild baseline — details in [`device/desktop/hardware.md`](device/desktop/hardware.md) and [`disk-cleanup.md`](device/desktop/disk-cleanup.md).
