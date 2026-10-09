-- porto/seaglass5 (job 41): EDIT mode. Bella's panel moves to the right side of the screen (it covered her and her speech
-- bubble) and hides for six seconds when something is made, so the reveal and her words are seen. Two exact finds in workspace.SeaGlass.SeaGlassClient (13151 chars, after job 39); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5. Output "QQ SG5".
if game:GetService("RunService"):IsRunning() then warn("QQ SG5 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG5 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if #s.Source ~= 13151 then warn(string.format("QQ SG5 ABORT - SeaGlassClient is %d chars, expected 13151 (job 39 not run yet, already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
]===], [===[
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
		panel.Visible = false; task.delay(6, function() if open then panel.Visible = true; refresh() end end)   -- the panel would sit on the reveal and her words (Shannon, VR)
]===]}, {[===[
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
]===], [===[
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(1, 0.5); panel.Position = UDim2.new(1, -14, 0.5, 0)   -- at the right: Bella and her words stay in view (Oct 9)
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG5 ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG5 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG5 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass5"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG5 DONE: SeaGlassClient %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5", #s.Source))
