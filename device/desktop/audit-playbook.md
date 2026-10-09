# Desktop Audit Playbook

> Device: desktop | Added: 09 Oct 2026
> Read this before editing `startmenu-taskbar.md`, `software.md`, or `disk-cleanup.md`.
> Everything here was verified live on Win11 23H2 (build 22631). Commands are PowerShell 7.

---

## 1. Taskbar pins — names and order

```powershell
$tb = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
[Text.Encoding]::UTF8.GetString($tb.Favorites)   # .lnk names appear in pin order
```

- **Gotcha:** the `Favorites` blob is **UTF-8 / single-byte**, not UTF-16. Decoding as Unicode gives mojibake.
- The `.lnk` files in `%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\` are the same set but **alphabetical** — they do not give order.
- Windows-managed pins (Search, Task View) are not in this list.

## 2. Start menu pins — names and order

```powershell
Export-StartLayout -Path "$env:TEMP\start.json"
Get-Content "$env:TEMP\start.json" -Raw    # pinnedList[] is already in order
```

- Entries are `packagedAppId` (Store) or `desktopAppLink` (file path).
- **Dead ends, don't retry:** `...\StartMenuExperienceHost_...\LocalState\start2.bin` is compressed; the CloudStore `tilegrid` keys are absent or opaque.

## 3. Installed apps

```powershell
winget list
```

- Authoritative for winget and MSIX apps. Duplicates appear as separate rows (e.g. Clockify 2.3.3 **and** 2.3.4).
- **Blind spots:** Game Pass and Battle.net titles do not appear.
- Convention: system/driver components (VC++ runtimes, .NET, chipset, Realtek, Xbox services) are left out of `software.md`.

## 4. "Is it really installed?" — before trusting a doc row

```powershell
Test-Path 'C:\Program Files\<App>'
Get-ChildItem 'C:\Program Files\<App>' -Recurse -File | Measure-Object Length -Sum
```

- **Empty folder / 0 files** → app was uninstalled and left litter. Move the row to `software.md` → "Previously Installed (Removed)".
- A folder holding only a stray log (e.g. `logs\ktane.log`, 552 KB) counts as **not installed**.

## 5. Games — check *every* Steam library

```powershell
Get-Content 'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf'   # all "path" roots
```

- There are **two** libraries here: `V:\Games\SteamLibrary` and `Z:\Games\SteamLibrary`. Checking one alone gives wrong answers.
- Per library, `steamapps\appmanifest_*.acf` holds `"appid"` and `"name"`. A folder under `common\` with no appmanifest is a leftover.
- Repack/installer folders (e.g. FitGirl) are **not** installs even when a `setup.exe` is present.

## 6. Doc conventions

| Doc | Holds |
|-----|-------|
| `startmenu-taskbar.md` | Pin lists only, in true order |
| `software.md` | Installed apps; `⚠` marks duplicates; removals go to "Previously Installed (Removed)" |
| `disk-cleanup.md` | §6 = sized app-removal candidates; §5 = drive free-space map |

Rules: bump the `Updated:` date · verify live, never recall · mark anything unverified · tables over prose · cut historical waffle.
