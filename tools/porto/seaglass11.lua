-- porto/seaglass11 (job 57): EDIT mode. Bella's reveal in VR: in front of your eyes, front and centre. Two exact finds in
-- workspace.SeaGlass.SeaGlassClient (after job 53, about 18492 chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass11. Output "QQ SG11".
if game:GetService("RunService"):IsRunning() then warn("QQ SG11 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG11 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - 18492) > 60 then warn(string.format("QQ SG11 ABORT - SeaGlassClient is %d chars, expected about 18492 (job 53 not run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
local function one(src, find, rep, what)
	local a, b = src:find(find, 1, true)
	if not a then return nil, what .. " not found" end
	if src:find(find, b + 1, true) then return nil, what .. " matches more than once" end
	return src:sub(1, a - 1) .. rep .. src:sub(b + 1)
end
local err
o, err = one(o, [===[
	local look = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
]===], [===[
	if UIS.VREnabled and cam then   -- VR: in front of your eyes, where you look at this moment (Shannon: "front and center, even in VR")
		local okc, rcf = pcall(cam.GetRenderCFrame, cam); rcf = okc and rcf or cam.CFrame
		base = rcf * CFrame.new(0, -0.35, -2.8)
		pcall(m.ScaleTo, m, 1.5)
	end
	local look = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
]===], "the look line"); if not o then warn("QQ SG11 ABORT - " .. err .. " (already patched?); nothing changed") return end
local o2 = one(o, [===[
		local lift = 2.4 * k + 0.15 * math.sin(t * 2.2)
]===], [===[
		local lift = (UIS.VREnabled and 0.45 or 1.8) * k + 0.15 * math.sin(t * 2.2)   -- (in VR it is already at eye level)
]===], "the lift line (2.4)")
if not o2 then o2, err = one(o, [===[
		local lift = 1.8 * k + 0.15 * math.sin(t * 2.2)
]===], [===[
		local lift = (UIS.VREnabled and 0.45 or 1.8) * k + 0.15 * math.sin(t * 2.2)   -- (in VR it is already at eye level)
]===], "the lift line (1.8)") end
if not o2 then warn("QQ SG11 ABORT - " .. err .. "; nothing changed") return end
o = o2
local f, cerr = loadstring(o)
if not f then warn("QQ SG11 ABORT - patched source does not compile: " .. tostring(cerr)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass11"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG11 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass11", before, #s.Source))
