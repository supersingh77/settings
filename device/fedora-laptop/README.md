# Fedora Silverblue Laptop — System Setup

> Active Fedora laptop. `device/laptop*` covers a separate Windows gaming laptop.

## Quick Reference

| Area | Current setup |
|---|---|
| **Hardware** | ASUS VivoBook X505ZA; Ryzen 5 2500U (4C/8T), Radeon Vega 8 |
| **Memory** | 10 GiB visible to Linux; 8 GiB zram swap. Physical module inventory is documented separately and remains unverified. |
| **Storage** | 480 GB WD Green NVMe (Silverblue/Btrfs); 1 TB Seagate HDD mounted as Btrfs at `/var/mnt/data` (label `data`) |
| **OS** | Fedora Silverblue 44; immutable OSTree deployments |
| **Host packages** | rpm-ostree layers: distrobox, Ghostty, uhubctl; Firefox removed from base |
| **App model** | GUI apps via system Flatpak; CLI/media/ADB tools in `fedora-toolbox-44`; selected user apps under `~/.local` |
| **Maintenance** | `update` stages host OS updates (reboot to apply); `cleanup` runs slower filesystem/app maintenance |

## Documentation Map

- **[Hardware](hardware.md)** — machine details, verified memory caveat, storage and power quirks
- **[Setup](#-setup)** — current host and user setup commands
- **[Troubleshooting](docs/troubleshooting.md)** — symptoms and recovery steps
- **[Lessons learned](docs/lessons.md)** — Silverblue-specific deployment and incident lessons

## Setup

Daily use: run `make linux` from the repository root. Setup commands below are for rebuild/recovery, not routine maintenance.

Set the clone path once in your shell with `export SETTINGS_ROOT="$(git rev-parse --show-toplevel)"`.

```bash
make linux
```

Host setup stages changes, may remove Firefox, and requires a reboot before user setup. Review the script before running it.

```bash
make -C "$SETTINGS_ROOT" setup-host
```

```bash
make -C "$SETTINGS_ROOT" setup-user
```

```bash
make -C "$SETTINGS_ROOT" setup-dev
make -C "$SETTINGS_ROOT" audit
```

The local Ruff version is pinned in `Makefile`; ShellCheck and shfmt are optional system tools. The audit runs available linters, shell syntax checks, tests, changed-code comment checks, and Fedora documentation checks.

---

## ⚡ Daily Commands

```bash
make -C "$SETTINGS_ROOT" audit

# Fast daily update (Flatpaks + OpenWork + UAD-NG + Antigravity + toolbox + rpm-ostree)
update

# The script stages rpm-ostree changes; they take effect only after reboot.
rpm-ostree status          # inspect the booted and pending deployments
sudo systemctl reboot      # boot the staged deployment

# Slow maintenance — run occasionally (btrfs scrub, flatpak cleanup, journal vacuum, DNS flush, trash empty)
cleanup

# OpenWork only
update-openwork

# UAD-NG only
update-uad

# Antigravity 2.0 only
update-antigravity

# Manual update steps
rpm-ostree upgrade          # stage system update (reboot to apply)
flatpak update              # update Flatpak apps (no reboot)

# Check system status
rpm-ostree status

# Android debloating
uad
```

---

## Toolbox boundary

`fedora-toolbox-44` is the intentional CLI/development environment for `adb`/`fastboot`, FFmpeg, 7-Zip, and GitHub CLI. GUI apps remain Flatpaks; Toolbox keeps command-line packages out of the immutable host and avoids host deployment churn. The current phone works with Toolbox ADB; USB rules are only needed if a device is not detected.

## Containers Quick Reference

```bash
# General container
toolbox enter fedora-toolbox-44

toolbox list
```

---

## 🖥️ GNOME Layout (Coordination Rule)

Same principle as the Windows desktop: an app lives in exactly **one** place — no redundancy.

| Place | Role | Example |
|-------|------|---------|
| **Favorites bar** (dock) | Daily drivers only | Chrome, Files, Terminal, OpenWork |
| **App grid** (Activities) | Everything else | VLC, UAD-NG, Ghostty, Antigravity |

- Keep the favorites bar short — if you haven't opened it this week, unpin it.
- GNOME has no desktop icons by default; don't add extensions just to recreate them.
- Search (Super key) reaches any app instantly — the grid is a fallback, not a filing system.

---

## 📱 Android Debloating (UAD-NG)

UAD-NG runs via `fedora-toolbox-44` (which has `adb` installed).

```bash
launch-uad
toolbox run -c fedora-toolbox-44 adb devices
```

Search **UAD-NG** in GNOME Activities to launch from the app grid. See **[`docs/uad-ng.md`](docs/uad-ng.md)** for USB debugging steps, ADB troubleshooting, and update instructions.

---

## Troubleshooting

Use [`docs/troubleshooting.md`](docs/troubleshooting.md) for current recovery guidance. The longer [`docs/lessons.md`](docs/lessons.md) file is retained for the Silverblue deployment and battery quirks documented there.

---
