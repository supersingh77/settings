; enable-scroll.ahk
; Stops the disable-scroll script by closing its hidden window.
; Run it: double-click or `autohotkey enable-scroll.ahk`
; ============================================================================
#Requires AutoHotkey >=2.0

DetectHiddenWindows True

WinClose "disable-scroll.ahk ahk_class AutoHotkey"

TrayTip "Scroll Unlocked", "Mouse scroll wheel has been re-enabled.", 2

ExitApp
