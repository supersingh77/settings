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
- **[Setup](#-setup)** — fresh setup or rebuild only
- **[Troubleshooting](docs/troubleshooting.md)** — symptoms and recovery steps
- **[Lessons learned](docs/lessons.md)** — Silverblue-specific deployment and incident lessons

## Setup

Daily checks: `make linux` from the repository root. This creates the pinned local Ruff environment and runs audit/tests; ShellCheck and shfmt run if installed.

To rebuild, preview with `make setup-host ARGS=--check` and `make setup-user ARGS=--check`. The host setup can remove Firefox and stage a deployment; inspect it before running. Reboot if a deployment is staged before running user setup.

---

## Toolbox boundary

`fedora-toolbox-44` is the intentional CLI/development environment for `adb`/`fastboot`, FFmpeg, 7-Zip, and GitHub CLI. GUI apps remain Flatpaks; Toolbox keeps command-line packages out of the immutable host and avoids host deployment churn. The current phone works with Toolbox ADB; USB rules are only needed if a device is not detected.

See [`docs/uad-ng.md`](docs/uad-ng.md) for phone-specific steps and [`docs/troubleshooting.md`](docs/troubleshooting.md) for recovery guidance.

---
