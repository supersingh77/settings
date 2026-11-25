---
refs: data/devices/desktop/state/taskbar.jsonl, data/devices/desktop/device.json
---

# Desktop Start menu pins

> Device: desktop

- The `taskbar` facet captures only pinned taskbar shortcuts (name, target, arguments). The Start menu's pinned list and its order are not captured anywhere.
- `Export-StartLayout` is unreliable in agent sessions; do not use it to back up or verify pins.
- No pin backup is stored in the repository. Re-pin through Start or taskbar settings after a rebuild, then check the order visually.
