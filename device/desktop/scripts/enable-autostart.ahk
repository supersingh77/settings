; enable-autostart.ahk
; Adds disable-scroll.ahk to Windows Startup so it runs automatically on login.
; Run it: double-click once and done.
; Undo: double-click disable-autostart.ahk
; ============================================================================
#Requires AutoHotkey >=2.0

startupDir    := A_AppData . "\Microsoft\Windows\Start Menu\Programs\Startup"
scriptPath    := A_ScriptDir . "\disable-scroll.ahk"
shortcutPath  := startupDir . "\disable-scroll.lnk"

; ── Create shortcut in Startup folder ───────────────────────────────────────
Shell      := ComObject("WScript.Shell")
Shortcut   := Shell.CreateShortcut(shortcutPath)
Shortcut.TargetPath      := scriptPath
Shortcut.WorkingDirectory := A_ScriptDir
Shortcut.Description     := "Blocks faulty Logitech scroll wheel"
Shortcut.Save()

MsgBox "Auto-start enabled!`n`ndisable-scroll.ahk will now run every time you log in.`n`nTo undo, run disable-autostart.ahk", "Scroll Lock Auto-Start", 0x40
ExitApp
