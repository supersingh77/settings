# 01 — DroidCam OBS Plugin

> Status: **Plugin manually installed v2.5.0 ✅** | Winget version didn't work, installed from GitHub directly.

---

## What happened

- `winget` installed the plugin but it didn't appear as a source in OBS
- Uninstalled the winget version, downloaded `DroidCamOBS.Setup.2.5.0.exe` directly from GitHub releases
- Manually ran the installer — confirmed plugin DLL exists at:
  `C:\Program Files\obs-studio\obs-plugins\64bit\droidcam-obs.dll`

## How to use in OBS

1. Open **OBS Studio**
2. In Sources, click **+** → Look for **DroidCam** source type (NOT "Video Capture Device")
3. Enter your phone's IP address or use WiFi discovery
4. Phone must have **DroidCam app** open and connected to same network

## Workaround (already tested successfully)

If the plugin source still doesn't show up, this is what you already did:
- Run **DroidCam Client** (standalone app, v7.2.1 installed)
- It creates a **DroidCam Virtual Camera** output
- In OBS, add a **Video Capture Device** source → select **"DroidCam Virtual Camera"**
- Done! This is a viable long-term setup even without the plugin.

## If plugin still isn't showing

- Make sure OBS is **restarted** after plugin install
- Check OBS → Tools → DroidCam (should appear if plugin loaded)
- Check `%appdata%\obs-studio\plugin_config` for droidcam config
- Reinstall from: https://github.com/dev47apps/droidcam-obs-plugin/releases
