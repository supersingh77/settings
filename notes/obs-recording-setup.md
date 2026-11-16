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

**Applied automatically on 16 Nov 2026** (OBS was closed, changes written into its config):

- `Mic/Aux` pinned to the **Owl Lite** (`{0.0.1…7a0ffdb4…}`) with a filter chain, in this order: **Noise Suppression (RNNoise, −30)** → **Gain (+14 dB)** → **Limiter (−2 dB)**. Noise first so the gain amplifies clean voice, limiter last so a shout cannot clip.
- `Desktop Audio` pinned to **Speakers (Razer Barracuda X 2.4)** (`{0.0.0…143661e3…}`) instead of "follow the Windows default", so it cannot drift onto the Bluetooth speaker (44.1 kHz, 100–300 ms latency) when that connects.
- The duplicate Owl Lite source was deleted; the Razer and Digitek capture sources remain in the scene, **muted**, for A/B testing.

### First real recording, measured (16 Nov 2026, 21.6 s)

| Aspect | Measured | Verdict |
|---|---|---|
| Video | 1920×1080 @ 60 fps, H.264 High, yuv420p, ~2.3 Mbps, 6.3 MB | exactly as configured |
| Audio format | AAC 48 kHz stereo, 192 kbps | correct |
| Loudness | **−31.5 LUFS integrated**, true peak **−19.5 dBFS** | **far too quiet** — that's what the +14 dB gain fixes |
| Defects | no black frames, no clipped samples | clean |

With the gain applied the same take would land near **−17.5 LUFS with peaks around −5.5 dBFS**, which is the target range for voice on YouTube. If speech now sounds loud or breathy, drop Gain to +10 dB; if it still feels quiet, +16 dB.

### Second take, after the gain (17 Nov 2026, 89.9 s)

| Measure | Before gain | After gain |
|---|---|---|
| Integrated loudness | −31.5 LUFS | **−19.8 LUFS** |
| True peak | −19.5 dBFS | **−4.0 dBFS** |
| Mean / max (volumedetect) | −34.4 / −19.5 dB | −20.7 / −4.0 dB |
| Video | 1080p60, ~2.3 Mbps | 1080p60, 1080p60 intact, 23 MB for 90 s |

The gain did what the arithmetic predicted, slightly conservatively — −19.8 LUFS sits at the quiet end of the −16 to −20 target, so YouTube will normalise it up ~6 dB. That is fine. If you want it hotter, +2 dB more on the Gain filter lands near −17.8; no other change needed.

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

### Mic choice — by ear, 16 Nov 2026

Asked to rank three live mics with each isolated, the answer was:

| Rank | Mic | Character |
|---|---|---|
| 1 | **Kreo Owl Lite** | best raw quality, but **picks up the most room noise** (fan, keyboard, ambience) |
| 2 | **Digitek wireless** (clipped to the collar) | slightly behind on fidelity, **much cleaner** — has its own noise cancelling, and being 20 cm from the mouth rejects the room |
| 3 | **Razer Barracuda X** | surprisingly unimpressive; low output level, and it **auto-sleeps** when idle |

That ranking is the useful result: **quality vs noise is the real trade-off**, not "which mic is better". Two ways to settle it, in order of effort:

1. **Stick with the Owl Lite (current)** — it is pinned, and **Noise Suppression (RNNoise) is applied** on `Mic/Aux`. That is exactly the filter for "best quality but noisy": it keeps the fidelity and strips fan/keyboard. Adjust it under Audio Mixer → gear on `Mic/Aux` → Filters (lower `suppress_level` = more aggressive; RNNoise ignores that value, so switch to Speex only if you need manual strength).
2. **Switch to the Digitek** — swap `Mic/Auxiliary Device 1` in OBS → Audio to `Microphone (USBAudio1.0)`. Lower ceiling, less work, and the collar position does the noise rejection for free.

Keep only **one** voice source live. On 16 Nov the scene had the Owl Lite captured twice (its own source plus the global `Mic/Aux`) — the duplicate was deleted, and the Razer/Digitek sources were left muted. Both are still there, muted, for A/B testing.

`Mic/Aux` is pinned to the **Owl Lite** webcam mic:

```
WASAPI: Device 'Microphone (Owl Lite Audio)' [48000 Hz] initialized (source: Mic/Aux)
```

Wired and always available beats a headset mic that silently sleeps. To compare a candidate properly, confirm with `mic-check.ps1` that it is awake and unmuted — a sleeping Barracuda looks exactly like a dead mic:

```powershell
pwsh device/desktop/scripts/mic-check.ps1 -Seconds 6   # speak while it runs
```

**Beware the false negative.** The same device measured −91 dB on one pass and −31 dB on the next (device still opening, or held by another app). Two passes, or one while speaking, before writing a mic off.

`mic-check.ps1` uses **DirectShow**, the same path as ffmpeg. Some USB mics — the Digitek wireless receiver is one — register a Windows audio endpoint but expose no DirectShow device, so the script cannot see them even though OBS (which uses WASAPI) can. Judge those by OBS's own audio meter.

### Desktop Audio is on "default", and the default moved

OBS stores `device_id: "default"`, so it follows the Windows default output. On 16 Nov that was the MAG 255XF HDMI; after the Zebronics **ZEB-COUNTY** Bluetooth speaker was paired and connected it became the speaker — visible in the log:

```
WASAPI: Device 'Headphones (ZEB-COUNTY)' [44100 Hz] initialized (source: Desktop Audio)
```

That is *working as designed*, but it means the captured device changes whenever you change the Windows default. Two consequences:

- **Bluetooth adds 100–300 ms of latency** and drops to 44.1 kHz. Fine for listening, wrong for monitoring your own voice and liable to drift against the facecam.
- **The speaker's microphone is telephony-grade** (`Headset — ZEB-COUNTY Hands-Free`, an HFP endpoint at 8–16 kHz). It is a new capture device, and it should stay unused for recording.

For recording, pin Desktop Audio to whatever you actually monitor on — the Razer headset (2.4 GHz, low latency) is the reasonable choice — instead of trusting "default".

### Two traps worth remembering

1. **Global audio devices are stored in the scene collection, not the profile.** `AuxAudioDevice1` / `DesktopAudioDevice1` live in `%APPDATA%\obs-studio\basic\scenes\Untitled.json`. Keys in `basic.ini` (`AuxDevice1`, `Mic/Auxiliary Device 1`, …) are ignored — all four were tested and dropped.
2. **Hand-written filter entries are rejected; a copied template works.** An invented `filters` object is discarded when OBS loads — but **copying a filter that OBS itself wrote** (same shape: `prev_ver`, `mixers: 255`, `monitoring_enabled`, `versioned_id` mapping to the newer kind) and only changing `name`/`uuid`/`id`/`settings` is accepted. Verify with `GetSourceFilterList` over `obs-websocket` rather than assuming.
3. **OBS only writes the scene collection on a clean exit.** Every automated session that ended in `Stop-Process` lost the change; the ones closed with `taskkill /IM obs64.exe` (WM_CLOSE, `ConfirmOnExit=false`, a real window rather than `--minimize-to-tray`) saved it. If a config change "doesn't stick", suspect the shutdown, not the write.

Target peaks around **−12 to −6 dB**, mean voice around −18 dB. Watch the meter once, then trust it.

## Deliberately not done

Keeping the "delete before optimising" rule — none of these are needed yet:

- **AV1 or HEVC recording.** The RX 7600 can encode both, and AV1 would roughly halve file size at equal quality. Rejected for now because editing/upload paths add friction; H.264 opens everywhere.
- **Game Capture in place of Display Capture.** It captures one window, skips desktop composition and avoids the OBS window bleeding in. Worth adding when you next record a game, but it is a scene change, not a settings change.
- **Multi-track audio** (game and mic on separate tracks). Real editing value once you're cutting videos; needs per-source track assignment in Advanced Audio Properties.
- **Replay buffer, extra scene collections, plugin installs.** Zero benefit until the basics above are actually exercised. (Noise suppression is the one filter worth having — see the audio section.)

## If OBS resets

OBS's config is **not** in this repo (`%APPDATA%\obs-studio`), so these are the values to recreate. Snapshots sit next to the originals as `Untitled.json.bak-*`.

| Where | Setting |
|---|---|
| Settings → Video | Base **1920×1080**, Output **1920×1080**, **60 fps**, NV12 / Rec.709 / Partial |
| Settings → Output | **Simple** mode, `VBitrate 6000`, **Recording Quality = High Quality**, encoder **AMD HW H.264** for both |
| Settings → Output → Recording | Path **`Z:\Recordings`**, format **hybrid MP4** |
| Settings → Audio | Mic/Aux = **Owl Lite**, filters: Noise Suppression (RNNoise) → Gain **+14 dB** → Limiter **−2 dB**; Desktop Audio = **Razer Barracuda X** |
| Scene | Display Capture (MAG 255XF) + Video Capture Device (Owl Lite) |

## Re-verifying later

```powershell
pwsh device/desktop/scripts/audit-state.ps1   # flags an OBS profile recording to C:
```

Then record 30 seconds and read `%APPDATA%\obs-studio\logs\<latest>.txt` — it prints the encoder, rate control, resolution and output path actually used.
