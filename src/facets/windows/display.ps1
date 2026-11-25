$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Disp {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
  public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;
    public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
    public int dmFields;
    public int dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
    public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
    public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
  }
  [DllImport("user32.dll", CharSet=CharSet.Unicode)]
  public static extern bool EnumDisplaySettings(string device, int modeNum, ref DEVMODE devMode);
}
'@
$rows = @(foreach ($n in 1..8) {
    $dm = New-Object Disp+DEVMODE
    $dm.dmSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'Disp+DEVMODE')
    if ([Disp]::EnumDisplaySettings("\\.\DISPLAY$n", -1, [ref]$dm)) {
        [pscustomobject]@{
            device = "DISPLAY$n"
            width = $dm.dmPelsWidth
            height = $dm.dmPelsHeight
            hz = $dm.dmDisplayFrequency
            bpp = $dm.dmBitsPerPel
        }
    }
})
ConvertTo-Json -InputObject $rows -Compress
