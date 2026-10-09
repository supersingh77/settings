# Phone — Redmi Note 11

> Status: Tracked (hardware + app inventory via adb)

## Overview

- **Device:** Redmi Note 11 (`spes`/`spes_in`, model `2201117TI`)
- **OS:** Android 13, MIUI V816
- **Full specs:** [`hardware.md`](hardware.md)
- **No root** — root would break banking apps.
- **USB debugging normally OFF** (banking-app security); enabled only for the monthly capture/debloat step.

## App inventory

Captured via adb on 2026-09-01. See [`apps/`](apps/):

| File | Contents | Count |
|------|----------|-------|
| [`apps/all-packages.txt`](apps/all-packages.txt) | Every installed package (system + user) | 289 |
| [`apps/user-installed.txt`](apps/user-installed.txt) | User-installed (3rd-party) apps | 61 |
| [`apps/debloated.txt`](apps/debloated.txt) | Packages removed via `pm uninstall --user 0` | 108 |
| [`apps/uad-selection.txt`](apps/uad-selection.txt) | UAD-NG selection export (planned debloat) | 168 |

### Understanding the two debloat lists

- **`debloated.txt`** = what is **actually removed** (uninstalled for user 0). This is the real state.
- **`uad-selection.txt`** = what you've **selected** in UAD-NG. As of the 2026-09-01 capture, this list has **zero overlap** with `debloated.txt` — the selection is a *planned* list that hasn't been applied (or was applied via a different method). Reconcile these before your next debloat pass.

## Monthly refresh routine

USB debugging is off most of the time, so this is a deliberate ~once-a-month step:

1. **Enable USB debugging** on the phone (Developer options → USB debugging), connect via USB.
2. Run the capture:
   ```bash
   bash device/phone/scripts/capture-phone.sh
   ```
   This refreshes `hardware.md`, `all-packages.txt`, `user-installed.txt`, and `debloated.txt`.
3. **Re-export the UAD selection** from UAD-NG (File → Export selection) and copy it to `device/phone/apps/uad-selection.txt`.
4. Commit and push:
   ```bash
   git add device/phone && git commit -m "phone: refresh capture" && git push
   ```
5. **Turn USB debugging back off** when done.

## Debloating (UAD-NG)

- Runs via `fedora-toolbox-44` (has `adb`).
- Method: `pm uninstall --user 0` — no root needed, safe for banking apps.
- After debloating, re-run the capture to record the new state.

## Known quirks

- (Add as you find them)
