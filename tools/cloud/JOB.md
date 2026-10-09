# Job 6: camera VR aim patch (Studio EDIT: one script's Source; ask Shannon first)

Shannon: "you can't really aim the shot with the golden circle" in VR. The gold ring followed the avatar's animated hand,
not the controller. This patch makes the aim the tracked controller itself (gold beam + ring), fills the ring in only
when the shutter would accept the shot, keeps photos level, and makes the ring and markers survive a respawn.
Desktop and phone are untouched.

1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/camera/vraim_patch.lua
   It patches workspace.PhotoGame.CameraClient.Source with six exact-string replacements. It refuses to run unless the
   Source is exactly the Oct 8 v3 text (56602 chars) and every find matches once; it compiles the result before
   writing; the original goes to ServerStorage.HudBackup.CameraClient_v3_pre_vraim.
   The patched script, for reference (byte-identical to what the patch produces):
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/italy/camera/CameraClient_v3.lua
2. Tell Shannon what it changes and wait for her yes.
3. Run it in Studio, Edit mode, with execute_luau, as is.
4. Send ONE message to the cloud session "GitHub free credit eligibility" with every Output line starting with
   `QQ VRA` (one line on success; an ABORT line otherwise). If it errors, send the error text.
5. Do not publish; Shannon does (Alt+P). Do not play-test unless she asks.

Undo, if wanted: replace CameraClient.Source with the Source of ServerStorage.HudBackup.CameraClient_v3_pre_vraim.

(Job 7, the town-wide floor cut, comes after this: its script is still under review and needs Shannon's yes on the plan.)
