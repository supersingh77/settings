---
refs: data/devices/desktop/tasks.json, data/devices/desktop/device.json
---

# Desktop software install policy

> Device: desktop

- Prefer winget; use the vendor installer when winget has no usable package. Scoop is the last resort.
- Prefer machine-wide installs. Per-user installs are only for apps that require them: Discord, Twinkle Tray, LocalSend, DeepSeek Harness, T3 Code, Roblox, and MSIX/AppX apps.
- Excluded by request: Razer Synapse, MCHOSE Hub, vJoy.
- Winget on this image: `--scope machine` fails with `0x80070005` (default-scope installs do land in Program Files; PowerShell and Python came from their official all-users installers); `winget source update` fails with "Failed to open the predefined source"; and winget fails with `0x8A150001` inside sandboxed agent sessions — run it from a normal elevated shell.
- Never store secrets such as OBS stream keys in this repository or its state files.
