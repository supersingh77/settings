---
refs:
---

# FFmpeg Video Workflow

> My preferred way to join and trim video clips with ffmpeg.
> Philosophy: **lossless first** — stream copy (`-c copy`) whenever possible, never re-encode unless the clips are incompatible.

---

## Core preference

- **Lossless concat** for joining clips that share the same codec/resolution/framerate/audio.
- **Stream copy** (`-c copy`) for trimming — instant, no quality loss.
- Only re-encode when clips are incompatible (different resolution, fps, or codec).
- Order clips **chronologically by filename timestamp** (e.g. `VID_20260905_160401.mp4` before `VID_20260905_161259.mp4`).

---

## Join (concat) — lossless

Works when all clips are the same format (same codec, resolution, fps, audio). Phone/OBS recordings from the same source usually qualify.

```powershell
# 1. Create a concat list file (same folder as the clips)
#    clips.txt:
#    file 'VID_20260905_160401.mp4'
#    file 'VID_20260905_161259.mp4'

# 2. Join (instant, no quality loss)
ffmpeg -f concat -safe 0 -i clips.txt -c copy "joined.mp4"
```

### Verify compatibility first

```powershell
ffmpeg -i "clip1.mp4" 2>&1 | Select-String "Duration|Stream"
ffmpeg -i "clip2.mp4" 2>&1 | Select-String "Duration|Stream"
```

Check that both show the same:
- Video codec (e.g. `h264`)
- Resolution (e.g. `1920x1080`)
- Framerate (e.g. `30 fps`)
- Audio codec + sample rate (e.g. `aac 48000 Hz`)

If they match → lossless concat. If not → use the re-encode fallback below.

### Re-encode fallback (incompatible clips)

```powershell
ffmpeg -i "clip1.mp4" -i "clip2.mp4" `
  -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" `
  -map "[v]" -map "[a]" "joined.mp4"
```

Slower, re-encodes, but handles mismatched clips.

---

## Trim — lossless

```powershell
# Cut a segment (no re-encode)
ffmpeg -ss 00:06:26 -i "input.mp4" -to 00:02:50 -c copy -avoid_negative_ts make_zero "output.mp4"
```

| Parameter | What it does |
|-----------|-------------|
| `-ss 00:06:26` | Start at 6 min 26 sec |
| `-to 00:02:50` | Output length (2 min 50 sec) |
| `-c copy` | Copy video+audio without re-encoding (instant) |

---

## Notes

- Twitch VODs / OBS recordings from the same session are usually compatible → lossless concat works.
- Always verify the joined/trimmed output plays correctly before deleting sources.
- The concat list file (`clips.txt`) is temporary — delete it after use.
- Big files: a 54-min 1080p clip at ~20 Mbps is ~7.7 GB. Expect large outputs when sources are large.

---

## Related

- [`join-videos.ps1`](../device/desktop/scripts/join-videos.ps1) — lossless concat of clips in a folder
- [`remux-audio-back.ps1`](../device/desktop/scripts/remux-audio-back.ps1) — put cleaned audio back into the original video without re-encoding it
