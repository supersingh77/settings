---
refs: obs:output.mode, obs:output.recordingType, obs:output.recEncoder, obs:output.recFormat, obs:output.recFilePath, obs:output.recTracks, obs:video.fps, obs:audio.sampleRate, obs:audio.channels
---

# OBS Recording Setup

> Device: desktop | Updated: 2026-11-23 | OBS 33.0.3

Current recording choices are recorded in [`devices/desktop/state/obs.jsonl`](../devices/desktop/state/obs.jsonl). OBS keeps them under `%APPDATA%\obs-studio` in `global.ini` and the active profile's `basic.ini`; the state file is a read-only capture of that profile, so changing it here does not change OBS.

## Recording

- Output Mode: **Advanced**; Recording Type: **Standard**. Standard supports the selected MKV audio tracks; FFmpeg output mode is not needed.
- **AMD HW AV1**, CQP **23**, High Quality preset; 1920×1080 at 60 fps; MKV; `Z:\Recordings`.
- CQP is variable bitrate: lower CQ values use more data for better quality. The Airtel 40 Mbps plan is an internet upload speed and does not cap local recording. `Z:` had about 478 GiB free when checked.
- AAC, 48 kHz stereo, 192 kbps per track.

## Microphone and desktop audio choices

- **Mic/Aux is the Owl Lite webcam mic** because it is wired and always on. The Razer Barracuda X mic auto-sleeps when idle and then records near-silence, so it is not safe as the default recording mic.
- **Desktop audio is pinned to the Barracuda X output**, not "default": the default followed Windows onto the Bluetooth speaker, which runs at a different sample rate and adds Bluetooth latency.
- **One live microphone only.** Capturing the Owl Lite twice (its own source plus global Mic/Aux) comb-filters the voice.
- **Digitek USB wireless mic** is visible to OBS through WASAPI but not to DirectShow, so ffmpeg and `mic-check.ps1` cannot measure it.
- The Zebronics Bluetooth speaker's mic is a low-bandwidth HFP telephony endpoint, not a recording mic. No monitor has a microphone; HDMI audio is output only.
- Mic filter order is noise suppression → gain → limiter: gain amplifies clean voice, and the limiter last prevents clipping.

Keep OBS stream keys out of the repository.

## Separate desktop and microphone audio

OBS puts these tracks in **one MKV file**. For the microphone comparison recording, the sources were assigned:

| Source | Track |
|---|---:|
| Desktop Audio | 1 |
| Mic/Aux (Owl Lite webcam mic) | 2 |
| Razer Barracuda X headphone mic | 3 |

In **Settings → Output → Recording → Audio Track**, enable the tracks being recorded. Keep each mic on its own track so an editor can select one mic and mix it with desktop audio.

Extract timestamp-preserving M4A copies from a three-track recording with FFmpeg:

```powershell
ffmpeg -i "Z:\Recordings\recording.mkv" -map 0:a:0 -c copy "desktop.m4a"
ffmpeg -i "Z:\Recordings\recording.mkv" -map 0:a:1 -c copy "webcam-mic.m4a"
ffmpeg -i "Z:\Recordings\recording.mkv" -map 0:a:2 -c copy "headphone-mic.m4a"
```

## Latest file checked

`2026-11-23 02-43-13.mkv` has three separate AAC streams: desktop, Owl Lite webcam mic, and Razer Barracuda X headphone mic. Source integrated loudness / true peak:

| Source | Integrated | True peak |
|---|---:|---:|
| Desktop | −14.0 LUFS | −2.6 dBFS |
| Owl Lite webcam mic | −20.5 LUFS | −6.0 dBFS |
| Razer headphone mic | −47.2 LUFS | −26.2 dBFS |

Two comparison mixes were saved in `Z:\Recordings`, keeping the AV1 video unchanged and mixing audio to FLAC. Both were loudness-matched near −18 LUFS / −2 dBTP:

| File | Desktop gain | Mic gain | Measured mix |
|---|---:|---:|---:|
| `2026-11-23 02-43-13 - webcam mic mix.mkv` | −4 dB | +3 dB | −17.6 LUFS / −2.8 dBFS true peak |
| `2026-11-23 02-43-13 - headphone mic mix.mkv` | −10 dB | +24 dB | −17.8 LUFS / −2.0 dBFS true peak |

The headphone mic needs a large capture gain increase; boosting it in post can raise its noise floor.
