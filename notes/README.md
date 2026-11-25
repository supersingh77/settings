---
refs:
---

# Notes

Long-term reference guides that outlive a single task. One topic per file, dated, with a `> Device:` line when it only applies to one machine.

## Index

| Note | Covers |
|------|--------|
| [desktop-setup.md](desktop-setup.md) | Desktop drive roles, the 300 Hz/MPRT display rule, Xbox 360 receiver and PXN controller quirks |
| [desktop-hardware.md](desktop-hardware.md) | Hardware facts probes miss: GPU VRAM field, stale ReviOS product name, S.M.A.R.T./cooler, network and Bluetooth caveats |
| [desktop-start-menu.md](desktop-start-menu.md) | Why Start menu pin order is not captured, broken `Export-StartLayout`, no pin backup |
| [desktop-maintenance.md](desktop-maintenance.md) | Proposed update/cleanup tasks and safe-cleanup judgement |
| [desktop-layout.md](desktop-layout.md) | Desktop placement rules |
| [desktop-known-traps.md](desktop-known-traps.md) | Folders that are not installs, recordings-on-C policy, version-field and Steam-library traps |
| [desktop-install-policy.md](desktop-install-policy.md) | Winget-first install policy, per-user exceptions, winget failure modes |
| [obs-recording-setup.md](obs-recording-setup.md) | Desktop OBS recording settings, source choices, separate audio tracks, and extraction from MKV |
| [ffmpeg-video-workflow.md](ffmpeg-video-workflow.md) | Lossless trim/concat of recordings; when to re-encode, when to remux |
| [windows-shell-repair.md](windows-shell-repair.md) | ReviOS 26H2 shell failure: default-verb launches and the app picker fail while explicit "Open with ▸" works. What is broken, what not to do, three-step repair path. Unresolved |

## Adding a note

```md
# Short title

> Device: desktop / laptop / fedora-laptop / phone / shared
> Added: YYYY-MM-DD

## What it covers
## Steps / settings
## Gotchas
```

Keep it about *how the thing works and why*, not a snapshot of current versions — those belong in the device docs and go stale fastest.
