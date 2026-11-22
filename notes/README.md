# Notes

Long-term reference guides that outlive a single task. One topic per file, dated, with a `> Device:` line when it only applies to one machine.

## Index

| Note | Covers |
|------|--------|
| [obs-recording-setup.md](obs-recording-setup.md) | Desktop OBS recording settings, separate audio tracks, and extraction from MKV |
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

## Removed 16 Nov 2026

Dropped because they described setups that no longer exist and would have been misleading:

- `assetto-corsa-drift-setup.md`, `assetto-corsa-optimization.md`, `assetto-corsa-wheel-ffb.md` — sim-racing tuning for the old setup, untouched for months
- `droidcam-obs-plugin.md`, `obs-stream-settings.md`, `streaming-workflow.md` — built around the phone-DroidCam webcam; replaced by a Kreo Owl Lite, so the OBS/DroidCam stack is being rebuilt from scratch
- `music-starter.md`, `vod-posting-guide.md` — personal guides unrelated to system configuration

The `games/` folder (Assetto Corsa `.ini` backups and Content Manager presets) was removed at the same time for the same reason: the settings no longer matched the car/wheel setup. Everything is still in Git history if it is ever needed.
