---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/tasks.json, src/facets/linux/sys-hardware.ts, src/facets/linux/config-file.ts, layer:ghostty
---

# Fedora port decisions

The Fedora hardware facet is named `sys-hardware` because facet names share one global namespace and the Windows port already uses `hardware`. The item ids stay `board:`, `disk:`, `os:`, `kernel:`, `mount:`, `iface:`, `battery:`, `zram:` and `mem:`.

`config-file` is observed, not managed: the old tool only captured `/etc/UPower/UPower.conf` and restoring it needs safe in-place editing plus a rule for removed items.

`rpm-ostree` reads the staged deployment when one exists, and the booted deployment otherwise, so capture and drift see the requested layer set across a reboot.

The `app` facet and `recipes/` wait. A facet only sees probe output, so its `plan` cannot read `recipes/*.json`, and the step model has no installer; keep `laptop apps` until that contract is designed.

`devices/fedora-laptop/tasks.json` holds the commands for the proposed `update` and `cleanup` verbs. The old "update installed apps" step has no argv and is not represented.
