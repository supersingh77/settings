# OBS Recording Setup

> Device: desktop | Updated: 2026-11-23 | OBS 33.0.3

Current recording choices are tracked in [`device/desktop/declared/obs.json`](../device/desktop/declared/obs.json). OBS settings live under `%APPDATA%\obs-studio`; the repo file documents intent, it does not apply settings.

## Recording

- Output Mode: **Advanced**; Recording Type: **Standard**. Standard supports the selected MKV audio tracks; FFmpeg output mode is not needed.
- **AMD HW AV1**, CQP **23**, High Quality preset; 1920×1080 at 60 fps; MKV; `Z:\Recordings`.
- CQP is variable bitrate: lower CQ values use more data for better quality. The Airtel 40 Mbps plan is an internet upload speed and does not cap local recording. `Z:` had about 478 GiB free when checked.
- AAC, 48 kHz stereo, 192 kbps per track.

## Separate desktop and microphone audio

OBS puts both tracks in **one MKV file**. In **Advanced Audio Properties**, assign:

| Source | Track 1 | Track 2 |
|---|---:|---:|
| Desktop Audio | ✓ | |
| Mic/Aux (Owl Lite) | | ✓ |

Then in **Settings → Output → Recording → Audio Track**, enable only 1 and 2. Muted candidate microphone sources remain muted. To compare them, unmute one and explicitly route it to the track you want.

Extract AAC tracks into separate files with FFmpeg:

```powershell
ffmpeg -i "Z:\Recordings\recording.mkv" -map 0:a:0 -c copy "desktop.aac"
ffmpeg -i "Z:\Recordings\recording.mkv" -map 0:a:1 -c copy "mic.aac"
```

## Latest file checked

`2026-11-23 02-12-11.mkv` had four AAC streams. The `desktop` and `mic` streams were identical to each other; streams 3 and 4 were another identical pair. Thus labels alone did not indicate isolated sources. OBS routing was corrected on 23 Nov; no post-change recording has been checked yet.
