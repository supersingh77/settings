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

## Audio — measured, not assumed

Device inventory on this machine (16 Nov 2026):

| Device | Role | State |
|---|---|---|
| **Kreo Owl Lite** | webcam + its mic | camera and **mic both work** — −31.8 dB mean / −6.1 dB peak, then −48.1 / −12.4 on a second pass. **Pinned as OBS's `Mic/Aux`**: wired, always on, no battery |
| **Razer Barracuda X 2.4** | headset mic **+** playback | works while awake (−45.1 dB mean, −27.7 dB peak) but **auto-mutes or sleeps when idle** — later passes read −74 dB, and one test recording captured −85 dB of nothing |
| **Focusrite Scarlett Solo** | `Analogue 1 + 2` input | connected, unused (guitar, not played this year), nothing plugged in → −91 dB |
| **Digitek USB wireless mic** | receiver `USBAudio1.0` | not plugged in (device state = not present) |
| **Zebronics BT speaker** | playback | not used for capture |
| Realtek ALC897 onboard | mic/line jacks | present as hardware, nothing plugged |

**The monitor has no microphone.** HDMI audio is output-only; the "extra mic" you noticed is the motherboard's Realtek mic jack, which Windows lists even with nothing connected.

### Mic choice

`Mic/Aux` is pinned to the **Owl Lite** webcam mic:

```
WASAPI: Device 'Microphone (Owl Lite Audio)' [48000 Hz] initialized (source: Mic/Aux)
```

Wired and always available beats a headset mic that silently sleeps. For better voice, wear the headset and switch `Mic/Aux` to it — but only after confirming with `mic-check.ps1` that it is awake and unmuted, because a sleeping Barracuda looks exactly like a dead mic:

```powershell
pwsh device/desktop/scripts/mic-check.ps1 -Seconds 6   # speak while it runs
```

**Beware the false negative.** The same device measured −91 dB on one pass and −31 dB on the next (device still opening, or held by another app). Two passes, or one while speaking, before writing a mic off.

### Desktop Audio is still on "default"

It currently resolves to `4 - MAG 255XF` (the monitor's HDMI). OBS's `device_id: "default"` means **it follows whatever Windows has as default output**, so:

- If you wear the headset while gaming → set the headset as the Windows default output, and OBS follows automatically.
- If you want them independent, pin Desktop Audio to the headset in OBS → Audio (or edit `DesktopAudioDevice1.settings.device_id` in the scene collection).

Using the headset for both playback and mic also removes the echo risk of monitor speakers leaking into the mic.

### Two traps worth remembering

1. **Global audio devices are stored in the scene collection, not the profile.** `AuxAudioDevice1` / `DesktopAudioDevice1` live in `%APPDATA%\obs-studio\basic\scenes\Untitled.json`. Keys in `basic.ini` (`AuxDevice1`, `Mic/Auxiliary Device 1`, …) are ignored — all four were tested and dropped.
2. **Hand-written filter entries get discarded.** Adding a `filters` array to `AuxAudioDevice1` survived OBS's parse but was stripped on the next save, so filters have to be added through the UI: **Audio Mixer → gear icon on Mic/Aux → Filters → + → Noise Suppression** (RNNoise, no tuning needed). That is the single best remaining audio improvement — it kills fan and keyboard noise on any mic.

Target peaks around **−12 to −6 dB**, mean voice around −18 dB. Watch the meter once, then trust it.

## Deliberately not done

Keeping the "delete before optimising" rule — none of these are needed yet:

- **AV1 or HEVC recording.** The RX 7600 can encode both, and AV1 would roughly halve file size at equal quality. Rejected for now because editing/upload paths add friction; H.264 opens everywhere.
- **Game Capture in place of Display Capture.** It captures one window, skips desktop composition and avoids the OBS window bleeding in. Worth adding when you next record a game, but it is a scene change, not a settings change.
- **Multi-track audio** (game and mic on separate tracks). Real editing value once you're cutting videos; needs per-source track assignment in Advanced Audio Properties.
- **Replay buffer, extra scene collections, plugin installs.** Zero benefit until the basics above are actually exercised. (Noise suppression is the one filter worth having — see the audio section.)

## Re-verifying later

```powershell
pwsh device/desktop/scripts/audit-state.ps1   # flags an OBS profile recording to C:
```

Then record 30 seconds and read `%APPDATA%\obs-studio\logs\<latest>.txt` — it prints the encoder, rate control, resolution and output path actually used.
