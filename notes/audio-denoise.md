---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/state/hardware.jsonl
---

# Audio denoise

Denoising is a person-in-the-loop workflow, still provided by the legacy `laptop` command until it is ported:

1. `laptop denoise-extract VIDEO` writes `VIDEO_audio.m4a` without re-encoding.
2. Upload that file to Adobe Podcast Enhanced Speech and download the result.
3. `laptop denoise-merge VIDEO ENHANCED_AUDIO` writes `VIDEO_denoised.mp4`, copying the video stream.

Upload subtitles to the video platform separately; embedding them depends on the local ffmpeg build.
