-- porto/seaglass10 (job 53): EDIT mode. Bella's reveal window on every flat screen (desktop too), the panel 30 px in on a
-- desktop. Three exact finds in workspace.SeaGlass.SeaGlassClient (after job 52, about 18296 chars); compiled before
-- writing; original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass10. Output "QQ SG10".
if game:GetService("RunService"):IsRunning() then warn("QQ SG10 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG10 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - 18296) > 60 then warn(string.format("QQ SG10 ABORT - SeaGlassClient is %d chars, expected about 18296 (job 52 not run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
for i, p in ipairs({{[===[
	if phone() then pcall(screenReveal, m:Clone()) end   -- a phone: big and on top; the world one below carries on (and its sound)
]===], [===[
	if not UIS.VREnabled then pcall(screenReveal, m:Clone()) end   -- every flat screen (desktop too - Shannon): big and on top; the world one below carries on (and its sound); VR keeps the world one
]===]}, {[===[
	panel.Position = UDim2.new(1, -14, 0.5, 0)   -- 14 px off the right edge on every screen (Shannon's phone: "zero space")
]===], [===[
	panel.Position = UDim2.new(1, phone() and -14 or -30, 0.5, 0)   -- 14 px off the right edge on a phone ("perfect"), 30 on a desktop ("a little to the left") - Shannon, Oct 9
]===]}, {[===[
	local size = math.floor(math.min(v.Y * 0.64, v.X * 0.42))
]===], [===[
	local size = math.floor(math.min(v.Y * (phone() and 0.64 or 0.5), v.X * 0.42))   -- a phone needs most of its height; a desktop half
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG10 ABORT - find " .. i .. " not found (already patched?); nothing changed. Source is " .. before .. " chars") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG10 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG10 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass10"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG10 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass10", before, #s.Source))
