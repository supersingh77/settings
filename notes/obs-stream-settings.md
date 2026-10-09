# 03 — OBS Streaming Settings

> Hardware: Ryzen 7 5700X | RX 7600 4GB | 16GB RAM
> Internet: 40 Mbps Airtel (ethernet, 4ms ping)
> Platform: Twitch

---

## Recommended OBS Settings

These are optimized for **1080p streaming** on your hardware — balance of quality vs performance.

### Output (Streaming tab)

| Setting | Value | Notes |
|---------|-------|-------|
| **Encoder** | AMD HW H.264 (AMF) | Uses GPU hardware encoder — leaves CPU free for gaming |
| **Rate Control** | CBR | Required for Twitch |
| **Bitrate** | 6000 Kbps | Twitch max non-partner bitrate |
| **Keyframe Interval** | 2 | Twitch requires 2 |
| **Preset** | Quality | Default is fine |
| **GPU Scaling** | Enabled | Lets GPU handle resize |

### Video

| Setting | Value | Notes |
|---------|-------|-------|
| **Base Resolution** | 1920×1080 | Your monitor native |
| **Output Resolution** | 1920×1080 | Can drop to 1280×720 if FPS is bad |
| **Downscale Filter** | Lanczos | ✅ Sharpest option — switched from bicubic |
| **FPS** | 30 | ✅ Set to 30 (720p @ 6000 Kbps looks much cleaner at 30fps — 60fps halves per-frame quality) |

### Audio

| Setting | Value | Notes |
|---------|-------|-------|
| **Sample Rate** | 48 kHz | Standard |
| **Desktop Audio** | Default (your speakers/headphones) | Game sounds |
| **Mic/Aux** | Your microphone device | Your voice |
| **Mic Noise Gate** | -26 dB (close) | Cuts background noise when silent |

### Advanced

| Setting | Value | Notes |
|---------|-------|-------|
| **Color Format** | NV12 | Standard for streaming |
| **Color Space** | Rec. 709 | Standard for SDR |
| **Color Range** | Partial | TV standard (better compatibility) |

---

## Scene Setup (Minimal)

Create these sources:

1. **Game Capture** → Assetto Corsa
2. **DroidCam Virtual Camera** or **DroidCam plugin source** → your facecam
3. **Audio Input Capture** → your mic
4. **(Optional) Text** → "twitch.tv/amrx7872" overlay

Don't overcomplicate scenes. Start with one scene called "Streaming" with just:
- Game capture (90% of screen)
- Facecam (small, bottom-right)
- Mic audio

---

## If You Get Low FPS While Streaming

1. Drop output resolution to **1280×720** (720p)
2. Drop FPS to **30**
3. Close other apps (especially browsers)
4. In AMD Adrenalin → Gaming → Assetto Corsa → Set **"Performance"** profile
5. Reduce AC's World Detail to 2 (see note 02)

---

## Twitch Integration

1. Go to **Twitch.tv → Creator Dashboard → Settings → Stream Key & Preferences**
2. Copy your **Stream Key**
3. In OBS → Settings → Stream → Service: **Twitch** → Paste stream key
4. Click **Start Streaming**

Your VOD will auto-save on Twitch (you can download from Video Producer).
