---
refs: data/devices/desktop/tasks.json, volume:Z:, steam-lib:V:\Games\SteamLibrary, steam-lib:Z:\Games\SteamLibrary, reg:PXN SimRacing
---

# Desktop known traps

> Device: desktop

## Folders that look like installs but are not

- `C:\Program Files\DroidCam` — empty; left over from the retired phone-as-webcam route (the webcam is now the Kreo Owl Lite).
- `C:\tools\php84` — a config/log stub with no PHP install behind it.
- `C:\AMD\Chipset_Software` — AMD installer staging (config/log only); the real package is the "AMD Chipset Software" app entry.

Do not infer an install from a folder name. The old audit measured folder contents to tell an empty leftover from a stub; that check is gone, so this list is the human replacement.

## Recordings belong on Z:

Recordings, VODs and archives go to `Z:\Recordings`. Files under `%USERPROFILE%\Videos` are out of policy; the cleanup task reports them so they can be moved, and never deletes them.

## Version fields disagree

PXN SimRacing's app reports a newer version than its uninstall entry; trust the app, not the registry entry. Its bundled vJoy driver is not installed (vJoy is excluded by request).

## Steam library on Z: is not registered

`Z:\Games\SteamLibrary` holds manifests but is not registered in Steam's library folders, so Steam does not list those games until the folder is added. `V:` is the registered library.
