# Desktop software

## Detected software

> Generated from live desktop readings by `update-inventory.ps1`. Run it with `-Apply` to refresh this section.
> Sources: uninstall and per-user package registries plus executable targets in `declared/audit-targets.json`. Portable apps outside those targets are not included.

### Registry applications

| Application | Version |
|---|---|
| **7-Zip 26.06 (x64)** | 26.06 |
| **ActivityWatch** | 0.14.3 |
| **AMD Chipset Software** | 8.09.28.1124 |
| **AMD Software** | 26.11.2 |
| **ExitLag version 5.23.3** | 5.23.3 |
| **Focusrite Audio Drivers 4.150.0.432** | 4.150.0.432 |
| **Focusrite Control 2 1.1210.0.0** | 1.1210.0.0 |
| **GameSir Connect 1.17.4** | 1.17.4 |
| **GenOffice 0.13.615** | 0.13.615 |
| **Git** | 2.56.0.4 |
| **Google Chrome** | 157.0.8103.79 |
| **GTA San Andreas** | 1.00.00001 |
| **HWiNFO® 64** | 8.54 |
| **Microsoft Edge WebView2 Runtime** | 158.0.4370.33 |
| **Microsoft Visual C++ 2012 Redistributable (x64) - 11.0.61030** | 11.0.61030.0 |
| **Microsoft Visual C++ 2012 Redistributable (x86) - 11.0.61030** | 11.0.61030.0 |
| **Microsoft Visual C++ 2013 Redistributable (x64) - 12.0.40664** | 12.0.40664.0 |
| **Microsoft Visual C++ 2013 Redistributable (x86) - 12.0.40664** | 12.0.40664.0 |
| **Microsoft Visual C++ v14 Redistributable (x64) - 14.52.37029** | 14.52.37029.0 |
| **Microsoft Visual C++ v14 Redistributable (x86) - 14.52.37029** | 14.52.37029.0 |
| **Microsoft Windows Application Compatibility Fix Database** | unreported |
| **Microsoft Windows Desktop Runtime - 8.0.34 (x64)** | 8.0.34.36622 |
| **Mozilla Firefox (x64 en-US)** | 160.0.1 |
| **Mozilla Maintenance Service** | 158.0.1 |
| **OBS Studio** | 33.0.1 |
| **PotPlayer-64 bit** | 26.10.21.0 |
| **PXN SimRacing** | 1.2.0.0 |
| **Realtek Audio Driver** | 6.0.9231.1 |
| **Realtek Ethernet Controller Driver** | 10.50.511.2021 |
| **Revision Tool version 2.15.1** | 2.15.1 |
| **Riot Vanguard** | unreported |
| **Steam** | 2.10.91.91 |
| **TP-Link UB500 Bluetooth 5.3 Driver** | 1051.1038.1040.230912 |
| **VLC media player** | 3.0.24 |

### Additional applications

| Application | Version | Location |
|---|---|---|
| **FFmpeg** | 9.0.2-full_build-www.gyan.dev | C:\Program Files\FFmpeg\bin\ffmpeg.exe |

### Packaged applications

| Application | Version |
|---|---|
| **Microsoft.WindowsTerminal** | 1.25.3131.0 |
| **com.notion.app.desktop.notion** | 7.44.0.0 |

### Steam libraries

```text
| registered | C:\Program Files (x86)\Steam | 1 apps |
| registered | V:\Games\SteamLibrary | 6 apps |
| on disk | V:\Games\SteamLibrary | 6 manifests | registered: True |
| on disk | Z:\Games\SteamLibrary | 2 manifests | registered: False |
```

### Folders that are not installed apps

```text
| C:\Program Files\DroidCam | 0 files | 0.00 MB | EMPTY - not an install |
| C:\tools\php84 | 1 files | 0.07 MB | STUB - config/log only, not an install |
| C:\AMD\Chipset_Software | 1 files | 0.00 MB | STUB - config/log only, not an install |

⚠ 0.00 GB of recordings sit in C:\Users\amar\Videos - out of policy, they belong on Z:\Recordings.
| OBS profile 'Untitled' | records to Z:\Recordings | ok |
```

## Install policy

- Prefer winget, then the vendor installer when winget has no usable package. Use Scoop only as a last resort.
- Prefer machine-wide installs. Per-user installs are reserved for applications that require them, including Discord, Twinkle Tray, LocalSend, DeepSeek Harness, T3 Code, Roblox, and MSIX/AppX applications.
- Excluded by request: Razer Synapse, MCHOSE Hub, and vJoy.
- Remove a machine-wide package from an elevated shell with `winget uninstall --id <id> --exact`.

## Setup notes

- OBS recording and audio choices are declared in [`declared/obs.json`](declared/obs.json); keep stream keys out of the repository.
- PXN SimRacing reports app version 1.6.8.0; its uninstall entry reports 1.2.0.0. Its bundled vJoy driver is not installed.
- `winget install --scope machine` fails with `0x80070005` on this Windows image. Default-scope installs landed in Program Files; PowerShell and Python were installed with their official all-users installers.
- `winget source update` resolves `Failed to open the predefined source`.
- winget fails with `0x8A150001` inside sandboxed agent sessions. Run it from a normal elevated shell.
