-- SpawnReturn: quit in the Château and you come back on the Château's dais, not at the top of the forest. The section
-- a player is standing in is kept on the player as an attribute, SquirrelSetup saves it beside their finds, and on the
-- next join the character is loaded straight onto that section's SpawnLocation. A section whose gate they have not
-- opened yet is never used, so wiping progress puts them back in the forest.
-- Needs the three daises from build_spawnpads.lua (Spawn_forest / Spawn_village / Spawn_domaine).
-- Oct 1 2026: knows Porto Nocciola (Spawn_porto from tools/travel/install_travel_t1.lua): south of z -300 is porto; the
-- respawn honours Item_porto / Item_frenchrank. Same patch the installer applies to the live script.
-- Run in edit mode: require(workspace.SpawnReturn.PatchModule)()  (packed by village/make_patch.py)
return function()
	local report = {}
	local scripts = workspace:WaitForChild("SquirrelScripts")

	-- ---------------------------------------------------------------- 1. save the section beside the finds ----
	local setup = scripts:WaitForChild("SquirrelSetup")
	if not setup.Source:find("SavedArea", 1, true) then
		local src = setup.Source
		local function sub(old, new, what)
			local i = src:find(old, 1, true)
			assert(i, "SpawnReturn: could not find " .. what .. " in SquirrelSetup")
			assert(not src:find(old, i + #old, true), "SpawnReturn: " .. what .. " is not unique")
			src = src:sub(1, i - 1) .. new .. src:sub(i + #old)
		end
		-- the load already has the saved table in hand; take the section off it too
		sub([[				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end]],
			[[				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end
			if type(data) == "table" and type(data.area) == "string" then player:SetAttribute("SavedArea", data.area) end]],
			"the load's found list")
		-- the save merges finds across servers; the section is simply the latest one we know about
		sub([[			return {found = out, updated = os.time()}]],
			[[			local area = player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil
			return {found = out, area = area, updated = os.time()}]],
			"the save's returned table")
		-- SpawnReturn waits for this before it decides where to put the character
		sub([[	loaded[uid] = true]],
			[[	loaded[uid] = true
	player:SetAttribute("SaveLoaded", true)]],
			"the end of the load")
		setup.Source = src .. [==[

-- ---- the section a player was last in: SpawnReturn sets the attribute, this saves it with the next batch ----
local function watchArea(player)
	player:GetAttributeChangedSignal("Area"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Area") ~= player:GetAttribute("SavedArea") then
			dirty[player.UserId] = true                     -- landing back in the section they left is not a change
		end
	end)
end
Players.PlayerAdded:Connect(watchArea)
for _, player in ipairs(Players:GetPlayers()) do watchArea(player) end
]==]
		table.insert(report, "SquirrelSetup saves the section")
	else
		table.insert(report, "SquirrelSetup already patched")
	end

	-- ---------------------------------------------------------------- 2. the spawn itself ----
	local old = workspace:FindFirstChild("SpawnReturn"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "SpawnReturn"; F.Parent = workspace
	local SERVER = [==[
-- SpawnReturn: load each character onto the dais of the section they were last in.
local Players = game:GetService("Players")
local boundary = workspace:FindFirstChild("Boundary")
local NEED = (boundary and boundary:GetAttribute("Need")) or 10
local ORDER = {"forest", "village", "domaine"}                   -- each one is behind the one before it
local RANK = {forest = 1, village = 2, domaine = 3}
local EDGE = {{"domaine", 353}, {"village", 150}}                -- same x lines the gates use

local function areaAt(pos)
	if pos.Z < -300 then return "porto" end                   -- the gorge, the plunge pool and the shore: Porto Nocciola (Travel)
	for _, a in ipairs(EDGE) do if pos.X >= a[2] then return a[1] end end
	return "forest"
end
local function spawnOf(id)
	return workspace:FindFirstChild("Spawn_" .. id) or workspace:FindFirstChild("Spawn_forest")
		or workspace:FindFirstChildWhichIsA("SpawnLocation", true)
end
local function target(player)                                    -- never past a gate that is still shut
	local area = player:GetAttribute("Area") or player:GetAttribute("SavedArea") or "forest"
	-- Porto Nocciola (Travel): a player who has landed there (Item_porto) comes back to its dais; anyone else whose last
	-- area is the south (in transit down the river) comes back to the last French section they stood in (Item_frenchrank)
	if area == "porto" then
		if (player:GetAttribute("Item_porto") or 0) >= 1 then return "porto" end
		area = ORDER[player:GetAttribute("Item_frenchrank") or 0] or "forest"
	end
	local want = RANK[area] or 1
	local reach = 1                                              -- how far the finds so far let them go
	while reach < #ORDER and (player:GetAttribute("Found_" .. ORDER[reach]) or 0) >= NEED do reach += 1 end
	return ORDER[math.min(want, reach)]
end
local function aim(player)                                       -- point the next spawn at the right dais
	local id = target(player)
	local sp = spawnOf(id)
	if sp then player.RespawnLocation = sp end
	return id, sp
end
local function bringIn(player)
	local t0 = os.clock()
	while player.Parent and player:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 8 do task.wait(0.15) end
	if not player.Parent then return end
	local id, sp = aim(player)
	local char = player.Character
	if not char then
		player:LoadCharacter()
	elseif sp and char.PrimaryPart and areaAt(char.PrimaryPart.Position) ~= id then
		char:PivotTo(sp.CFrame + Vector3.new(0, 3.5, 0))          -- the character beat the save; walk it over
	end
end
local function join(player)
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 15)
		if hum then
			hum.Died:Connect(function()
				task.wait(Players.RespawnTime)
				if player.Parent then pcall(aim, player); pcall(function() player:LoadCharacter() end) end
			end)
		end
	end)
	task.spawn(function()
		local ok, err = pcall(bringIn, player)
		if not ok then warn("SpawnReturn: " .. tostring(err)) end
		if player.Parent and not player.Character then pcall(function() player:LoadCharacter() end) end
	end)
	task.delay(14, function()                                     -- nobody is ever left without a character
		if player.Parent and not player.Character then pcall(function() player:LoadCharacter() end) end
	end)
end
Players.PlayerAdded:Connect(join)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(join, player) end

-- which section they are in now, checked often enough to catch a walk through a gate
task.spawn(function()
	while true do
		task.wait(2)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				local id = areaAt(root.Position)
				if id ~= player:GetAttribute("Area") then
					player:SetAttribute("Area", id)
					pcall(aim, player)
				end
			end
		end
	end
end)
Players.CharacterAutoLoads = false                                -- last, so a fault above still leaves spawning working
]==]
	local s = Instance.new("Script"); s.Name = "SpawnReturnServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	table.insert(report, "SpawnReturnServer installed")
	print("SpawnReturn: " .. table.concat(report, ", "))
end
