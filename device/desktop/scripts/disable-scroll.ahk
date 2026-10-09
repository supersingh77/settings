; disable-scroll.ahk
; Blocks mouse wheel up/down events to stop a faulty scroll wheel
; Run it: double-click or `autohotkey disable-scroll.ahk`
; Stop it: Ctrl+Alt+Q, or run enable-scroll.ahk, or right-click tray icon > Exit
; ============================================================================
#Requires AutoHotkey >=2.0

Persistent

; ── Block scroll wheel (including Ctrl+Scroll / Shift+Scroll) ──────────────
*WheelUp::Return
*WheelDown::Return

; ── Notify ──────────────────────────────────────────────────────────────────
TrayTip "Scroll Locked", "Mouse scroll wheel has been disabled.`nCtrl+Alt+Q to re-enable.", 3

; ── Exit hotkey: Ctrl+Alt+Q ────────────────────────────────────────────────
^!q::
{
    ExitApp
}
