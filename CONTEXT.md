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

- C: drive has **98.8 GB free** after the 23 Oct cleanup — no longer critical
- Net worth / assets & liabilities feature was spec'd but the finance project is now in a separate repo

## What Changed Recently

- **2026-11-04 — `update` froze on the GitHub CLI download**: winget used **Delivery Optimization** (`DeliveryOptimization downloading from url:` then silence for 4 min). Fixed by `network.downloader: wininet` in `%LOCALAPPDATA%\Microsoft\WinGet\Settings\settings.json`, and by no longer piping winget per-package output — piping disabled winget's progress bar, which is what made the stall look like a dead terminal.
- **2026-11-04 — `update` fixed for real; PowerShell now 7.6.9**: `winget upgrade` in 1.29.380 has **no `--exclude`** — the first fix attempt died on `0x8A150002` (invalid argument) before upgrading anything. `update-system.ps1` now parses the `winget upgrade` table and drives `winget upgrade --id <id> --exact` one package at a time, filtering `Microsoft.PowerShell`; a failing package is reported at the end instead of aborting the run. 7.6.9 itself was installed from **Command Prompt** — the MSI kills the pwsh-hosted install and rolls back 1603 (24 Oct 7.6.8, 1 Nov ×3 + 3 Nov 7.6.9). Documented in `device/desktop/scripts/README.md`.
- **2026-11-03 — diagnosed `update` dying at package 1 (PowerShell 1603)**: PowerShell MSI replaces the running engine's binaries, Windows Installer closes `pwsh` mid-install, transaction rolls back; transcript ends at `The pipeline has been stopped.`
- **2026-10-23 — ReviOS 26H2 rebuild**: clean Windows 11 Pro 26H2 (build 26300.9457) replacing the Atlas OS setup. Old `V:` → `E:`, old `Z:` → `D:`.
- Drivers: AMD chipset 8.09.28.1124 (fixes `ACPI\AMDIF030`), Adrenalin 26.10.1 (32.0.32015.7029), Realtek audio 6.0.9231.1, Realtek LAN 10.50.511.2021, Focusrite 4.150.0.432.
- Apps restored: 7-Zip, PowerShell 7.6.7, Python 3.14.7, GitHub CLI, FFmpeg (machine-wide), plus Discord, Steam, PotPlayer, HWiNFO, Twinkle Tray, Radmin VPN, LocalSend.
- PXN V10 Pro wheel + A7 Gear Shift connected; PXN SimRacing 1.6.9 installed and detects the V10 Pro base/pedals.
- MSI MAG 255XF monitor driver 1.0.0.0 (WHQL) + ICM installed; MPRT locks DDC/CI brightness, so Twinkle Tray needs MPRT off.
- Display now 1920×1080 @ 300 Hz; C: 98.8 GB free after removing 46.6 GB (including the 38 GB `Windows.old`); Steam libraries on `E:`/`D:` need re-adding on first launch.
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
