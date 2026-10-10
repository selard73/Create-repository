-- porto/seaglass12 (job 62): EDIT mode. Bella's reveal in VR a touch smaller and farther off. Two exact finds in
-- workspace.SeaGlass.SeaGlassClient (after job 57, about 18853 chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass12. Output "QQ SG12".
if game:GetService("RunService"):IsRunning() then warn("QQ SG12 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG12 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - 18853) > 60 then warn(string.format("QQ SG12 ABORT - SeaGlassClient is %d chars, expected about 18853 (job 57 not run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
for i, p in ipairs({{[===[
		base = rcf * CFrame.new(0, -0.35, -2.8)
]===], [===[
		base = rcf * CFrame.new(0, -0.3, -3.3)   -- (a little farther off: "slightly smaller please", Oct 10)
]===]}, {[===[
		pcall(m.ScaleTo, m, 1.5)
]===], [===[
		pcall(m.ScaleTo, m, 1.15)
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG12 ABORT - find " .. i .. " not found (already patched?); nothing changed. Source is " .. before .. " chars") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG12 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG12 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass12"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG12 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass12", before, #s.Source))
