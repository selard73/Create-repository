param([string]$Out, [int]$Left = 216, [int]$Top = 126, [int]$Right = 1456, [int]$Bottom = 594)
# Captures a region of the Roblox Studio window (coordinates in the 1456x819 screenshot frame; default = the whole 3D
# viewport when the Explorer panel is hidden) from whichever monitor holds the Squirrelapalooza Studio window.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class DPIcap2 { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[void][DPIcap2]::SetProcessDPIAware()
$p = Get-Process RobloxStudioBeta | Where-Object { $_.MainWindowTitle -like "*Roblox Studio*" } | Select-Object -First 1
$b = [System.Windows.Forms.Screen]::FromHandle($p.MainWindowHandle).Bounds
$x0 = [int]($b.X + $b.Width * $Left / 1456); $y0 = [int]($b.Y + $b.Height * $Top / 819)
$w = [int]($b.Width * ($Right - $Left) / 1456); $h = [int]($b.Height * ($Bottom - $Top) / 819)
"region $Left,$Top-$Right,$Bottom -> $x0,$y0 ${w}x$h"
$bmp = New-Object System.Drawing.Bitmap $w, $h
[System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($x0, $y0, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"saved $Out ($w x $h)"
