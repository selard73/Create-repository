local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent

local template = ServerStorage:WaitForChild("AcornTemplate")
local spots = workspace:WaitForChild("AcornSpots")
local picked = RS:WaitForChild("AcornPicked")
local award = RS:WaitForChild("AwardAcorns")
local REST = template:GetAttribute("Rest") or 0.3

local live = Instance.new("Folder")                    -- run-time only; never saved into the place
live.Name = "Acorns"
live.Parent = workspace

-- every spot, grouped by section, so a collected acorn comes back in the same part of the map and the three
-- sections do not slowly drain into one
local bySection, free, holder = {}, {}, {}
for _, at in ipairs(spots:GetChildren()) do
	if at:IsA("Attachment") then
		local s = at:GetAttribute("Section") or "forest"
		bySection[s] = bySection[s] or {}
		table.insert(bySection[s], at)
	end
end
for s, list in pairs(bySection) do
	free[s] = {}
	for _, at in ipairs(list) do free[s][at] = true end
end

local rng = Random.new()
local function takeFreeSpot(section, avoid)
	local pool = {}
	for at in pairs(free[section] or {}) do
		if at ~= avoid then table.insert(pool, at) end
	end
	if #pool == 0 then return nil end
	return pool[rng:NextInteger(1, #pool)]
end

local function lieAt(model, surface, yaw)
	-- the same placement the preview uses: on its side, turned a different way each time, belly on the surface.
	-- The tilt goes in the PivotTo rather than the parts, because PivotTo would otherwise cancel it out.
	model:PivotTo(CFrame.new(surface + Vector3.new(0, REST, 0))
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(math.rad(90), 0, 0))
end

local spawnAt
local function collect(model, at, section, player)
	-- one collector only. Touched fires many times as a character brushes past, and two limbs can arrive in the
	-- same instant, so the flag is set BEFORE anything else happens.
 local char=player and player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 or not player:GetAttribute("SaveLoaded") or (root.Position-model:GetPivot().Position).Magnitude>(F:GetAttribute("ClickDistance") or 28) then return end
	if model:GetAttribute("Taken") then return end
	model:SetAttribute("Taken", true)

	local value = F:GetAttribute("Value") or 1
	player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + value)
	award:Fire(player, value)                          -- SquirrelSetup owns the saving
	picked:FireClient(player, player:GetAttribute("Acorns"), model:GetPivot().Position)

	model:Destroy()
	free[section][at] = true
	holder[at] = nil

	local wait = F:GetAttribute("Respawn") or 300
	task.delay(wait, function()
		-- somewhere ELSE, which is the whole point: the map is never the same twice
		local spot = takeFreeSpot(section, at)
		if spot then spawnAt(spot, section) end
	end)
end

function spawnAt(at, section)
	if holder[at] then return end
	local m = template:Clone()
	m.Name = "Acorn"
	lieAt(m, at.Position, rng:NextNumber(0, math.pi * 2))
	m.Parent = live
	free[section][at] = nil
	holder[at] = m

 local hit = m:FindFirstChild("Hit") or m.PrimaryPart
 hit.CanTouch=true;hit.CanQuery=true
 local click=Instance.new("ClickDetector");click.MaxActivationDistance=F:GetAttribute("ClickDistance") or 28;click.Parent=hit
 click.MouseClick:Connect(function(player) collect(m,at,section,player) end)
	hit.Touched:Connect(function(other)
		local char = other and other:FindFirstAncestorOfClass("Model")
		local player = char and Players:GetPlayerFromCharacter(char)
		if player then collect(m, at, section, player) end
	end)
	return m
end

-- fill the map
local density = F:GetAttribute("Density") or 0.33
local planted = {}
for section, list in pairs(bySection) do
	local want = math.max(1, math.floor(#list * density + 0.5))
	local n = 0
	while n < want do
		local spot = takeFreeSpot(section)
		if not spot then break end
		spawnAt(spot, section)
		n += 1
	end
	planted[section] = n
end
print(string.format("AcornServer: %d in the forest, %d in the Rue, %d at the Chateau (%.0f%% of %d hiding places); back after %ds",
	planted.forest or 0, planted.village or 0, planted.domaine or 0, density * 100,
	#spots:GetChildren(), F:GetAttribute("Respawn") or 300))

-- a player who has never played still needs the attribute to exist, so the counter has something to read
Players.PlayerAdded:Connect(function(p)
	if p:GetAttribute("Acorns") == nil then p:SetAttribute("Acorns", 0) end
end)
for _, p in ipairs(Players:GetPlayers()) do
	if p:GetAttribute("Acorns") == nil then p:SetAttribute("Acorns", 0) end
end
