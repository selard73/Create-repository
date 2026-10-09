-- porto/opera_hush1 (job 19): EDIT mode. Map music silent while the opera singer sings, back 2 s after she stops.
-- One exact find in workspace.PortoPassport.PortoActivities (the job 17 text, 7202 chars); compiled before writing;
-- original -> ServerStorage.HudBackup.PortoActivities_pre_hush1. Output lines start with "QQ HUSH".
if game:GetService("RunService"):IsRunning() then warn("QQ HUSH ABORT - Play mode") return end
local PP = workspace:FindFirstChild("PortoPassport")
local s = PP and PP:FindFirstChild("PortoActivities")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ HUSH ABORT - missing workspace.PortoPassport.PortoActivities") return end
if #s.Source ~= 7202 then warn(string.format("QQ HUSH ABORT - PortoActivities is %d chars, expected 7202 (already patched, or changed); nothing changed", #s.Source)) return end
local OLD, NEW = [===[
	sound.Ended:Connect(function() prompt.ActionText = "Listen"; listeners = {} end)
]===], [===[
	sound.Ended:Connect(function() prompt.ActionText = "Listen"; listeners = {} end)
	-- Shannon, Oct 9: "the background music should go silent when she is singing, then pause for 2 seconds after she
	-- stops, then resume". MusicClient goes silent while the character has NoMusic; hushed[] holds only the ones set here.
	local hushed = {}
	local function release(char) if hushed[char] then hushed[char] = nil; if char.Parent then char:SetAttribute("NoMusic", nil) end end end
	local endedAt
	while true do
		task.wait(0.25)
		if sound.IsPlaying then
			endedAt = nil
			for _, pl in ipairs(Players:GetPlayers()) do
				local char = pl.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - part.Position).Magnitude <= sound.RollOffMaxDistance then
					if not hushed[char] and not char:GetAttribute("NoMusic") then hushed[char] = true; char:SetAttribute("NoMusic", true) end
				elseif char and hushed[char] then release(char) end
			end
		elseif next(hushed) then
			endedAt = endedAt or os.clock()
			if os.clock() - endedAt >= num("OperaMusicPause", 2) then for char in pairs(hushed) do release(char) end end
		end
	end
]===]
local a, b = s.Source:find(OLD, 1, true)
if not a or s.Source:find(OLD, b + 1, true) then warn("QQ HUSH ABORT - the find does not match exactly once; nothing changed") return end
local o = s.Source:sub(1, a - 1) .. NEW .. s.Source:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ HUSH ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PortoActivities_pre_hush1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ HUSH DONE: PortoActivities %d -> %d chars; backup ServerStorage.HudBackup.PortoActivities_pre_hush1", 7202, #s.Source))
