# UI Layout — Taskbar & Start Menu

> Device: Desktop PC | Updated: 23 Oct 2026
> Taskbar verified live via UI Automation. Start verified via `Export-StartLayout` (see caveat).

## Taskbar (pinned, left → right)

| # | Pin |
|---|-----|
| 1 | File Explorer |
| 2 | Microsoft Store |
| 3 | Google Chrome |
| 4 | Terminal |
| 5 | DeepSeek Harness |
| 6 | PXN SimRacing |

Windows-managed buttons (Start, Search, Task View) are not included; the UI Automation filter returns only user pins.

## Start Menu (pinned)

| # | Pin |
|---|-----|
| 1 | Settings |
| 2 | File Explorer |

> **Caveat:** on this 26H2 build, `Export-StartLayout` returned only these two entries. Treat the list as the exported state; if more were pinned later, verify in the Start UI. Older 17/19-pin lists are retired.

## Notes

- No pin backup is stored on disk. Re-pin by dragging from Start to the taskbar.
- **File Explorer** is pinned in both places; that overlap is intentional.
- The taskbar is deliberately lean: only one AI app (DeepSeek Harness), plus the sim-racing session tool (PXN SimRacing).
- Discord and Twinkle Tray live on the desktop, not the taskbar.
- PXN SimRacing is session-only; it does not need to be pinned permanently.
