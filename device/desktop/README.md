# Desktop PC — Custom Build

> Active desktop for gaming and streaming.

## Documentation

| Doc | Covers |
|-----|--------|
| [Hardware](hardware.md) | Generated live hardware inventory and human notes on devices and known quirks |
| [Software](software.md) | Generated installed-software inventory and setup policy |
| [Taskbar & Start](startmenu-taskbar.md) | Generated taskbar pins and Start menu verification note |
| [Desktop Layout](desktop.md) | Placement rules for files and shortcuts |
| [Disk Cleanup](disk-cleanup.md) | Recurring cleanup procedures |
| [Audit Playbook](audit-playbook.md) | Manual fallbacks for readings the collector does not cover |
| [Scripts](scripts/README.md) | Maintenance, video tools, inventory generation and checks |
| [Tests](tests/README.md) | Behavioural invariants and non-mutating previews |
| [Library](lib/README.md) | Pure functions the scripts and tests share |
| [Declared state](declared/README.md) | Rebuildable intent: package manifest, OBS settings, registry tweaks |

## Setup Rules

1. **Storage:** C: = OS + core apps. Games/streaming software → **V:**. Recordings, VODs, archives → **Z:**. The letters are a deliberate choice; do not renumber them to match a textbook layout.
2. **Software:** follow the install and exclusion policy in [software.md](software.md).
3. **Display:** keep 300 Hz for desktop/gaming. MPRT must be **off** for Twinkle Tray brightness; MPRT has no DDC/CI control.
4. **Controllers:** the third-party Xbox 360 receiver opens Task View when the controller is off — unplug it or keep the controller on. PXN A7 shifter enumerates separately from the V10 Pro wheel.
5. **Inventory:** run `pwsh device/desktop/scripts/update-inventory.ps1 -DryRun` to inspect drift, then `-Apply` to update generated sections. Review `git diff`; keep or revert the reported changes. Run `verify.ps1`, `check-docs.ps1` and `tests/run-tests.ps1` before committing.
6. **Maintenance:** in PowerShell 7, `update` and `cleanup` run the scripts in [`scripts/`](scripts/README.md). Both accept `-DryRun`.
