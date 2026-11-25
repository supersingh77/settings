---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/tasks.json, src/facets/linux/hardware.ts, src/facets/linux/config-file.ts, src/facets/linux/app.ts, src/core/recipe.ts, src/runtime/recipe/install.ts, recipes/antigravity.json, layer:ghostty, app:antigravity
---

# Fedora port decisions

Facets are platform-scoped: each facet and each device declares a `platform`, so `hardware` exists once for Windows and once for Linux instead of needing distinct names. Fixtures live under `fixtures/<platform>/<facet>/`.

`config-file` is observed, not managed: the old tool only captured `/etc/UPower/UPower.conf` and restoring it needs safe in-place editing plus a rule for removed items.

`rpm-ostree` reads the staged deployment when one exists, and the booted deployment otherwise, so capture and drift see the requested layer set across a reboot.

`app` is managed. Recipes under `recipes/` are strict data for source, paths, install kind, launcher, icon and desktop entries; the facet plans one recipe step and the CLI executes it from `src/runtime/recipe/` (release lookup, download, tarball/AppImage/binary install, launcher, desktop entry, icon, cache refresh). The port downloads single-stream instead of the old parallel ranged downloader, and drops its progress output.

`devices/fedora-laptop/tasks.json` holds the commands for the proposed `update` and `cleanup` verbs. The old "update installed apps" step has no argv and is not represented.

The Python `laptop` package still owns phone, media, shell hooks and the old task runner; those port in later phases, not with the facets.
