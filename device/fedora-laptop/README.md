# Fedora Silverblue Laptop — System Setup

> Active Fedora laptop. `device/laptop*` covers a separate Windows gaming laptop.

## Quick Reference

The tracked [`hardware.md`](hardware.md) and [`software.md`](software.md) files are the canonical inventories. `## Detected *` sections are machine-generated; edit them only by running the inventory script. Human caveats live in the sections below and are never overwritten.

## Documentation Map

- **[Hardware](hardware.md)** — canonical hardware inventory and human caveats
- **[Software](software.md)** — canonical installed-software inventory and human caveats
- **[Inventory script](scripts/check-inventory.py)** — `python3 device/fedora-laptop/scripts/check-inventory.py` prints a diff and exits nonzero on drift; `--apply` writes the generated sections directly to the Markdown files
- **[Setup](#-setup)** — fresh setup or rebuild only
- **[Troubleshooting](docs/troubleshooting.md)** — symptoms and recovery steps
- **[Lessons learned](docs/lessons.md)** — Silverblue-specific deployment and incident lessons

## Setup

Daily checks: `make linux` from the repository root. The audit fails when live system readings differ from committed Markdown. To regenerate inventory sections from the live machine:

```
python3 device/fedora-laptop/scripts/check-inventory.py --apply
git diff device/fedora-laptop/hardware.md device/fedora-laptop/software.md
git add -p   # stage wanted changes, revert unwanted ones
```

To rebuild, preview with `make setup-host ARGS=--check` and `make setup-user ARGS=--check`. The host setup can remove Firefox and stage a deployment; inspect it before running. Reboot if a deployment is staged before running user setup.

---

## Toolbox boundary

`fedora-toolbox-44` is the intentional CLI/development environment for `adb`/`fastboot`, FFmpeg, 7-Zip, and GitHub CLI. GUI apps remain Flatpaks; Toolbox keeps command-line packages out of the immutable host and avoids host deployment churn. The current phone works with Toolbox ADB; USB rules are only needed if a device is not detected.

See [`docs/uad-ng.md`](docs/uad-ng.md) for phone-specific steps and [`docs/troubleshooting.md`](docs/troubleshooting.md) for recovery guidance.

---
