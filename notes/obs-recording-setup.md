# OBS Recording & Streaming Setup

> Device: desktop | Written: 2026-11-16 | Status: recording ready, streaming not configured
> Verified from OBS 33.0.1's own logs after a real test recording, not from the GUI.

## The split that drives every choice

Local **recording** is quality-bound — bandwidth is irrelevant, so spend disk for sharpness.
Live **streaming** is bandwidth-bound — 6000–9000 kbps total decides everything.

Recording for YouTube therefore does **not** need to match the stream. OBS's default "record same as stream" collapses the two and caps local recordings at stream bitrate; that was the biggest thing wrong with the old profile.

## Verified configuration (2026-11-16)

| Setting | Value | Why |
|---|---|---|
| Encoder (both) | **AMD HW H.264 (AVC)** — `amd` | Offloads to the GPU media engine. The old profile used **x264 software at 6000 kbps**, which competes with the game for CPU and is why 1080p60 was not viable before |
| Recording quality | **High Quality** → **CQP 23**, preset *quality* | Constant-quality: bitrate follows the scene. Static screens cost almost nothing, racing costs what it needs. ~2× the visual quality of 6000 kbps CBR for the same footage |
| Base resolution | 1920×1080 | Native panel |
| Output resolution | **1920×1080** (was 1280×720) | 720p discards half your panel; YouTube gives 1080p60 its own ladder |
| FPS | **60** (was 30) | Racing reads far better at 60; the 300 Hz panel makes 60 trivial to render |
| Format | `hybrid_mp4` | MP4 compatibility + crash-safe hybrid remux |
| Recording path | **`Z:\Recordings`** (was `C:\Users\amar\Videos`) | C: is the OS drive at ~66 GB free; Z: has ~480 GB |
| Audio | 48 kHz stereo, AAC 192 (record) / 160 (stream) | 192 is worth it for voice |
| Colour | NV12 / Rec.709 / Partial | Correct SDR, matches capture |

Result of the test recording: `cqp: 23, preset: quality, 1920x1080`, written to `Z:\Recordings`.

## Streaming (not yet configured)

No service is set, so nothing streams until you add a key. Bitrate guidance with a 40 Mbps upload:

| Platform | Resolution | Bitrate |
|---|---|---|
| Twitch (non-partner) | 1080p60 or 720p60 | **6000** — hard ceiling, 720p60 looks sharper at this rate |
| YouTube | 1080p60 | 8000–9000 |
| Kick | 1080p60 | 8000 |

Keep OBS at 6000 while you might stream anywhere; raise it only if you commit to YouTube/Kick. Recording is unaffected either way now.

> Simple output mode shares **one** output resolution between stream and recording. Streaming 720p60 while recording 1080p60 requires switching Output mode to **Advanced** (separate encoders, separate rescale). Don't bother until a platform actually forces the issue.

## Audio — the part most likely to bite

OBS currently captures:

- **Mic/Aux** → `Microphone (Owl Lite Audio)` — the webcam's built-in mic
- **Desktop Audio** → `4 - MAG 255XF (AMD High Definition Audio Device)` — the monitor's HDMI output, **not** your headphones or interface

Measured on the two existing recordings: 12 Nov averaged **−37.8 dB** (too quiet), 14 Nov **−18.4 dB** (healthy). Quiet voice is the classic "sounds bad on YouTube" cause — viewers turn it up and hear hiss.

Worth doing:

1. **Check Desktop Audio matches what you hear.** If you game on the Focusrite or Razer headset while Windows' default output is the monitor, OBS records the wrong (or silent) device. Set OBS → Audio → Desktop Audio to the device you actually listen on.
2. **Use the Focusrite for voice if a mic is plugged into it.** `Analogue 1 + 2` is a live input; a Scarlett + XLR mic beats any webcam mic by a wide margin. Otherwise keep the webcam mic and add **Noise Suppression** + a small **Gain** filter.
3. Target peaks around **−12 to −6 dB**, mean voice around −18 dB.

## Deliberately not done

Keeping the "delete before optimising" rule — none of these are needed yet:

- **AV1 or HEVC recording.** The RX 7600 can encode both, and AV1 would roughly halve file size at equal quality. Rejected for now because editing/upload paths add friction; H.264 opens everywhere.
- **Game Capture in place of Display Capture.** It captures one window, skips desktop composition and avoids the OBS window bleeding in. Worth adding when you next record a game, but it is a scene change, not a settings change.
- **Multi-track audio** (game and mic on separate tracks). Real editing value once you're cutting videos; needs per-source track assignment in Advanced Audio Properties.
- **Replay buffer, scene collections, filters, plugins.** Zero benefit until the basics above are actually exercised.

## Re-verifying later

```powershell
pwsh device/desktop/scripts/audit-state.ps1   # flags an OBS profile recording to C:
```

Then record 30 seconds and read `%APPDATA%\obs-studio\logs\<latest>.txt` — it prints the encoder, rate control, resolution and output path actually used.
