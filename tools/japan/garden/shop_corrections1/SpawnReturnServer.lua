-- SpawnReturn: load each character onto the dais of the section they were last in.
local Players = game:GetService("Players")
-- JAPANFIX1_20261015: the preview module is optional - without it nobody may enter Japan and this script still runs
local PreviewAccess
do
	local m=game.ServerScriptService:FindFirstChild("JapanPreviewAccess")
	local ok, mod=false, nil
	if m then ok, mod=pcall(require, m) end
	PreviewAccess=(ok and type(mod) == "table") and mod or {IsAllowed = function() return false end, IsJapan = function() return false end, CanUsePrompt = function() return false end}
end
local RunService = game:GetService("RunService")
local DAIS = {"forest", "village", "domaine", "porto"}           -- a player respawns at the last of these daises they stood on
local function daisAt(pos)
	for _, id in ipairs(DAIS) do
		local sp = workspace:FindFirstChild("Spawn_" .. id)
		if sp then
			local d = pos - sp.Position
			if math.abs(d.X) < 6 and math.abs(d.Z) < 6 and d.Y > -2 and d.Y < 9 then return id end
		end
	end
end
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
local function japanArrival()
	local japan = workspace:FindFirstChild("JapanMap")
	local street = japan and japan:FindFirstChild("LanternStreet")
	local arrival = street and street:FindFirstChild("JapanArrival")
	return arrival and arrival:IsA("BasePart") and arrival or nil
end
local function spawnOf(id)
	if id == "japan" then return japanArrival() end
	return workspace:FindFirstChild("Spawn_" .. id) or workspace:FindFirstChild("Spawn_forest")
		or workspace:FindFirstChildWhichIsA("SpawnLocation", true)
end
local function target(player)                                    -- never past a gate that is still shut
	-- OWNER_JAPAN_START1_20261018: owner-only start; normal travel remains available.
	-- Clear OwnerStartArea to restore the usual saved-arrival behavior.
	local ownerArea = script.Parent:GetAttribute("OwnerStartArea")
	if player.UserId == 9611145467 then
		if ownerArea == "japan" and PreviewAccess.IsAllowed(player) and japanArrival() then return "japan" end
		if RANK[ownerArea] then return ownerArea end
	end
	-- Shannon's Studio tests start in Italy (SpawnReturn attribute StudioStartPorto = false turns it off; never in a live game)
	if RunService:IsStudio() and script.Parent:GetAttribute("StudioStartPorto") ~= false then return "porto" end
	-- the last dais they touched (saved as their area); older saves fall back to the last section they were in
	local area = player:GetAttribute("Dais") or player:GetAttribute("SavedArea") or player:GetAttribute("Area") or "forest"
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
	if sp then player.RespawnLocation = sp:IsA("SpawnLocation") and sp or nil end
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
	elseif sp and char.PrimaryPart and (id == "japan" or areaAt(char.PrimaryPart.Position) ~= id) then
		char:PivotTo(sp.CFrame + Vector3.new(0, 3.5, 0))          -- the character beat the save; walk it over
	end
end
local function join(player)
	player.CharacterAdded:Connect(function(char)
		-- Japan uses its existing arrival marker, not a public/random spawn pad.
		if player.UserId == 9611145467 and script.Parent:GetAttribute("OwnerStartArea") == "japan" and PreviewAccess.IsAllowed(player) then
			task.spawn(function()
				char:WaitForChild("HumanoidRootPart", 15)
				if player.Character == char and char.PrimaryPart then
					local ok, err = pcall(bringIn, player)
					if not ok then warn("Owner Japan arrival: " .. tostring(err)) end
				end
			end)
		end
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
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and PreviewAccess.IsAllowed(player) and not player:GetAttribute("JapanPreviewInFlight") and PreviewAccess.IsJapan(root.Position) then
				if player:GetAttribute("Area") ~= "japan" then player:SetAttribute("Area", "japan") end   -- (JAPANFIX1: Japan is its own area, not the last one she left)
			elseif root and not (PreviewAccess.IsAllowed(player) and (player:GetAttribute("JapanPreviewInFlight") or PreviewAccess.IsJapan(root.Position))) then
				local dais = daisAt(root.Position)
				if dais and dais ~= player:GetAttribute("Dais") then
					player:SetAttribute("Dais", dais)
					pcall(aim, player)
				end
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
