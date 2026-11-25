---
refs: volume:C:, volume:V:, volume:Z:, display-mode:DISPLAY1, monitor:MSI MAG 255XF, devices/desktop/device.json
---

# Desktop drive, display and controller rules

> Device: desktop

## Drives

- `C:` holds Windows and core apps.
- `V:` holds games and streaming software.
- `Z:` holds recordings, VODs and archives. Recordings never belong on `C:`.

The volumes themselves are observed state; this is the rule about what goes where.

## Display

Keep the main display at 300 Hz. MPRT must stay off: it strobes the backlight and hands brightness control to the monitor, so DDC/CI tools such as Twinkle Tray cannot dim it, and FreeSync/VRR is usually disabled too. The MAG 255XF exposes no MPRT VCP code, so no DDC/CI tool can turn it back off — use the monitor OSD joystick if MPRT is wanted.

## Controllers

- The third-party Xbox 360 wireless receiver can open Task View by itself when its controller is off (phantom Win+Tab). That was a receiver firmware defect, fixed by a firmware update on the same dongle — it is not a Windows setting. If it returns, check the pad firmware in GameSir Connect, or unplug the receiver when not gaming.
- The PXN V10 Pro wheel and the PXN A7 shifter enumerate as two separate HID game controllers. PXN SimRacing reads the wheel, pedals and keymap; bind the shifter per game.
