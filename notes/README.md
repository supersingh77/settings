# Notes

Long-term reference guides that outlive a single task. One topic per file, dated, with a `> Device:` line when it only applies to one machine.

## Index

| Note | Covers |
|------|--------|
| [obs-recording-setup.md](obs-recording-setup.md) | OBS as configured 16 Nov 2026: AMF, CQP 23, 1080p60, `Z:\Recordings`; the record-vs-stream split, audio gotchas, streaming bitrates per platform |
| [ffmpeg-video-workflow.md](ffmpeg-video-workflow.md) | Lossless trim/concat of recordings; when to re-encode, when to remux |
| [windows-shell-repair.md](windows-shell-repair.md) | ReviOS 26H2 shell failure: `OpenWith` / picker dies at launch, `.mp4`/`.m4a` have no default app. Unresolved — repair path documented |

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
