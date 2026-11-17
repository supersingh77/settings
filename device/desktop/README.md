# Desktop PC — Custom Build

> Status: Active | Last verified: 17 Nov 2026 | OS: ReviOS 26H2

## Quick Reference

| Item | Detail |
|------|--------|
| **OS** | Windows 11 Pro 26H2 — build **26300.9457** (ReviOS). `ProductName` in the registry still reads "Windows 10 Pro" — ignore it |
| **Board / BIOS** | ASRock B450M-HDV R4.0 / AMI P10.60 (2026-04-17) |
| **CPU** | AMD Ryzen 7 5700X (8C/16T) |
| **GPU** | AMD Radeon RX 7600 8 GB — Adrenalin 26.10.1 (driver 32.0.32015.7029) |
| **RAM** | 16 GB DDR4-3000 (2 × 8 GB) |
| **Storage** | C: 126.1 GB system (**67.0 GB free**, measured 17 Nov 2026) · V: 350 GB games · Z: 931.5 GB archive |
| **Display** | MSI MAG 255XF — 1080p @ **300 Hz** (secondary: BenQ RL2240H) |
| **Role** | Gaming + streaming |

## Documentation

| Doc | Covers |
|-----|--------|
| [Hardware](hardware.md) | Components, drivers, storage, audio/network, known quirks |
| [Software](software.md) | Installed apps, versions, install scope, drivers, exclusions, removals |
| [Taskbar & Start](startmenu-taskbar.md) | Current pins, verified order |
| [Desktop Layout](desktop.md) | Actual `C:\Users\amar\Desktop` contents |
| [Disk Cleanup](disk-cleanup.md) | Drive map, measured consumers, recurring checklist |
| [Audit Playbook](audit-playbook.md) | Commands to verify pins/apps/drivers/Steam live |
| [Scripts](scripts/README.md) | Maintenance, video tools, `audit-state.ps1`, `verify.ps1` |
| [Tests](tests/README.md) | Behavioural invariants: parsers, verdict thresholds, dry runs, converged state |
| [Library](lib/README.md) | Pure functions the scripts and tests share |
| [Declared state](declared/README.md) | Rebuildable intent: package manifest, OBS settings, registry tweaks |

## Setup Rules

1. **Storage:** C: = OS + core apps. Games/streaming software → **V:**. Recordings, VODs, archives → **Z:**. There is no `D:` or `E:` on this machine, despite what older revisions of these docs said.
2. **Apps — preference order:** **winget** → **vendor installer** → **scoop**. **All users / machine-wide first**; per-user only when the vendor requires it (Discord, Twinkle Tray, LocalSend, DeepSeek Harness, T3 Code, Roblox, MSIX/AppX packages). No Razer Synapse, MCHOSE Hub, or vJoy.
3. **Display:** keep 300 Hz for desktop/gaming. MPRT must be **off** for Twinkle Tray brightness; MPRT has no DDC/CI control.
4. **Controllers:** the third-party Xbox 360 receiver opens Task View when the controller is off — unplug it or keep the controller on. PXN A7 shifter enumerates separately from the V10 Pro wheel.
5. **Before editing:** run `pwsh device/desktop/scripts/audit-state.ps1` and apply the checks in [audit-playbook.md](audit-playbook.md). Bump the `Updated` date and record only verified values. **Before committing:** `verify.ps1` and `tests/run-tests.ps1` must both exit 0.
6. **Maintenance:** in PowerShell 7, `update` and `cleanup` run the scripts in [`scripts/`](scripts/README.md). Both accept `-DryRun`. `update` deliberately skips PowerShell itself — its MSI kills the session it replaces (MSI 1603), so that one upgrade runs from Command Prompt.

## Current Gaps

- **OBS is recording-ready** — 1080p60, AMD AMF H.264 at CQP 23, writing to `Z:\Recordings` — but **not broadcast-ready**: no stream destination is set. Audio still comes from the webcam mic with desktop audio pinned to the monitor's HDMI, so levels/device choice is the next thing to check ([obs-recording-setup.md](../../notes/obs-recording-setup.md)).
- The phone-DroidCam route is retired (Kreo Owl Lite instead). `C:\Program Files\DroidCam` is an empty leftover folder, not an install; a stale `droidcam-obs` module entry remains in OBS's plugin manager.
- **ShareX** and **input-overlay** are still missing.
- `Z:\Games\SteamLibrary` (Celeste, Hollow Knight) is not registered in Steam; `V:` is.
- **"Choose another app" does not work** — the app picker is dead on this image (`ShellHost.exe` `0xC0000142`). Media types open correctly and `.md` does not, despite both having valid handlers; see [windows-shell-repair.md](../../notes/windows-shell-repair.md).
- In-game shifter binding still needs a sim.
- **16 Nov 2026:** Notepad++ and Obsidian removed. A default Obsidian vault is left at `Desktop\obsidian\` pending deletion.
