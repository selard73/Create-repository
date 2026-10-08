# cap_seq.ps1: grab the Studio viewport (display 2) every Interval seconds, Count times -> <Prefix>NN.png in the scratchpad
param([int]$Count = 40, [double]$Interval = 1.5, [string]$Prefix = "seq_")
Add-Type -AssemblyName System.Drawing
$d = "C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\580647d7-7ff4-4cf5-b0fd-5f0547bee56a\scratchpad"
$x0, $y0, $w, $h = 2210, 166, 1628, 490
for ($i = 0; $i -lt $Count; $i++) {
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($x0, $y0, 0, 0, $bmp.Size)
  $bmp.Save(("{0}\{1}{2:D2}.png" -f $d, $Prefix, $i), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Start-Sleep -Milliseconds ([int]($Interval * 1000))
}
"done $Count frames"
