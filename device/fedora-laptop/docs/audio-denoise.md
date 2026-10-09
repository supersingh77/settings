# 🎙️ Audio Denoising Guide

Workflow for using **Adobe Podcast** to clean up video audio on Fedora Silverblue.

## 🛠️ Tools Used
- `ffmpeg` (Host system)
- [Adobe Podcast Enhanced Speech](https://podcast.adobe.com/enhance) (Web-based)

---

## 🏃 Workflow

### 1. Extract Audio
Use the `audio-denoise.sh` script to pull the raw audio from your video without re-encoding:

```bash
bash scripts/audio-denoise.sh extract VID_VID_20260325_212718.mp4
```
*Output: `VID_20260325_212718_audio.m4a`*

### 2. Enhance via Adobe Podcast
1. Go to [podcast.adobe.com/enhance](https://podcast.adobe.com/enhance).
2. Upload the extracted `.m4a` file.
3. Download the resulting `.wav` or `.mp4` file.

### 3. Merge Back
Merge the enhanced audio back into the original video (while keeping the original video stream):

```bash
bash scripts/audio-denoise.sh merge VID_20260325_212718.mp4 VID_20260325_212718_enhanced.wav
```
*Output: `VID_20260325_212718_denoised.mp4`*

---

## ⚠️ Notes
- **Subtitles**: If you have subtitles (`.srt`), it's recommended to upload them separately to platforms like YouTube, as embedding them in MP4 can sometimes be inconsistent depending on the local `ffmpeg` codecs.
- **Efficiency**: The script uses `copy` mode for both video and audio, meaning it's extremely fast and maintains the exact quality of the processed files.
