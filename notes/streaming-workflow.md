# 05 — Streaming Workflow (Full Car)

> Your complete process from boot-up to upload.  
> Philosophy: Do the whole thing, note what sucks, improve one thing next time.

---

## 🏁 The Full Loop

```
SETUP → STREAM → SAVE → TRIM → POST → REVIEW
  ↑                                ↓
  └─────────── 1% better ──────────┘
```

---

## 1️⃣ Before Stream — Setup

### Hardware Check
- [ ] PC turned on, no one else using it
- [ ] Phone charged, DroidCam app open
- [ ] Phone connected to Wi-Fi (same network as PC)
- [ ] Wheel/pedals plugged in

### Software Check
- [ ] **OBS Studio** — open, scene selected (Game + Facecam + Mic)
- [ ] **DroidCam** — connected (phone feed showing in OBS or as always-on-top window)
- [ ] **Assetto Corsa** — loaded via Content Manager
- [ ] **Discord** — open (for chat / friends)
- [ ] Close Chrome/Firefox (saves RAM/VRAM for streaming)

### OBS Quick Settings (from notes/03)
- Encoder: AMD HW H.264 (AMF)
- Bitrate: 6000 Kbps
- Output: 1280×720 @ 30fps (30fps recommended — 60fps halves quality at 6000 Kbps)
- Scene: Game capture + Facecam + Mic

### Twitch
- [ ] Go to twitch.tv → Creator Dashboard → check stream key in OBS
- [ ] Set title: e.g. "Assetto Corsa practice — Imola, manual gears"
- [ ] (Optional) Set a category: "Assetto Corsa"

---

## 2️⃣ During Stream — Go Live

1. Click **Start Streaming** in OBS
2. Launch Assetto Corsa via Content Manager
3. Drive your practice session (e.g. 30 min Imola)
4. Chat with any viewers if they show up
5. When done, click **Stop Streaming** in OBS

### What Works
- DroidCam always-on-top window as facecam (plugin workaround)
- 10-minute sessions are good length
- Manual gears + learning = natural content

### What to Watch For
- FPS drops? → Lower AC world detail or OBS output resolution
- Audio issues? → Check mic levels in OBS
- Facecam lag? → Check Wi-Fi signal

---

## 3️⃣ After Stream — Save the VOD

Twitch auto-saves your stream as a VOD.

### Download from Twitch
1. Go to **twitch.tv/amrx7872** → **Creator Dashboard**
2. Click **Content** → **Video Producer**
3. Find your latest stream
4. Click **Download** (saves as MP4, ~720p)

VOD lands in: `%USERPROFILE%\Downloads\`

---

## 4️⃣ Trim the Highlight

### Tool: FFmpeg (instant, lossless)
```powershell
# Cut a segment from the video (no re-encode)
ffmpeg -ss 00:06:26 -i "input.mp4" -to 00:02:50 -c copy -avoid_negative_ts make_zero "output.mp4"
```

| Parameter | What it does |
|-----------|-------------|
| `-ss 00:06:26` | Start at 6 min 26 sec |
| `-i input.mp4` | Source file |
| `-to 00:02:50` | Output length (2 min 50 sec) |
| `-c copy` | Copy video+audio without re-encoding (instant) |

**Tip for next time:** Adjust `-ss` and `-to` values depending on which part of the VOD is best.

### Manual option: ShareX
- Open ShareX → Task → Screen Recording → Video Converter
- Load VOD, trim visually, export as MP4

### Constraint reference
- YouTube: under 3 min → recommended to non-subscribers
- Instagram: under 60 sec (stories), up to 90 sec (reels)
- Last 30 sec of VOD often dead air → always cut it

---

## 5️⃣ Post to Platforms

### YouTube
1. Go to [studio.youtube.com](https://studio.youtube.com)
2. Click **Upload** → Select trimmed MP4
3. Title: e.g. "Assetto Corsa — Imola Practice (Manual Gears)"
4. Description: "Quick practice session on Imola. Streaming on twitch.tv/amrx7872"
5. Visibility: Public or Unlisted
6. Click **Publish**

### Instagram (via phone)
1. Open **LocalSend** on PC → Send the MP4 file to your phone
2. On phone: Open Instagram → **+** → **Reel**
3. Select the video (horizontal works fine, Instagram accepts it)
4. Trim to under 90 sec if needed (in-app tool)
5. Add caption + hashtags: `#assettocorsa #simracing #imola`
6. **Post**

---

## 6️⃣ Review & Improve (1% Better)

After each full cycle, pick ONE thing to improve. Don't try to fix everything.

### Improvement Ideas (pick one next time)

| Area | Potential Improvement | Difficulty |
|------|----------------------|------------|
| **Facecam** | Get DroidCam OBS plugin working (cleaner than always-on-top) | Medium |
| **Quality** | Stream at 1080p instead of 720p (check if RX 7600 can handle it) | Medium |
| **Audio** | Set up Voicemeeter Banana for separate game/mic/stream audio | Hard |
| **Trimming** | Save Twitch clips during stream instead of trimming VOD after | Easy |
| **Thumbnail** | Make a custom thumbnail for YouTube (ShareX + basic edit) | Easy |
| **Scheduling** | Stream at same time/day each week | Easy |
| **AC Performance** | Tweak CSP settings further for smoother FPS | Medium |
| **Clip Sharing** | Use Discord to share clips with friends instantly | Easy |
| **VOD Titles** | Consistent naming convention for VODs | Easy |
| **Multi-platform** | Automate cross-posting YouTube → Instagram | Hard |

### Tracking
Keep a simple log after each stream:

```
Stream #1 — 30 May 2026
├── VOD: 10 min, Imola, manual gears ✅
├── Facecam: DroidCam always-on-top (workaround) ⚠️
├── FPS: Playable but room for improvement ⚠️
├── Posted: YouTube + Instagram ✅
└── 1% improvement for next time: [pick one from the table]
```

---

## Tools Reference

| Tool | What For | Where |
|------|----------|-------|
| **OBS Studio** | Streaming + recording | Start Menu |
| **DroidCam Client** | Phone → PC webcam | Start Menu |
| **Content Manager** | Launch Assetto Corsa with mods | Start Menu |
| **Discord** | Chat, community, share clips | Start Menu |
| **ShareX** | Screenshots, VOD trimming | Start Menu |
| **FFmpeg** | Fast lossless video trimming | Terminal (`ffmpeg`) |
| **LocalSend** | Send files PC ↔ phone | Start Menu |
| **HWiNFO** | Monitor temps/usage while streaming | Start Menu |
| **Git** | Track your config docs | Terminal (`git`) |

---

## Git History (your docs)

```
3a4a459 — Update software.md with installed versions
a1111c7 — Add notes: DroidCam, AC optimization, OBS settings, VOD guide
39b7d30 — Update software.md: DroidCam OBS Plugin removed
a4628ba — Initial setup: document PC hardware and software plan
```

All docs live at: `C:\Users\amar\Desktop\config\`
