# 04 — VOD Posting Workflow

> Status: First VOD downloaded from Twitch Video Producer ✅
> Current approach: **"Full car"** — do it manually now, optimize later

---

## ⚡ VOD Quality Fix (10 Jun 2026)

First stream VOD looked horrible when downloaded. Root cause:

- **OBS was streaming at 720p60 @ 6000 Kbps** — 60fps halves the bitrate per frame
- **Changed to 720p30 @ 6000 Kbps** — doubles bits per frame, way cleaner on VOD
- **Downscale filter changed** from `bicubic` to `lanczos` — sharper image

**Why this matters for VODs:** Twitch re-encodes VODs at even lower bitrates than the live stream. At 60fps the VOD becomes a blocky mess. 30fps keeps it watchable.

**When downloading from Twitch Video Producer:** always pick the **Source** quality option (not a lower transcode) for the best quality download.

---

## File Reference

- Twitch channel: **twitch.tv/amrx7872**
- First VOD: 10 min Assetto Corsa @ Imola (manual gears!)
- Downloaded via: Twitch Creator Dashboard → Content → Video Producer

---

## Current Process (Manual — The "Brutal" Way)

### 1. Trim the VOD
**Option A: ShareX (installed ✅)**
- Open ShareX → Task → Screen Recording → Video Converter
- Load the VOD file, trim to best moments
- Export as MP4

**Option B: FFmpeg (installed ✅ via winget)**
```powershell
# Trim without re-encoding (fast, no quality loss)
ffmpeg -i "input.mp4" -ss 00:01:00 -to 00:03:00 -c copy "output.mp4"
```
- `-ss` = start time (HH:MM:SS)
- `-to` = end time
- `-c copy` = copies video/audio without re-encoding (instant!)

**Option C: Free editors**
- DaVinci Resolve (professional, steep learning curve)
- CapCut Desktop (easier, good for social media)

### 2. Export for Instagram
- Format: **MP4**
- Aspect: **9:16 vertical** (1080×1920) or **1:1 square** (1080×1080)
- Length: **≤ 60 seconds** (Reels limit)
- Resolution: 1080×1920 (vertical)

### 3. Export for YouTube
- Format: **MP4**
- Aspect: **16:9** (1920×1080)
- Length: Any
- Title idea: "First time driving Imola in Assetto Corsa | Manual Gears | Twitch Stream VOD"

### 4. Upload
- **YouTube**: studio.youtube.com → Upload → Add title/description
- **Instagram**: Phone app → Upload reel (transfer file to phone via LocalSend, which you have installed ✅)

---

## Future Optimizations (For Next Time)

After doing this manual process 2-3 times, pick ONE thing to automate:

| Process Step | Future Automation Idea |
|-------------|----------------------|
| Trimming | Auto-save Twitch clips instead of full VOD |
| Instagram format | FFmpeg script to auto-crop to vertical |
| Captions | Use YouTube auto-captions or a simple tool |
| File transfer | LocalSend already installed ✅ |
| Scheduling | Buffer one week of content |

---

## Tools You Have for This

| Tool | Status | Use |
|------|--------|-----|
| **ShareX** | ✅ Installed | Screenshots, recording, basic trim |
| **FFmpeg** | ✅ Installed | Trim without re-encoding |
| **LocalSend** | ✅ Installed | Send files phone ↔ PC |
| **OBS** | ✅ Installed | Future: record locally for higher quality |
| **Chrome/Firefox** | ✅ Installed | YouTube/Instagram upload |

---

## Your Philosophy

> *"No one can become a big streamer from day one. I'm going to be patient and have low expectations. I'd rather get 1% profit today than 20% in a month."*

**Execution beats perfection.** The first VOD posted manually > the perfect VOD never posted. Keep this "full car" mindset — do the whole process, note what sucks, improve one thing next time.
