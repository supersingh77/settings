# Windows shell / "Open with" failure — diagnosis and repair path

> Device: desktop | Written: 2026-11-16 | Status: unresolved on this image

## Symptoms

- Double-clicking `.mp4` / `.m4a` in `Videos/` and `.md` in `personal-ledger/diary/` does not open them.
- Right-click → **Open with → Choose another app** does nothing (no dialog ever appears).
- File Explorer has no tabs and looks like a cut-down build.

## Verified evidence

OS reports **26H2, build 26300.9457**, but the shell files are from the 26100 line:

| Component | Version |
|---|---|
| `C:\Windows\explorer.exe` | 10.0.26100.8117 |
| `C:\Windows\System32\OpenWith.exe` | 10.0.26100.8117 |
| `C:\Windows\System32\ShellHost.exe` | 10.0.26100.9278 |
| `twinui.pcshell.dll` | 10.0.26100.9278 |
| `Windows.UI.Xaml.dll` | 10.0.26100.8972 |
| `MicrosoftWindows.Client.CBS` | 1000.26100.360.0 |
| `MicrosoftWindows.Client.Core` | 1000.26100.133.0 |
| `Microsoft.UI.Xaml.CBS` | 9.2603.18001.0 |

**The picker is dead, not slow:**

- `OpenWith.exe` starts and exits **without creating a window** — `0xC0000142` (`STATUS_DLL_INIT_FAILED`) from a low-integrity process, `0x80073D54` from a normal-integrity process.
- `ShellHost.exe` (the dialog host behind it) exits the same way.
- Other GUI binaries (`mstsc.exe`, `mmc.exe`) start normally, so the desktop itself can create windows.

**The shell can still launch associations:**

- A synthetic `.zzz` → `cmd /c echo` association launched successfully through `ShellExecuteEx` (process created, marker file written). So the launch path is intact; the fault is specific to the shell/app-picker components.

**Association state (re-checked 16 Nov 2026, 19:45):**

| Extension | State | Resolves to |
|---|---|---|
| `.md` | no `UserChoice`; `HKCR\.md` → **`Markdown Document`** (repointed 16 Nov) | `GenOffice.exe "%1"` — works |
| `.txt` | `UserChoice` → `AppX4ztfk…` (AppX Notepad), hash present | `Notepad.exe` (packaged) |
| `.mp4` / `.m4a` / `.mkv` and 31 other media types | `UserChoiceLatest` held a **hash but no `ProgId`** → resolved to the dead picker. **Those 34 keys were deleted 16 Nov** | falls back to `HKCR` default, e.g. `PotPlayerMini64.MP4` → `PotPlayerMini64.exe "%1"` |

- `UserChoice` keys are ACL-protected; deleting them fails without elevation.
- **101 extensions still carry a hash-only `UserChoiceLatest`**, but most of those also have a valid `UserChoice` that wins — they are not the cause of the double-click failure.
- `HKCR\txtfile` (the standard Text File class) is missing.
- UCPD (User Choice Protection Driver) is **stopped**; the old `NoInternetOpenWith` policy and the stray `NoOpenWith` value on `OpenWith.exe` are **gone** as of 16 Nov, so they are no longer contributing.
- No shell-hooking tools installed (no StartAllBack / ExplorerPatcher / Open-Shell).

## Root cause

The image mixes **26100-era shell binaries and packages with a 26300 OS build**. The modern Explorer UI (tabs) and the app picker both come from that shell stack, so they fail or fall back to the cut-down behaviour. The association store is a second, smaller problem: hash-only `UserChoiceLatest` entries make Windows treat video types as having no default and hand them to the broken picker.

## Applied 16 Nov 2026

What was actually changed, with the backup that undoes it:

| Change | Effect | Undo |
|---|---|---|
| Deleted the 34 hash-only `UserChoiceLatest` keys (all media types) | Windows falls back to the `HKCR` default handler instead of "no default → picker" | `reg import %LOCALAPPDATA%\DesktopMaintenance\FileExts-backup-2026-11-16.reg` |
| Repointed `HKCR\.md` → `Markdown Document` | `.md` now has a command (GenOffice) instead of a dead ProgId | `reg add "HKCR\.md" /ve /d Markdown /f` (restores the broken state) |
| Added `PotPlayerMini64.*` to `OpenWithProgids` for media types | PotPlayer appears in the "Open with ▸" submenu | delete the value |

**Correction to an earlier claim in this note:** `OpenWithProgids` was reported as empty. That was a **measurement error** — `Get-ChildItem` lists subkeys, not values, so a populated `OpenWithProgids` looked empty. The values were there all along (`WMP11.AssocFile.MP4`, etc.). Read them with `.GetValueNames()`.

**Test-method warning:** launching a file from inside an agent sandbox reports `Server execution failed` / `Access is denied` for **every** type, including ones that work fine by hand. Those errors are the sandbox refusing the shell launch, not the OS. Association behaviour has to be verified by double-clicking as the logged-in user.

## Verified by hand, 16 Nov 2026 (after the association repair)

Tested by double-clicking as the logged-in user — the only reliable method.

| Action | Result |
|---|---|
| Double-click a **video** (`.mp4`/`.mkv`) | ✅ opens (VLC) |
| Right-click → **Open with ▸ PotPlayer** | ✅ works, for video and for audio |
| Right-click → **Play with PotPlayer** (`.m4a`) | ✅ works |
| Right-click → **Open with ▸ GenOffice** (`.md`) | ✅ works |
| Double-click **`.m4a`** | ❌ nothing |
| Double-click **`.md`** | ❌ nothing |
| Right-click → **Open** (the default verb) on `.m4a` | ❌ nothing |
| **Choose another app** (any type) | ❌ nothing — this is the dead picker |

**What that pattern means.** Every *explicit* handler launch works. Only the paths that go through **default-verb resolution** (double-click, right-click → Open) fail, and only for some types. The association *data* is provably equivalent:

| Type | UserChoice | Class → ProgId | Verbs | Outcome |
|---|---|---|---|---|
| `.mp4` | none | `PotPlayerMini64.MP4` | Enqueue, **open**, play | ✅ opens |
| `.mkv` | none | `PotPlayerMini64.MKV` | Enqueue, **open**, play | ✅ opens |
| `.m4a` | none | `PotPlayerMini64.m4a` | Enqueue, **open**, play | ❌ nothing |
| `.md` | none | `Markdown Document` (shell default = `open`) | **open** | ❌ nothing |

Identical structure, identical commands, identical hives — different outcomes. Registry surgery has therefore reached its limit; the difference is in the shell's resolver, not the data.

**Practical path until the image is repaired:**

1. Use **right-click → Open with ▸ \<app\>** — verified working for every type in the table above.
2. Try setting the default explicitly in **Settings → Apps → Default apps → choose PotPlayer → `.m4a`** (and GenOffice for `.md`). *Viewing* the page is not the same as clicking **Set default** — the click writes a real `UserChoice` with its valid hash, which takes priority over the broken fallback path. This is the one thing that could restore double-click without reinstalling.

## The build number is NOT the problem (corrected 16 Nov 2026)

An earlier revision of this note blamed a "26100 shell on a 26300 OS". **That was wrong**, and the install media proves it. The original ISO is still on disk (`Z:\Downloads\Windows11_Client_x64_en-us_26300_9457.iso`), and mounting its `install.wim` shows the media ships *exactly* what is installed:

| File | In the ISO's install.wim | Installed |
|---|---|---|
| `explorer.exe` | 10.0.26100.8117 | 10.0.26100.8117 ✅ |
| `ShellHost.exe` | 10.0.26100.9278 | 10.0.26100.9278 ✅ |
| `twinui.pcshell.dll` | 10.0.26100.9278 | 10.0.26100.9278 ✅ |
| `shell32.dll` | 10.0.26100.9278 | 10.0.26100.9278 ✅ |
| `ntoskrnl.exe` | 10.0.26100.9457 | 10.0.26100.9457 ✅ |

DISM reports the image itself as `Version: 10.0.26300, ServicePack Build: 9457`. So this is an **enablement-style release**: the OS reports 26300 while its binaries stay on the 26100 servicing line, at UBR 9457. Version numbers like `26100.8117` are therefore normal here — ReviOS replaced nothing, and there is no malicious or accidental file mix.

What that also means: **a repair install from this same ISO would restore exactly the binaries you already have.** It is not a magic fix for the shell behaviour, and it would not add tabs if this media doesn't provide them.

### So what is actually broken

With the media ruled out, the remaining fault is runtime state, not files:

- `ShellHost.exe` (the dialog host behind "Choose another app") exits with **`0xC0000142`** at DLL init, despite being the shipped binary.
- `OpenWith.exe` starts and exits without creating a window.
- Every shell package it depends on **is present**: `MicrosoftWindows.Client.CBS 1000.26100.360.0`, `Microsoft.Windows.Client.Core 1000.26100.133.0`, `Microsoft.UI.Xaml.CBS 9.2603.18001.0`, `ShellExperienceHost 10.0.26100.8115`, `StartMenuExperienceHost 10.0.26100.4768`. No packages are missing; none are provisioned offline, so they cannot be reinstalled from an image.

**Repair attempted 16 Nov 2026:** all five shell packages were re-registered (`Add-AppxPackage -DisableDevelopmentMode -Register …AppXManifest.xml`) — all reported OK. That is the standard fix for a shell whose registrations have gone stale, and it costs nothing to try.

**Result 17 Nov 2026, after a reboot: it did not help.** `.m4a` double-click still does nothing. Also confirmed afterwards that `.m4a` and `.md` still have **no `UserChoice` key at all** (`ProgId` empty, no hash) — so the Settings → Default apps route has *not* actually been exercised yet. Viewing that page is not the same as clicking **Set default**.

If the picker still fails after a reboot, the honest options are:

1. `sfc /scannow` then `DISM /Online /Cleanup-Image /RestoreHealth` — free, low odds.
2. **Repair install from the ISO on `Z:`** — keeps files and apps, but as shown above expect the *same* shell versions afterwards. Worth doing only if you also want the ReviOS tweaks reverted.
3. **Clean install from that same ISO**, then check whether the picker works *before* applying the ReviOS playbook. That is the only way to tell whether the media or the playbook is responsible. ReviOS Playbook 26.10 (`Revi-PB-26.10.apbx`) was applied to this machine; the archive is password-protected, so its changes could not be inspected.

## What does not fix it

- Re-registering the CBS packages as the current user — tried, no change to the picker.
- Deleting or repointing `UserChoice` by hand — Windows rewrites the keys, and doing it live can briefly make **every** extension resolve to `OpenWith.exe`.
- Installing another text editor — does not touch Explorer or the picker.

## Repair path

1. Optional, cheap first attempt (elevated): `sfc /scannow` then `DISM /Online /Cleanup-Image /RestoreHealth`. Low odds on a modified image.
2. **In-place repair install** with matching 26300 media — keeps files and apps.
3. Clean install if the repair install fails.
4. Until then: open files from inside the app (`File → Open`) rather than by double-click.

## Refactor — how this should be handled in this repo

- **One read-only diagnostic script**, not a fix-all script: report OS/build, shell file versions, package versions, a picker launch test, and the `AssocQueryString` table for the affected extensions. No writes, no elevation needed.
- **Keep the decision tree in a note** (this file). If the picker exits with `0xC0000142`/`0x80073D54` and the shell binaries are older than the OS build, it is an image problem — stop, do not patch the registry.
- **Never write associations by hand.** Use the OS UI or the documented API; hand-editing `UserChoice` is protected, self-healing, and can make things worse.
- **Scripts stay small, idempotent, and log to `%LOCALAPPDATA%\DesktopMaintenance`** — same pattern as `update-system.ps1` / `cleanup-system.ps1`.

## Loose ends

- **Notepad++ 8.9.9.1 — resolved 16 Nov 2026.** It was installed only during this troubleshooting and removed with `winget uninstall --id Notepad++.Notepad++ --exact` from an elevated shell (the MSI uninstall returns 1603 without elevation, which is why it sat there).
- **Obsidian 1.15.1 — installed and removed 16 Nov 2026** (same day, to test `.md` handling). Its uninstaller left the `.md` mapping worse: `HKCR\.md` still points at the `Markdown` ProgId, but that ProgId's `shell\open\command` is now empty, and there is no `UserChoice`. Double-clicking a `.md` therefore does nothing. Stale `HKCR\Obsidian` and `HKCR\obsidian` keys also remain.
  - Do **not** fix this by hand-writing `UserChoice` (see the rule above). It can be set from **Settings → Apps → Default apps → `.md`** once the picker is repaired, or GenOffice can be used explicitly.
- A `.reg` snapshot of `HKCU\…\FileExts` lives in `%LOCALAPPDATA%\DesktopMaintenance`; `reg import` refuses the protected keys, so it is a reference only.
- `.txt` was restored to its original handling; `.mp4` / `.m4a` remain unresolved exactly as before.
