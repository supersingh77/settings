# Project context

Personal configuration repository. This file is a short entry point; current policy lives in [`AGENTS.md`](AGENTS.md), and the device index is [`device/README.md`](device/README.md).

## Desktop inventory workflow

Run `pwsh device/desktop/scripts/update-inventory.ps1 -DryRun` to inspect drift, then add `-Apply` to update generated sections in the hardware, software, and taskbar docs. Review the diff and run the desktop checks in [`device/desktop/scripts/README.md`](device/desktop/scripts/README.md).
