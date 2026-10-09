; disable-autostart.ahk
; Removes disable-scroll.ahk from Windows Startup.
; Run it: double-click once and done.
; ============================================================================
#Requires AutoHotkey >=2.0

startupDir    := A_AppData . "\Microsoft\Windows\Start Menu\Programs\Startup"
shortcutPath  := startupDir . "\disable-scroll.lnk"

if FileExist(shortcutPath) {
    FileDelete(shortcutPath)
    MsgBox "Auto-start removed.`n`ndisable-scroll.ahk will no longer run on login.", "Scroll Lock Auto-Start", 0x40
} else {
    MsgBox "No auto-start entry found — nothing to remove.", "Scroll Lock Auto-Start", 0x40
}
ExitApp
