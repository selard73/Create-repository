# studio_front.ps1: bring Roblox Studio's main window to the front (call as the LAST action of a PowerShell step).
# Uses the Alt-key + AttachThreadInput trick so Windows' foreground lock does not refuse the switch.
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
}
"@
$p = Get-Process RobloxStudioBeta -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
$h = $p.MainWindowHandle
[W]::ShowWindow($h, 9) | Out-Null
$fg = [W]::GetForegroundWindow()
$fgThread = [W]::GetWindowThreadProcessId($fg, [IntPtr]::Zero)
$me = [W]::GetCurrentThreadId()
[W]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [W]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)   # tap Alt
[W]::AttachThreadInput($me, $fgThread, $true) | Out-Null
[W]::BringWindowToTop($h) | Out-Null
[W]::SetForegroundWindow($h) | Out-Null
[W]::AttachThreadInput($me, $fgThread, $false) | Out-Null
Start-Sleep -Milliseconds 300
$now = [W]::GetForegroundWindow()
"front: " + $p.MainWindowTitle + " (foreground is Studio: " + ($now -eq $h) + ")"
