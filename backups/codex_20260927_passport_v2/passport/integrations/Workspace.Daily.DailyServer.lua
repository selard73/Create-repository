local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local action = RS:WaitForChild("DailyAction")
local ev = RS:WaitForChild("DailyEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local AREA = {forest = "The Great Acorn Forest", village = "Rue de Noisette", domaine = "Ch" .. utf8.char(226) .. "teau de l'Acorn"}
local GOLD = Color3.fromRGB(255, 200, 60)

local function today() return math.floor((os.time() - (F:GetAttribute("DayOffsetHours") or 9) * 3600) / 86400) end
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function rewardFor(streak)
	return math.min((F:GetAttribute("BaseReward") or 10) + (F:GetAttribute("StepReward") or 5) * (streak - 1), F:GetAttribute("MaxReward") or 40)
end
local function nextStreak(player, day)
	local last, streak = item(player, "daily_day"), item(player, "daily_streak")
	if last == day - 1 then return math.max(1, streak + 1) end
	return 1
end
local function giveAcorns(player, n)
	awardAcorns:Fire(player, n)
	player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + n)
end

-- ---------------------------------------------------------------- the golden squirrel ----
local gold = {day = nil, model = nil, entry = nil, area = nil}
local function stateOf(player)
	local day = today()
	local streak = nextStreak(player, day)
	return {
		day = day, claimable = item(player, "daily_day") ~= day, streak = streak, reward = rewardFor(streak),
		goldName = F:GetAttribute("GoldName") or "", goldArea = F:GetAttribute("GoldArea") or "", goldFound = item(player, "daily_gold") == day,
	}
end
local goldClaimed={}
local function goldFound(player)
 local char=player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart")
 if not hrp or not player:GetAttribute("SaveLoaded") or not gold.model or (hrp.Position-gold.model:GetPivot().Position).Magnitude>34 then return end
	local day = today()
	if item(player, "daily_gold") == day or goldClaimed[player]==day then return end
	goldClaimed[player]=day
	setItem(player, "daily_gold", day)
	local r = F:GetAttribute("GoldReward") or 30
	giveAcorns(player, r)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"gold",{name=gold.entry and gold.entry.name or "the Golden Squirrel",area=gold.area,prize=r}) end
	ev:FireClient(player, "gold", r, gold.entry and gold.entry.name or "the Golden Squirrel")
	print(string.format("Daily: %s found the golden %s (+%d)", player.Name, gold.entry and gold.entry.name or "?", r))
end
local function pickGold(day)
	local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
	local list = Registry.squirrels
	local n = #list
	for k = 0, n - 1 do
		local e = list[(day + k) % n + 1]
		local model
		for _, m in ipairs(workspace:GetDescendants()) do
			if m:IsA("Model") and m.Name:lower() == e.id .. "_color" and m:FindFirstChildWhichIsA("MeshPart", true) then model = m break end
		end
		if model and model:GetAttribute("SquirrelId") then return e, model end
	end
end
local function spotFor(day, map)
	local spots = workspace:FindFirstChild("AcornSpots")
	if not spots then return nil end
	local list = {}
	for _, a in ipairs(spots:GetChildren()) do if a:IsA("Attachment") and (a:GetAttribute("Section") or "forest") == map then list[#list + 1] = a end end
	if #list == 0 then for _, a in ipairs(spots:GetChildren()) do if a:IsA("Attachment") then list[#list + 1] = a end end end
	if #list == 0 then return nil end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list[Random.new(day * 7919 + 13):NextInteger(1, #list)]
end
local function makeGold(day)
	if gold.model then gold.model:Destroy(); gold.model = nil end
	local entry, source = pickGold(day)
	if not entry then warn("Daily: no squirrel model to make golden") return end
	local spot = spotFor(day, entry.map)
	if not spot then warn("Daily: no AcornSpots to hide in") return end
	local clone = source:Clone()
	clone.Name = "GoldenSquirrel"
	-- strip every attribute (the squirrel scripts paint any mesh that carries GrayTexture/ColorTexture) and the
	-- bones (that is how they recognise a squirrel mesh); RBX_ attributes belong to Roblox and cannot be touched
	local function stripAttributes(inst)
		for k in pairs(inst:GetAttributes()) do
			if not k:match("^RBX_") then pcall(function() inst:SetAttribute(k, nil) end) end
		end
	end
	local CS = game:GetService("CollectionService")
	for _, t in ipairs(CS:GetTags(clone)) do CS:RemoveTag(clone, t) end      -- not a collectible: no "Squirrel" tag
	stripAttributes(clone)
	for _, d in ipairs(clone:GetDescendants()) do
		for _, t in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, t) end
		stripAttributes(d)
		if d:IsA("Bone") then d:Destroy() end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Highlight") or d:IsA("BillboardGui") or d:IsA("BaseScript")
			or d:IsA("SurfaceAppearance") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Decal") then d:Destroy() end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.Transparency = 0
			if d:IsA("MeshPart") then d.TextureID = "" end
			d.Color = GOLD; d.Material = Enum.Material.SmoothPlastic; d.Reflectance = 0.25   -- Metal went dark in the shade
		end
	end
	-- before he is found he is a pale cream-gold with a glow outline (only where you can see him: no peeking through
	-- walls); the click turns him bright shiny yellow on the finder's screen
	local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255, 244, 205); hl.FillTransparency = 0.35; hl.OutlineColor = Color3.fromRGB(255, 240, 150)
	hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Parent = clone
	clone.Parent = F
	local pos = spot.WorldPosition
	-- keep the original's own rotation (Meshy meshes stand up through their pivot) and only turn it about the vertical
	local srcRot = source:GetPivot().Rotation
	clone:PivotTo(CFrame.new(pos) * CFrame.Angles(0, Random.new(day):NextNumber(0, math.pi * 2), 0) * srcRot)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {clone, workspace:FindFirstChild("Acorns") or clone, workspace:FindFirstChild("AcornSpots") or clone}
	local hit = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -12, 0), rp)
	local groundY = hit and hit.Position.Y or pos.Y
	local cf, size = clone:GetBoundingBox()
	clone:PivotTo(clone:GetPivot() + Vector3.new(0, groundY + 0.05 - (cf.Position.Y - size.Y / 2), 0))
	-- one invisible box round the whole squirrel takes the click (its meshes are several parts, and a click on a
	-- lamb or a staff must count too); the sparkles and the glow ride on it
	local bcf, bsize = clone:GetBoundingBox()
	local box = Instance.new("Part"); box.Name = "Hitbox"; box.Size = bsize + Vector3.new(0.4, 0.4, 0.4); box.CFrame = bcf; box.Transparency = 1
	box.Anchored = true; box.CanCollide = false; box.CanQuery = true; box.CastShadow = false; box.Parent = clone
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(GOLD); pe.LightEmission = 1
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0)}); pe.Lifetime = NumberRange.new(0.8, 1.4); pe.Rate = 12
	pe.Speed = NumberRange.new(0.5, 1.5); pe.SpreadAngle = Vector2.new(180, 180); pe.Transparency = NumberSequence.new(0.2); pe.Parent = box
	local l = Instance.new("PointLight"); l.Color = GOLD; l.Brightness = 0.8; l.Range = 8; l.Parent = box
	local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 28; cd.Parent = box
	cd.MouseClick:Connect(goldFound)
 box.CanTouch=true
 box.Touched:Connect(function(hit)
  local char=hit:FindFirstAncestorOfClass("Model");local player=char and Players:GetPlayerFromCharacter(char)
  if player then goldFound(player) end
 end)
	gold.day, gold.model, gold.entry, gold.area = day, clone, entry, AREA[entry.map] or entry.map
	F:SetAttribute("GoldName", entry.name); F:SetAttribute("GoldArea", gold.area); F:SetAttribute("GoldDay", day)
	print(string.format("Daily: the golden %s is hiding in %s at (%.0f,%.0f,%.0f)", entry.name, gold.area, pos.X, groundY, pos.Z))
end

-- ---------------------------------------------------------------- players ----
local function offer(player) ev:FireClient(player, "state", stateOf(player)) end
local function watch(player)
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 15 do task.wait(0.25) end
		if not player.Parent then return end
		task.wait(2)
		while not gold.model and os.clock() - t0 < 30 do task.wait(0.5) end
		offer(player)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
action.OnServerInvoke = function(player, what)
	if what == "claim" then
		local day = today()
		if item(player, "daily_day") == day then return false, "already collected today" end
		local streak = nextStreak(player, day)
		local r = rewardFor(streak)
		setItem(player, "daily_day", day); setItem(player, "daily_streak", streak)
		giveAcorns(player, r)
		print(string.format("Daily: %s collected day %d of a %d-day streak (+%d)", player.Name, day, streak, r))
		return true, {streak = streak, reward = r}
	elseif what == "state" then
		return true, stateOf(player)
	end
	return false, "no such thing"
end
-- the day rolls over while people are playing, too
task.spawn(function()
	-- the squirrels are scaled and tagged by SquirrelSetup first; wait for one to carry its id
	local t0 = os.clock()
	while os.clock() - t0 < 30 do
		local any = false
		for _, m in ipairs(workspace:GetDescendants()) do if m:IsA("Model") and m:GetAttribute("SquirrelId") then any = true break end end
		if any then break end
		task.wait(0.5)
	end
	makeGold(today())
	while true do
		task.wait(60)
		if today() ~= gold.day then
			makeGold(today())
			for _, p in ipairs(Players:GetPlayers()) do offer(p) end
		end
	end
end)
print("Daily: ready")

Players.PlayerRemoving:Connect(function(p) goldClaimed[p]=nil end)
