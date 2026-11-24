---
refs:
---

# Windows shell: no default verb, and the app picker never opens

> Device: desktop | Verified 16-17 Nov 2026 | Status: unresolved on this image

## What is broken

| Action | Result |
|---|---|
| Double-click `.mp4` / `.mkv` | opens (PotPlayer) |
| Double-click `.m4a` | nothing |
| Double-click `.md` | nothing |
| Right-click → **Open** (the default verb), `.m4a` / `.md` | nothing |
| Right-click → **Open with ▸ \<app\>** | works for every type |
| **Choose another app**, any type | no dialog ever appears |
| File Explorer | no tabs |

Every *explicit* handler launch works. Only **default-verb resolution** fails, and only for some types.

## The picker is dead, not slow

`OpenWith.exe` and `ShellHost.exe` start and exit **without creating a window**: `0xC0000142` (`STATUS_DLL_INIT_FAILED`) from a low-integrity process, `0x80073D54` from a normal-integrity one. `mstsc.exe` and `mmc.exe` open normally, so the desktop itself can create windows. A synthetic `.zzz` association launched `cmd` through `ShellExecuteEx`, so the launch path is intact.

## Version numbers are not the cause

The OS reports **26300.9457** while the shell binaries are on the 26100 servicing line. That is the shipped configuration, not file damage: the original ISO's `install.wim` contains exactly what is installed, and DISM reports the image itself as 26300 / build 9457. This is an enablement-style release, so `26100.x` file versions are normal here.

| File | In the ISO | Installed |
|---|---|---|
| `explorer.exe` | 10.0.26100.8117 | 10.0.26100.8117 |
| `OpenWith.exe` | 10.0.26100.8117 | 10.0.26100.8117 |
| `ShellHost.exe`, `twinui.pcshell.dll` | 10.0.26100.9278 | 10.0.26100.9278 |
| `shell32.dll` | 10.0.26100.9278 | 10.0.26100.9278 |
| `ntoskrnl.exe` | 10.0.26100.9457 | 10.0.26100.9457 |

Every shell package the picker depends on is present — `MicrosoftWindows.Client.CBS 1000.26100.360.0`, `Microsoft.Windows.Client.Core 1000.26100.133.0`, `Microsoft.UI.Xaml.CBS 9.2603.18001.0`, `ShellExperienceHost 10.0.26100.8115`, `StartMenuExperienceHost 10.0.26100.4768` — and none is provisioned offline. Re-registering all five changed nothing, so the fault is runtime state, not a missing or stale registration.

## The association data is equivalent, so the resolver is at fault

Measured 17 Nov 2026. None of these carries a `UserChoice`, so each falls back to its class default:

| Type | Class → command | Outcome |
|---|---|---|
| `.mp4` | `PotPlayerMini64.MP4` → quoted PotPlayer | opens |
| `.mkv` | `PotPlayerMini64.MKV` → quoted PotPlayer | opens |
| `.m4a` | `PotPlayerMini64.m4a` → quoted PotPlayer | nothing |
| `.md` | `MarkdownText` → quoted `notepad.exe` ([why notepad](../device/desktop/declared/associations.json)) | nothing |

Identical structure, identical quoting, different outcomes. Registry surgery has reached its limit here.

## What not to do

- **Do not write `UserChoice` by hand.** It is ACL-protected, Windows rewrites it, and a wrong value can make every extension resolve to the dead picker.
- **Do not click "Reset all default apps".** It writes a `UserChoice` for 19 media types pointing at `AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs` — a third-party package hash that is neither installed nor provisioned — which turns a partial failure into a total one. Recovery: delete the whole `FileExts\<ext>` key (deleting `UserChoice` alone is denied), then restore `OpenWithList` with `a = <exe>` and `MRUList = a`, because deleting the parent takes the MRU with it and "Open with ▸" then has nothing to show.
- **Do not trust a sandboxed launch.** An agent session reports `Server execution failed` / `Access is denied` for every type, including ones that work by hand. Association behaviour can only be verified by double-clicking as the logged-in user.
- **Do not compare two handlers by eye.** Compare the command text byte for byte and confirm `HKCR\Applications\<exe>` exists. Both have been the real difference during this investigation.

## Repair path

1. `sfc /scannow`, then `DISM /Online /Cleanup-Image /RestoreHealth` — not yet run on this image.
2. Repair install from `Z:\Downloads\Windows11_Client_x64_en-us_26300_9457.iso` — expected to change nothing, since it replaces binaries with the ones already installed.
3. Clean install from that ISO, then ReviOS Playbook 26.10 — the only configuration never tried here. The playbook archive (`Revi-PB-26.10.apbx`) is password-protected, so its changes cannot be inspected.

Until one of those lands: right-click → **Open with ▸ \<app\>**, and set a default from **Settings → Apps → Default apps**. That UI is the only sanctioned writer of `UserChoice`, and it writes a valid hash, which is the one thing that could restore double-click without reinstalling anything.
