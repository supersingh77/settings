---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/tasks.json, src/facets/linux/hardware.ts, src/facets/linux/config-file.ts, layer:ghostty
---

# Fedora port decisions

Facets are platform-scoped: each facet and each device declares a `platform`, so `hardware` exists once for Windows and once for Linux instead of needing distinct names. Fixtures live under `fixtures/<platform>/<facet>/`.

`config-file` is observed, not managed: the old tool only captured `/etc/UPower/UPower.conf` and restoring it needs safe in-place editing plus a rule for removed items.

`rpm-ostree` reads the staged deployment when one exists, and the booted deployment otherwise, so capture and drift see the requested layer set across a reboot.

The `app` facet and `recipes/` wait. A facet only sees probe output, so its `plan` cannot read `recipes/*.json`, and the step model has no installer; keep `laptop apps` until that contract is designed.

`devices/fedora-laptop/tasks.json` holds the commands for the proposed `update` and `cleanup` verbs. The old "update installed apps" step has no argv and is not represented.
