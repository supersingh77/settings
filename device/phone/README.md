# Phone — Redmi Note 11

> Two physical units: work (4 GB) and personal (6 GB). Shared model facts live here; differences are under [`work/`](work/) and [`personal/`](personal/).

## Shared baseline

- **Model:** Redmi Note 11 (`2201117TI`, device `spes`, product `spes_in`)
- **Shared hardware:** Qualcomm SM6225/Snapdragon 680; 6.43-inch AMOLED, 1080×2400; 5000 mAh battery; USB-C charging
- **Work differences:** 4 GB RAM; see [`work/`](work/)
- **Personal differences:** 6 GB RAM; see [`personal/`](personal/)
- **Shared model facts:** [`hardware.md`](hardware.md)
- **Historical app snapshot:** [`archive/2026-09-01/`](archive/2026-09-01/) — role was not recorded; do not treat as current.
- **No root** — root would break banking apps.
- **USB debugging normally OFF** (banking-app security); enable only when capturing or managing a phone.

## Capture

Preview without writing using `bash device/phone/scripts/capture-phone.sh <work|personal> <adb-serial> --check`. Omit `--check` to capture. The script targets that serial, validates Redmi Note 11 `spes`, and never saves the serial. Review the generated role folder before committing. Package lists cover Android user 0; `not-installed-user-0.txt` is a package-state difference, not an authoritative list of apps intentionally removed by the owner.

## Debloating (UAD-NG)

- Runs via `fedora-toolbox-44` (has `adb`).
- Method: `pm uninstall --user 0` — no root needed, safe for banking apps.
- After debloating, re-run the capture to record the new state.

## ROM safety

The work phone remains on stock MIUI with a locked bootloader. Do not flash a ROM unless its maintainer explicitly supports this variant and provides verified device-specific installation and recovery instructions.
