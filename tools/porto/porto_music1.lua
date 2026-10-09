-- porto/porto_music1 (job 20): EDIT mode. The map music comes back for players who reach Porto by travel or the boat.
-- READ-ONLY scan first (QQ MUS lines: every script that mentions NoMusic); it stops if an enabled script other than
-- TravelServer / BoatServer / PortoActivities / MusicClient sets NoMusic. Then three exact finds in
-- workspace.PortoPassport.PortoActivities (the job 19 text, 8292 chars), compiled before writing;
-- original -> ServerStorage.HudBackup.PortoActivities_pre_music1.
if game:GetService("RunService"):IsRunning() then warn("QQ MUS ABORT - Play mode") return end
local KNOWN = {TravelServer = true, BoatServer = true, PortoActivities = true, MusicClient = true}
local other = 0
for _, root in ipairs({workspace, game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage"), game:GetService("StarterPlayer"), game:GetService("StarterGui")}) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") and d.Source:find("NoMusic", 1, true) then
			local on = not d:IsA("BaseScript") or d.Enabled
			local sets = d.Source:find('"NoMusic", true', 1, true) ~= nil
			print(string.format("QQ MUS %s | %s | enabled=%s sets=%s", d:GetFullName(), d.ClassName, tostring(on), tostring(sets)))
			if on and sets and not KNOWN[d.Name] then other += 1 end
		end
	end
end
if other > 0 then warn("QQ MUS ABORT - another script sets NoMusic (listed above); nothing changed") return end
local PP = workspace:FindFirstChild("PortoPassport")
local s = PP and PP:FindFirstChild("PortoActivities")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ MUS ABORT - missing workspace.PortoPassport.PortoActivities") return end
if #s.Source ~= 8292 then warn(string.format("QQ MUS ABORT - PortoActivities is %d chars, expected 8292 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
-- ---------- the opera duet: a Listen prompt and the aria ----------
]===], [===[
local operaHushed = {}   -- characters the opera has silenced (the music watcher at the end leaves them alone)
-- ---------- the opera duet: a Listen prompt and the aria ----------
]===]}, {[===[
	local hushed = {}
]===], [===[
	local hushed = operaHushed
]===]}, {[===[

print("PortoActivities: ready")]===], [===[

-- ---------- the map music after travel or the boat (Shannon, Oct 9) ----------
-- Travel to Porto and the boat set NoMusic (from before Porto had music) and nothing cleared it, so arrivals heard no
-- music until they respawned. Once a character stands on its own feet in Porto (past the dock line, not seated, not
-- falling) and the opera is not singing to it, the flag goes and MapMusic.MusicClient plays the Porto track again.
local MapMusic = workspace:FindFirstChild("MapMusic")
task.spawn(function()
	while true do
		task.wait(1)
		local portoZ = MapMusic and MapMusic:GetAttribute("PortoZ") or -594
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and char:GetAttribute("NoMusic") and not operaHushed[char] and root.Position.Z < portoZ
				and hum.SeatPart == nil and hum.FloorMaterial ~= Enum.Material.Air then
				char:SetAttribute("NoMusic", nil)
			end
		end
	end
end)

print("PortoActivities: ready")]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a or o:find(p[1], b + 1, true) then warn("QQ MUS ABORT - find " .. i .. " does not match exactly once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ MUS ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PortoActivities_pre_music1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ MUS DONE: PortoActivities %d -> %d chars; backup ServerStorage.HudBackup.PortoActivities_pre_music1", 8292, #s.Source))
