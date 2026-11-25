---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/state/hardware.jsonl
---

# Audio denoise

Denoising is a person-in-the-loop workflow:

1. `bun run dev media extract VIDEO` writes `VIDEO_audio.m4a` without re-encoding.
2. Upload that file to Adobe Podcast Enhanced Speech and download the result.
3. `bun run dev media merge VIDEO ENHANCED_AUDIO` writes `VIDEO_denoised.mp4`, copying the video stream.

Upload subtitles to the video platform separately; embedding them depends on the local ffmpeg build. `bun run dev media join FOLDER` concatenates clips losslessly.
