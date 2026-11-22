# Workflows

Procedures that involve a person or a web service and so cannot be scripted away.

## UAD-NG: connect a phone

1. Settings → About phone: tap Build number 7 times.
2. Settings → Developer options: enable USB debugging.
3. Connect by USB, set File Transfer (MTP), tap Allow on the phone.
4. Run `laptop uad`. It checks the ADB state through the Toolbox and refuses to start until the device is `ready`; `--force` skips the check.

If ADB cannot open the device, install `android-udev-rules` inside the Toolbox and reload udev on the host. `laptop apps uad-ng` installs or updates the binary.

## Audio denoise

1. `laptop denoise-extract VIDEO` writes `VIDEO_audio.m4a` without re-encoding.
2. Upload it to Adobe Podcast Enhanced Speech and download the result.
3. `laptop denoise-merge VIDEO ENHANCED_AUDIO` writes `VIDEO_denoised.mp4`, copying the video stream.

Upload subtitles to the video platform separately; embedding them in MP4 depends on the local ffmpeg build.
