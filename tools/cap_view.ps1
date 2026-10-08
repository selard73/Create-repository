# cap_view.ps1 -Name <file>: the Studio viewport (Studio on display 2, docked layout) as a PNG in the scratchpad
param([Parameter(Mandatory = $true)][string]$Name)
Add-Type -AssemblyName System.Drawing
$d = "C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\580647d7-7ff4-4cf5-b0fd-5f0547bee56a\scratchpad"
$x0, $y0, $w, $h = 2210, 166, 1628, 490
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($x0, $y0, 0, 0, $bmp.Size)
$bmp.Save("$d\$Name", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"saved $Name"
