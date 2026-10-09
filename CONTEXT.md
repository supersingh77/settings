# CONTEXT.md — Project Bootup File

> Every new chat reads this first. Update it at the end of each chat.

## What This Is

Personal config + life-log repo covering all devices (Windows desktop, Windows laptop, Fedora laptop, phone). Intentionally organic: raw thoughts → processed into structured modules → clear history across devices.

## Directory Map

| Area | Purpose |
|------|---------|
| `inbox/` | Raw, unsorted ideas — processed into other folders over time |
| `outbox/` | Agent's outgoing work — ready to dispatch to another chat/app/agent |
| `device/` | Per-device setup notes, hardware, software, scripts |
| `notes/` | Long-term reference guides and workflows |
| `games/` | Game settings and controller configs |

> The `finance/` project has been moved to a separate repo. Do not reference it here.

## Devices

| Device | Key Files |
|--------|-----------|
| Windows Desktop | `device/desktop/hardware.md`, `software.md`, `desktop.md`, `startmenu-taskbar.md`, `disk-cleanup.md`, `audit-playbook.md`, `scripts/` |
| Windows Laptop | `device/laptop/hardware.md`, `software.md`, `scripts/` |
| Fedora Laptop | `device/fedora-laptop/` — full setup, scripts, docs |
| Phone | `device/phone/hardware.md`, `apps/`, `scripts/` |

## Key Conventions

- **Inbox pattern**: One small `.md` file per idea with title, device metadata, date, core thoughts. Process into canonical folders over time.
- **Outbox pattern**: Structured `.md` files ready to dispatch. Agent puts completed work here for user review before sending.
- **Scripts**: Live inside their owning device folder (e.g. `device/desktop/scripts/`), not in a shared top-level `scripts/`.
- **Desktop audits**: read `device/desktop/audit-playbook.md` first — verified commands for live pin/app/Steam state before editing those docs.
- **Git workflow**: `git pull` before starting, `git add . && git commit && git push` after changes.
- **Commit style**: `area: brief description` (e.g. `desktop: fix stale notes`, `fedora-laptop: add lessons-learned doc`).

## Tech Stack / Package Managers

- **Windows**: winget (primary), scoop (CLI helpers only: `dark`, `innounp`)
- **Fedora**: bash scripts in `device/fedora-laptop/scripts/`
- **Phone**: ADB-based scripts in `device/phone/scripts/`

## Active Threads

- C: drive critically low (13.0 GB free) — needs cleanup; app-removal candidates sized in `device/desktop/disk-cleanup.md` §6, awaiting go-ahead
- Net worth / assets & liabilities feature was spec'd but the finance project is now in a separate repo

## What Changed Recently

- Full repo cleanup pass (2026-10-09): corrected desktop GPU to **8 GB** (WMI 32-bit cap explained), driver → 26.8.1, free space C: 13.0 / V: 32.4 / Z: 302.9 GB, RAM module detail, BIOS
- `startmenu-taskbar.md` taskbar list corrected to the real **17** pins; "taskbar and Start disjoint" note fixed (they overlap on Settings/Terminal/Notepad)
- `audit-playbook.md` §1 now documents the UI Automation method and the registry decode's packaged-app blind spot
- `desktop.md` rewritten to the live `C:\Users\amar\Desktop` layout (`bills/`, `statements/`, `settings/`, `8/`; `Personal/` and `config/` no longer exist)
- Fixed stale refs: streaming-workflow path → `settings\` + removed dead commit hashes; VRAM 4GB→8GB in notes/laptop docs
- Added `install-links.sh` to the Fedora README tree
- Added `device/desktop/audit-playbook.md` — verified commands for live pin/app/Steam audits (2026-10-09)
- Fixed inverted "No Invented Values" rule in `README.md` (it read "Do guess")
- Start menu / taskbar docs verified live against registry (2026-10-09): Zed → Cursor, Audacity unpinned
- `software.md` reconciled with real installs — stale apps removed, AutoClaw/ZCode/MiniMax Code added
- App-removal candidates sized and parked in `disk-cleanup.md` (no app changes made)
- Finance project moved to separate repo; `CONTEXT.md` created (2026-10-09)
