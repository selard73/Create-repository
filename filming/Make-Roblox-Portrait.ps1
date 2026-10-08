# Make-Roblox-Portrait.ps1 (Oct 8 2026): turns the open Roblox game window into a 9:16 portrait window for TikTok footage.
# The game area (not counting the title bar) becomes exactly 9 wide by 16 tall, as tall as the chosen screen allows,
# centred on it. Then press Win+Alt+R to start and stop recording (Xbox Game Bar saves to Videos\Captures).
#   -Monitor 1 or 2   which screen to put it on (default 1)
param([int]$Monitor = 1)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class RobloxWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
[RobloxWin]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Windows.Forms

$proc = Get-Process -Name RobloxPlayerBeta -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $proc) {
  Write-Host "I can't find the Roblox game window. Open 1001 Squirrels in the Roblox app (not Studio), then run this again."
  exit 1
}
$h = $proc.MainWindowHandle
[RobloxWin]::ShowWindow($h, 9) | Out-Null          # un-maximise / restore, so it can be resized
Start-Sleep -Milliseconds 300

$screens = [System.Windows.Forms.Screen]::AllScreens
$idx = [Math]::Max(1, [Math]::Min($Monitor, $screens.Count)) - 1
$area = $screens[$idx].WorkingArea

$wr = New-Object RobloxWin+RECT
$cr = New-Object RobloxWin+RECT
[RobloxWin]::GetWindowRect($h, [ref]$wr) | Out-Null
[RobloxWin]::GetClientRect($h, [ref]$cr) | Out-Null
$frameW = ($wr.Right - $wr.Left) - $cr.Right       # borders + title bar around the game area
$frameH = ($wr.Bottom - $wr.Top) - $cr.Bottom

$gameH = $area.Height - $frameH
$gameW = [int][Math]::Floor($gameH * 9 / 16)
$gameH = [int][Math]::Floor($gameW * 16 / 9)
if ($gameW % 2) { $gameW -= 1 }                     # even sizes keep video encoders happy
if ($gameH % 2) { $gameH -= 1 }

$x = $area.Left + [int](($area.Width - ($gameW + $frameW)) / 2)
$y = $area.Top
[RobloxWin]::SetWindowPos($h, [IntPtr]::Zero, $x, $y, $gameW + $frameW, $gameH + $frameH, 0x0040) | Out-Null
[RobloxWin]::SetForegroundWindow($h) | Out-Null

Start-Sleep -Milliseconds 300
[RobloxWin]::GetClientRect($h, [ref]$cr) | Out-Null
$w, $hh = $cr.Right, $cr.Bottom
if ([Math]::Abs($w / $hh - 9 / 16) -lt 0.02) {
  Write-Host ("Roblox game area is now {0} x {1} - true 9:16 portrait." -f $w, $hh)
} else {
  # Roblox will not make its window narrower than about 800 px, so on a 1080-tall screen it cannot be a full 9:16 window.
  $cropW = [int][Math]::Floor($hh * 9 / 16)
  Write-Host ("Roblox game area is now {0} x {1}. Roblox won't go narrower than that, so this is not quite 9:16." -f $w, $hh)
  Write-Host ("Record as it is, then crop the middle {0} x {1} (9:16) in CapCut or TikTok's editor - the tours keep the subject in the middle." -f $cropW, $hh)
  Write-Host "For true 1080 x 1920: Settings > System > Display > your 2nd monitor > Display orientation: Portrait, then Roblox full-screen (F11) on it."
}
Write-Host "In the game: F8 opens the filming menu. Win+Alt+R starts / stops recording."
