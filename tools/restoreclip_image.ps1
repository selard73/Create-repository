# restoreclip_image.ps1 -Path <png>: put one of Shannon's saved clipboard images back on the clipboard (end of a Studio session)
param([Parameter(Mandatory = $true)][string]$Path)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($Path)
[System.Windows.Forms.Clipboard]::SetImage($img)
"restored clipboard image: $Path (" + $img.Width + "x" + $img.Height + ")"
