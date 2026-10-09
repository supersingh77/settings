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
| Windows Desktop | `device/desktop/hardware.md`, `software.md`, `startmenu-taskbar.md`, `scripts/` |
| Windows Laptop | `device/laptop/hardware.md`, `software.md`, `scripts/` |
| Fedora Laptop | `device/fedora-laptop/` — full setup, scripts, docs |
| Phone | `device/phone/hardware.md`, `apps/`, `scripts/` |

## Key Conventions

- **Inbox pattern**: One small `.md` file per idea with title, device metadata, date, core thoughts. Process into canonical folders over time.
- **Outbox pattern**: Structured `.md` files ready to dispatch. Agent puts completed work here for user review before sending.
- **Scripts**: Live inside their owning device folder (e.g. `device/desktop/scripts/`), not in a shared top-level `scripts/`.
- **Git workflow**: `git pull` before starting, `git add . && git commit && git push` after changes.
- **Commit style**: `area: brief description` (e.g. `desktop: fix stale notes`, `fedora-laptop: add lessons-learned doc`).

## Tech Stack / Package Managers

- **Windows**: winget (primary), scoop (CLI helpers only: `dark`, `innounp`)
- **Fedora**: bash scripts in `device/fedora-laptop/scripts/`
- **Phone**: ADB-based scripts in `device/phone/scripts/`

## Active Threads

- C: drive critically low (12.7 GB free) — needs cleanup
- Net worth / assets & liabilities feature was spec'd but the finance project is now in a separate repo

## What Changed Recently

- Finance project removed from this repo (moved to separate repo)
- `CONTEXT.md` created (2026-10-09)
- Outbox system created (2026-10-09)
- Bootup sequence added to agent config (2026-10-09)
- Desktop software inventory refreshed (2026-10-09)
