-- porto/seaglass5 (job 41): EDIT mode. Bella's panel hides for six seconds when something is made, so the reveal and her
-- words are seen. One exact find in workspace.SeaGlass.SeaGlassClient (13151 chars, after job 39); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5. Output "QQ SG5".
if game:GetService("RunService"):IsRunning() then warn("QQ SG5 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG5 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if #s.Source ~= 13151 then warn(string.format("QQ SG5 ABORT - SeaGlassClient is %d chars, expected 13151 (job 39 not run yet, already patched, or changed); nothing changed", #s.Source)) return end
local a, b = s.Source:find([===[
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
]===], 1, true)
if not a or s.Source:find([===[
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
]===], b + 1, true) then warn("QQ SG5 ABORT - the find does not match exactly once; nothing changed") return end
local o = s.Source:sub(1, a - 1) .. [===[
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
		panel.Visible = false; task.delay(6, function() if open then panel.Visible = true; refresh() end end)   -- the panel would sit on the reveal and her words (Shannon, VR)
]===] .. s.Source:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ SG5 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass5"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG5 DONE: SeaGlassClient %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5", #s.Source))
