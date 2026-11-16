# UI Layout — Taskbar & Start Menu

> Device: Desktop PC | Updated: 16 Nov 2026
> Taskbar reconstructed from the `Taskband\Favorites` blob (byte offsets give true left→right order) plus `%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar`.
> UI Automation returns nothing inside an agent session, and `Export-StartLayout` fails with `0x80070490` — verify visually when you can.

## Taskbar (pinned, left → right)

| # | Pin | Kind |
|---|-----|------|
| 1 | File Explorer | desktop app |
| 2 | Microsoft Store | packaged (`Microsoft.WindowsStore_8wekyb3d8bbwe!App`) |
| 3 | Google Chrome | desktop app |
| 4 | Terminal | packaged (`Microsoft.WindowsTerminal_8wekyb3d8bbwe!App`, 1.24.11911.0) |
| 5 | DeepSeek Harness | desktop app |
| 6 | GenOffice | desktop app |
| 7 | T3 Code (Beta) | desktop app |
| 8 | Bootstraps Notion Desktop Installer | ⚠️ **installer stub — junk**, pinned by the Notion installer on 16 Nov |
| 9 | Notion | packaged (`com.notion.app.desktop.notion`) |

Windows-managed buttons (Start, Search, Task View) and tray items are not pins and are not in this list.

- **PXN SimRacing is no longer pinned** (it was #6 in the 23 Oct list). Its pin file is gone from `User Pinned\TaskBar`.
- **Obsidian was pinned until 16 Nov**; uninstalling the app removed its `Obsidian (2).lnk` pin automatically.
- **To do:** unpin #8 — right-click → Unpin from taskbar. Notion itself is #9, so the stub adds nothing.

## Start Menu (pinned)

| # | Pin |
|---|-----|
| 1 | Settings |
| 2 | File Explorer |

> **Caveat:** on this 26H2 build, `Export-StartLayout` returns only these two entries — and in an agent session it fails outright. Treat the list as the last exported state (23 Oct 2026); if the Start UI shows more pins, the export is incomplete and the UI wins. Older 17/19-pin lists are retired.

## Notes

- No pin backup is stored on disk. Re-pin by dragging from Start to the taskbar.
- **File Explorer** is pinned in both places; that overlap is intentional.
- The taskbar is no longer "deliberately lean": it grew from 6 to 9 pins during the Oct–Nov installs (GenOffice, T3 Code, Notion). Prune it if it starts to feel cluttered.
- Discord and Twinkle Tray live on the desktop / public desktop, not the taskbar.
- To audit pins without a GUI: the `User Pinned\TaskBar` folder gives the **set**, and the `Taskband\Favorites` blob gives the **order** — see [audit-playbook.md](audit-playbook.md) §1.
