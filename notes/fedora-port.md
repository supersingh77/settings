---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/tasks.json, src/facets/linux/hardware.ts, src/facets/linux/config-file.ts, src/facets/linux/app.ts, src/core/recipe.ts, recipes/antigravity.json, layer:ghostty, app:antigravity
---

# Fedora port decisions

Facets are platform-scoped: each facet and each device declares a `platform`, so `hardware` exists once for Windows and once for Linux instead of needing distinct names. Fixtures live under `fixtures/<platform>/<facet>/`.

`config-file` is observed, not managed: the old tool only captured `/etc/UPower/UPower.conf` and restoring it needs safe in-place editing plus a rule for removed items.

`rpm-ostree` reads the staged deployment when one exists, and the booted deployment otherwise, so capture and drift see the requested layer set across a reboot.

`recipes/` is strict `Recipe` data copied from `declared/apps.json`: source, paths, install kind, launcher, icon and desktop entries. The CLI loads and validates it into the pure `Repo` context that facets receive, so `app` probes versions from the recipe's version path; item ids stay `app:<name>`. `app` is observed until a step can execute an install: the current `Step` is argv only, so install/remove execution is the remaining piece before the Python installer can go.

`devices/fedora-laptop/tasks.json` holds the commands for the proposed `update` and `cleanup` verbs. The old "update installed apps" step has no argv and is not represented.
