-- porto/seaglass8 (job 51): EDIT mode. Bella's panel anchored by its right edge in the layout itself (Studio still builds
-- it centre-anchored, so Position (1, -4) hung half of it off a phone screen). One exact find in
-- workspace.SeaGlass.SeaGlassClient (after job 50, about 15822 chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass8. Output "QQ SG8".
if game:GetService("RunService"):IsRunning() then warn("QQ SG8 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG8 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - 15822) > 60 then warn(string.format("QQ SG8 ABORT - SeaGlassClient is %d chars, expected about 15822 (job 50 not run yet, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
if o:find([===[
	panel.AnchorPoint = Vector2.new(1, 0.5)   -- anchored by its right edge (the construction line still said the centre; half of it hung off a phone - Oct 9)
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
]===], 1, true) then warn("QQ SG8 ABORT - already patched; nothing changed") return end
local a, b = o:find([===[
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
]===], 1, true)
if not a then warn("QQ SG8 ABORT - the position line was not found; nothing changed. Source is " .. before .. " chars") return end
if o:find([===[
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
]===], b + 1, true) then warn("QQ SG8 ABORT - the find matches more than once; nothing changed") return end
o = o:sub(1, a - 1) .. [===[
	panel.AnchorPoint = Vector2.new(1, 0.5)   -- anchored by its right edge (the construction line still said the centre; half of it hung off a phone - Oct 9)
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
]===] .. o:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ SG8 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass8"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG8 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass8", before, #s.Source))
