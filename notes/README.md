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
