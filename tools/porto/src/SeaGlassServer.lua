-- SeaGlassServer (workspace.SeaGlass): Bella's beach finds (Oct 9 2026, Shannon: "find sea glass and shells ... build the
-- things with them ... sell them for acorns; one item, the parfum bottle, you can keep"; today's small version: "the
-- interaction can just be with the squirrel on the beach", and the squirrel finding the glass IS Bella).
-- Sea glass and shells lie on the sand round the Sea Glass Collector Squirrel (Bella) on the Spiaggia. Walk up, "Pick up":
-- Item_<kind> +1 (AwardItems, so it is saved). COUNT pieces are out at a time; a taken piece grows back somewhere else after
-- RESPAWN_MIN..RESPAWN_MAX s. Bella's prompt opens the client's panel; "make" is checked HERE: the finds come off
-- (AwardItems negative), Bella pays acorns (AwardAcorns + the Acorns attribute, as CrabServer does) or, for the parfum
-- bottle, Item_parfum_bottle = 1 to keep. The first thing made stamps the passport outing porto_beach.
-- Attributes on workspace.SeaGlass: Count 8, RespawnMin 45, RespawnMax 90, BoxMin/BoxMax (the sand to scatter on).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local G = script.Parent
local R = require(G:WaitForChild("Recipes"))
local ev = G:WaitForChild("SeaGlassEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local passport = RS:FindFirstChild("PassportActivity")
local pieces = G:WaitForChild("Pieces")
local function num(name, d) local v = G:GetAttribute(name) return type(v) == "number" and v or d end
local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end

local bella = workspace:WaitForChild("seaglass_squirrel_color", 60)
local bellaPos = bella and bella:GetPivot().Position or Vector3.new(399.6, -48.8, -1054.8)

-- ---------- where a piece may lie: sand, away from Bella and from each other, nothing built on it ----------
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Exclude; tparams.IgnoreWater = false -- a ray that meets the sea stops at its surface (Material Water), so no piece lies underwater
local oparams = OverlapParams.new(); oparams.FilterType = Enum.RaycastFilterType.Exclude; oparams.FilterDescendantsInstances = {workspace.Terrain, pieces}
local spots = {}
local function findSpots()
	local a = G:GetAttribute("BoxMin"); local b = G:GetAttribute("BoxMax")
	if typeof(a) ~= "Vector3" then a = Vector3.new(388, -60, -1095) end
	if typeof(b) ~= "Vector3" then b = Vector3.new(445, -40, -1046) end
	local rng = Random.new(7)
	local tries = 0
	while #spots < 40 and tries < 400 do
		tries += 1
		local x, z = rng:NextNumber(a.X, b.X), rng:NextNumber(a.Z, b.Z)
		local hit = workspace:Raycast(Vector3.new(x, b.Y + 20, z), Vector3.new(0, -(b.Y - a.Y + 40), 0), tparams)
		if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Sand and hit.Normal.Y > 0.8 then
			local pos = hit.Position
			local ok = (pos - bellaPos).Magnitude >= 3.5
			if ok then for _, s in ipairs(spots) do if (s - pos).Magnitude < 2.6 then ok = false break end end end
			if ok and #workspace:GetPartBoundsInRadius(pos, 1.3, oparams) > 0 then ok = false end
			if ok then table.insert(spots, pos) end
		end
	end
	print(string.format("SeaGlassServer: %d spots on the sand (%d tries)", #spots, tries))
end
findSpots()
if #spots < 8 then warn("SeaGlassServer: not enough sand spots; set BoxMin/BoxMax on workspace.SeaGlass") end

-- ---------- the pieces ----------
local function pickKind(rng)
	local total = 0
	for _, k in ipairs(R.kinds) do total += k.weight end
	local r = rng:NextNumber(0, total)
	for _, k in ipairs(R.kinds) do r -= k.weight; if r <= 0 then return k end end
	return R.kinds[1]
end
local function build(kind, pos, rng)
	local m = Instance.new("Model"); m.Name = "Find"; m:SetAttribute("Kind", kind.id)
	local body = Instance.new("Part"); body.Name = "Body"; body.Anchored = true; body.CanCollide = false; body.CanTouch = false; body.CastShadow = false
	body.Color = kind.colour
	local yaw = rng:NextNumber(0, math.pi * 2)
	if kind.glass then
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.55, 0.28, 0.45)
		body.Material = Enum.Material.Glass; body.Transparency = 0.2; body.Reflectance = 0.15
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, yaw, 0)
		local l = Instance.new("PointLight"); l.Color = kind.colour; l.Brightness = 0.7; l.Range = 3.5; l.Shadows = false; l.Parent = body
	elseif kind.shell == "scallop" then
		body.Shape = Enum.PartType.Cylinder; body.Size = Vector3.new(0.14, 0.62, 0.62); body.Material = Enum.Material.Sandstone
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, yaw, math.rad(90))
	elseif kind.shell == "spiral" then
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.3, 0.3, 0.58); body.Material = Enum.Material.Sandstone
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, yaw, 0)
	else
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.42, 0.26, 0.3); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.1
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, yaw, 0)
	end
	body.Parent = m; m.PrimaryPart = body
	local pr = Instance.new("ProximityPrompt"); pr.Name = "PickPrompt"; pr.ObjectText = kind.name; pr.ActionText = "Pick up"
	pr.MaxActivationDistance = 8; pr.HoldDuration = 0; pr.RequiresLineOfSight = false; pr.UIOffset = Vector2.new(0, -10); pr.Parent = body
	m.Parent = pieces
	return m, pr
end

local used = {}      -- [spotIndex] = piece model
local rng = Random.new()
local function freeSpot()
	local free = {}
	for i in ipairs(spots) do if not used[i] then table.insert(free, i) end end
	if #free == 0 then return nil end
	return free[rng:NextInteger(1, #free)]
end
local taking = {}
local function spawnOne()
	local i = freeSpot()
	if not i then return end
	local kind = pickKind(rng)
	local m, pr = build(kind, spots[i], rng)
	used[i] = m
	pr.Triggered:Connect(function(p)
		if taking[m] or not m.Parent then return end
		taking[m] = true
		awardItems:Fire(p, kind.id, 1)
		ev:FireClient(p, "found", kind.id, kind.name, item(p, kind.id) + 1, kind.rare == true)
		used[i] = nil
		m:Destroy()
		task.delay(rng:NextNumber(num("RespawnMin", 45), num("RespawnMax", 90)), spawnOne)
	end)
end
for _ = 1, num("Count", 8) do spawnOne() end

-- ---------- Bella ----------
if bella then
	local part = bella.PrimaryPart or bella:FindFirstChildWhichIsA("BasePart", true)
	if part and not part:FindFirstChild("BellaPrompt") then
		local pr = Instance.new("ProximityPrompt"); pr.Name = "BellaPrompt"; pr.ObjectText = "Bella"; pr.ActionText = "Show your beach finds"
		pr.MaxActivationDistance = 10; pr.HoldDuration = 0; pr.RequiresLineOfSight = false; pr.UIOffset = Vector2.new(0, -60); pr.Parent = part
		pr.Triggered:Connect(function(p) ev:FireClient(p, "open") end)
	end
else
	warn("SeaGlassServer: no seaglass_squirrel_color in the world - Bella's prompt is missing")
end

-- ---------- making things ----------
local busy = {}
ev.OnServerEvent:Connect(function(p, what, recipeId)
	if what ~= "make" or busy[p] then return end
	local r = type(recipeId) == "string" and R.byRecipe[recipeId]
	if not r then return end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - bellaPos).Magnitude > 16 then ev:FireClient(p, "nope", "Come closer to Bella first.") return end
	if r.keep and item(p, r.keep) > 0 then ev:FireClient(p, "nope", "You already have your " .. r.name:lower() .. ". Keep it safe!") return end
	for id, n in pairs(r.needs) do
		if item(p, id) < n then ev:FireClient(p, "nope", "Not enough " .. (R.byId[id] and R.byId[id].short or id) .. " yet. Keep looking!") return end
	end
	busy[p] = true
	for id, n in pairs(r.needs) do awardItems:Fire(p, id, -n) end
	local pay = 0
	if r.keep then
		awardItems:Fire(p, r.keep, 1)
	else
		pay = r.pay or 0
		awardAcorns:Fire(p, pay)
		p:SetAttribute("Acorns", (p:GetAttribute("Acorns") or 0) + pay)
	end
	if passport then passport:Fire(p, "porto_beach", {made = r.name, prize = pay, kept = r.keep ~= nil}) end
	busy[p] = nil
	ev:FireClient(p, "made", r.id, r.name, pay, r.line)
end)
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("SeaGlassServer: ready")
