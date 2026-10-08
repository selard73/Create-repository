# setclip.ps1 -Path <file>: put one of my scripts on the clipboard, first keeping a copy of whatever of Shannon's is there
# (text that is not one of my Lua scripts -> shannon_clipboard.txt + a timestamped copy; an image -> a timestamped PNG)
param([Parameter(Mandatory = $true)][string]$Path)
Add-Type -AssemblyName System.Windows.Forms
$d = "C:\Users\slard\roblox-props\tools\clipboard_saves"   # a lasting folder (a chat's scratchpad is temporary)
if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
  $f = "$d\shannon_clipboard_$stamp.png"
  [System.Windows.Forms.Clipboard]::GetImage().Save($f)
  "kept her clipboard image: $f"
} elseif ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
  $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
  $f = "$d\shannon_clipboard_$stamp.files.txt"
  [System.IO.File]::WriteAllLines($f, [string[]]$files)
  "kept her clipboard file list: $f"
} else {
  $t = Get-Clipboard -Raw
  $saved = if (Test-Path "$d\shannon_clipboard.txt") { [System.IO.File]::ReadAllText("$d\shannon_clipboard.txt") } else { "" }
  if ($t -and $t -ne $saved -and -not $t.StartsWith("--")) {
    [System.IO.File]::WriteAllText("$d\shannon_clipboard_$stamp.txt", $t)
    [System.IO.File]::WriteAllText("$d\shannon_clipboard.txt", $t)
    "kept her clipboard text ($($t.Length) chars)"
  }
}
Set-Clipboard -Value ([System.IO.File]::ReadAllText($Path))
"set: " + ((Get-Clipboard -Raw) -split "`n")[0]
