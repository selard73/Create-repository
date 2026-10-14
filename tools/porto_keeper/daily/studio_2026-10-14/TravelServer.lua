-- TravelServer: the travel boards beside the spawn daises. Hold the prompt and you are at the other city's dais after a
-- short fade (TravelClient draws it). Porto Nocciola opens the first time a player gets there (Item_porto, awarded here when
-- they are down on the shore or in the pool); travelling back to France lands in the LAST French section they stood in
-- (Item_frenchrank 1/2/3 = forest/village/domaine, kept up to date from the Area attribute SpawnReturn sets). Items are saved
-- by SquirrelSetup through ReplicatedStorage.AwardItems; this script never touches the DataStore.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local ev = F:WaitForChild("TravelEvent")
local award = RS:WaitForChild("AwardItems")
local activity = RS:FindFirstChild("PassportActivity")
local SEA_Y = -52.9
local FRENCH = {forest = 1, village = 2, domaine = 3}
local FRENCH_ID = {"forest", "village", "domaine"}
local NAMES = {porto = "Porto Nocciola", forest = "French Squirrel Country", village = "French Squirrel Country", domaine = "French Squirrel Country"}
local busy = {}

local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local function opened(p) return item(p, "porto") >= 1 end
local function lastFrench(p)
	local a = p:GetAttribute("Area")
	if FRENCH[a] then return a end
	local r = FRENCH_ID[item(p, "frenchrank")]
	if r then return r end
	local s = p:GetAttribute("SavedArea")
	if FRENCH[s] then return s end
	return "forest"
end
local function travel(p, dest)
	if busy[p] then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 then return end
	local id = dest == "porto" and "porto" or lastFrench(p)
	local sp = workspace:FindFirstChild("Spawn_" .. id)
	if not sp then warn("Travel: no Spawn_" .. id); return end
	busy[p] = true
	ev:FireClient(p, "fade", NAMES[id] or id)
	task.wait(0.45)                                              -- the screen is dark before anything moves
	if not (char.Parent and root.Parent and hum.Parent and hum.Health > 0) then busy[p] = nil; return end
	hum.Sit = false
	local target = CFrame.new(sp.Position + Vector3.new(0, 3.5, 0)) * sp.CFrame.Rotation
	pcall(function() p:RequestStreamAroundAsync(target.Position, 3) end)   -- streaming is on: have the other city there first
	root.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(target)
	p:SetAttribute("Area", id)                                   -- SpawnReturn would catch up within 2 s; this keeps the save and the respawn exact
	p.RespawnLocation = sp
	if id == "porto" then char:SetAttribute("NoMusic", true) else char:SetAttribute("NoMusic", nil) end   -- the map music comes back in France
	ev:FireClient(p, "arrived", NAMES[id] or id)
	print(string.format("Travel: %s -> %s", p.Name, id))
	task.delay(1.5, function() busy[p] = nil end)
end
local function hook(pr)
	if not (pr:IsA("ProximityPrompt") and pr.Name == "TravelPrompt") then return end
	pr.Triggered:Connect(function(p)
		local dest = pr:GetAttribute("Dest") or "porto"
		if dest == "porto" and not opened(p) then
			ev:FireClient(p, "note", "Porto Nocciola opens after your first boat trip down the river.")
			return
		end
		travel(p, dest)
	end)
end
for _, d in ipairs(F:GetDescendants()) do hook(d) end
F.DescendantAdded:Connect(hook)

-- bookkeeping from the Area attribute: the last French section, and the first arrival at Porto Nocciola
local function onArea(p)
	local a = p:GetAttribute("Area")
	if p:GetAttribute("SaveLoaded") ~= true then return end     -- items are not in yet; the next change will do
	if FRENCH[a] then
		local have = item(p, "frenchrank")
		if have ~= FRENCH[a] then award:Fire(p, "frenchrank", FRENCH[a] - have) end
	elseif a == "porto" and not opened(p) then
		task.spawn(function()                                    -- when they are actually down (not still under the chute)
			for _ = 1, 60 do
				if p.Parent ~= Players or p:GetAttribute("Area") ~= "porto" or opened(p) then return end
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and not char:FindFirstChild("Parachute") and root.Position.Y < SEA_Y + 12 then
					award:Fire(p, "porto", 1)
					if activity then activity:Fire(p, "porto", {}) end
					print("Travel: " .. p.Name .. " arrived at Porto Nocciola")
					return
				end
				task.wait(1.5)
			end
		end)
	end
end
local function watch(p)
	p:GetAttributeChangedSignal("Area"):Connect(function() onArea(p) end)
	p:GetAttributeChangedSignal("SaveLoaded"):Connect(function() onArea(p) end)
	onArea(p)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("Travel: boards ready (France <-> Porto Nocciola)")
