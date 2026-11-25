---
refs: devices/fedora-laptop/device.json, devices/fedora-laptop/state/hardware.jsonl
---

# Audio denoise

The local denoise is a single `dev media` call on the Windows desktop or Fedora laptop:

1. `bun run dev media denoise VIDEO` copies the video stream and runs ffmpeg `afftdn` on the audio, writing `VIDEO_denoised.mp4`.
2. Listen to a short section before replacing anything; `afftdn` removes hiss but can dull a close voice.

For a stronger cloud cleanup, split the same job into two steps:

1. `bun run dev media extract VIDEO` writes `VIDEO_audio.m4a` without re-encoding.
2. Upload that file for enhancement and download the result.
3. `bun run dev media remux VIDEO ENHANCED_AUDIO` writes `VIDEO_remuxed.mp4`, copying the video stream.

`bun run dev media join FIRST SECOND [OUTPUT]` concatenates two compatible clips losslessly. Upload subtitles to the video platform separately; embedding them depends on the local ffmpeg build.
