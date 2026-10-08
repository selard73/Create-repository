param([string]$Out)
# Captures the Roblox Studio 3D viewport (the layout used all session: viewport spans 216..1318 x 126..594 of a
# 1456x819 frame) from whichever monitor holds the Squirrelapalooza Studio window, and saves it as a PNG.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class DPIcap { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[void][DPIcap]::SetProcessDPIAware()
$p = Get-Process RobloxStudioBeta | Where-Object { $_.MainWindowTitle -like "Squirrel*" } | Select-Object -First 1
$b = [System.Windows.Forms.Screen]::FromHandle($p.MainWindowHandle).Bounds
$x0 = [int]($b.X + $b.Width * 216 / 1456); $y0 = [int]($b.Y + $b.Height * 126 / 819)
$w = [int]($b.Width * (1318 - 216) / 1456); $h = [int]($b.Height * (594 - 126) / 819)
$bmp = New-Object System.Drawing.Bitmap $w, $h
[System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($x0, $y0, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"saved $Out ($w x $h)"
