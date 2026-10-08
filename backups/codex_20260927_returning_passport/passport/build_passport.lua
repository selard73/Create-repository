-- Passport 2.1 migration for the existing 1001 Squirrels place. EDIT ONLY.
-- Requires the v1 Passport already installed; see passport/README.md.
return function()
-- codex_passport_v2 v2 (EDIT ONLY): personal memories and both collection inputs
assert(not game:GetService("RunService"):IsRunning(),"EDIT only")
local changes={}
table.insert(changes,{target=workspace.AcornSystem.AcornServer,source=[====[local Players = game:GetService("Players")
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
]====],before=[====[local Players = game:GetService("Players")
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

	local hit = m:FindFirstChild("Hit")
	hit.Touched:Connect(function(other)
		local char = other and other.Parent
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
]====]})
table.insert(changes,{target=workspace.Baguette.ChaseServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local join = F:WaitForChild("ChaseJoin")
local ev = F:WaitForChild("ChaseEvent")
local stand = F:WaitForChild("Stand")
local prize = stand:WaitForChild("ChaseBaguette")
local award = RS:WaitForChild("AwardAcorns", 30)
local C = Color3.fromRGB
local UP = CFrame.Angles(0, 0, math.rad(90))
local LAND = {}
for entry in string.gmatch(F:GetAttribute("Landmarks") or "", "[^;]+") do
	local name, x, z = entry:match("^(.-)|(%-?%d+)|(%-?%d+)$")
	if name then table.insert(LAND, {name, tonumber(x), tonumber(z)}) end
end
local function A(k) return F:GetAttribute(k) end

local joined = {}                                       -- player -> true
local holder, immuneUntil, heldSince, earnedThisHold = nil, 0, 0, 0
local noTakeBack = {}                                   -- player -> clock until which they can't take it back
local grabs = {}                                        -- UserId -> {count, since}

local function parts(p)
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid"), c
end
local function count() local n = 0; for p in pairs(joined) do if p.Parent then n += 1 end end; return n end
local function give(p, n)
	if n <= 0 then return end
	if award then award:Fire(p, n) end
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
end

-- the baguette on the holder's back, crumbs falling behind
local function removeHeld(p)
	local _, _, c = parts(p)
	local m = c and c:FindFirstChild("ChaseBaguette")
	if m then m:Destroy() end
end
local function attach(p)
	local hrp, _, c = parts(p)
	local torso = c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
	if not (hrp and torso) then return end
	removeHeld(p)
	local m = Instance.new("Model"); m.Name = "ChaseBaguette"
	local function piece(name, size, colour, shape, offset)
		local q = Instance.new("Part"); q.Name = name; q.Size = size; q.Color = colour; q.Material = Enum.Material.SmoothPlastic
		if shape then q.Shape = shape end
		q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.Massless = true
		local cf = CFrame.new(0, 0.2, 0.62) * CFrame.Angles(0, 0, math.rad(55)) * offset     -- slung across the back
		q.CFrame = torso.CFrame * cf
		local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = q; w.C0 = cf; w.Parent = q
		q.Parent = m
		return q
	end
	local loaf = piece("Loaf", Vector3.new(3.1, 0.44, 0.44), C(226, 172, 96), Enum.PartType.Cylinder, CFrame.new())
	for i = -1, 1 do
		piece("Slash", Vector3.new(0.4, 0.06, 0.3), C(240, 206, 150), nil, CFrame.new(i * 0.8, 0, -0.19) * CFrame.Angles(0, math.rad(35), 0))
	end
	piece("Ribbon", Vector3.new(0.3, 0.48, 0.48), C(200, 60, 70), Enum.PartType.Cylinder, CFrame.new(0, 0, 0))
	local a = Instance.new("Attachment"); a.Parent = loaf
	local crumbs = Instance.new("ParticleEmitter"); crumbs.Name = "Crumbs"; crumbs.Color = ColorSequence.new(C(214, 164, 100))
	crumbs.Size = NumberSequence.new(0.14); crumbs.Rate = 7; crumbs.Lifetime = NumberRange.new(1.2, 1.8); crumbs.Speed = NumberRange.new(0.5, 1.5)
	crumbs.Acceleration = Vector3.new(0, -18, 0); crumbs.SpreadAngle = Vector2.new(60, 60); crumbs.Parent = a
	m.Parent = c
end

local function where(p)
	local hrp = parts(p)
	if not hrp or #LAND == 0 then return "" end
	local best, bd = LAND[1][1], math.huge
	for _, l in ipairs(LAND) do
		local d = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(l[2], l[3])).Magnitude
		if d < bd then best, bd = l[1], d end
	end
	return best
end

local function showAtBakery(on)
	F:SetAttribute("AtBakery", on)
	prize.Transparency = on and 0 or 1
	prize.ShineAt.Shine.Enabled = on
end
local function recordHold(ongoing)
 if holder and holder.Parent then
  local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(holder,"baguette",{seconds=math.max(0,os.clock()-heldSince),prize=earnedThisHold,ongoing=ongoing}) end
 end
end
local function setHolder(p, reason, from)
 recordHold(false)
	if holder then removeHeld(holder) end
	holder = p
	if p then

			attach(p)
		F:SetAttribute("Holder", p.UserId); F:SetAttribute("HolderName", p.DisplayName); F:SetAttribute("HolderWhere", where(p))
		immuneUntil = os.clock() + (A("Immune") or 5); heldSince = os.clock(); earnedThisHold = 0
		recordHold(true)
		showAtBakery(false)
	else
		F:SetAttribute("Holder", 0); F:SetAttribute("HolderName", ""); F:SetAttribute("HolderWhere", "")
	end
	for q in pairs(joined) do
		if q.Parent then ev:FireClient(q, "holder", p and p.DisplayName or "", from and from.DisplayName or "", reason or "", p and p.UserId or 0, from and from.UserId or 0) end
	end
end
local function grabPrize(p)
	local now = os.clock()
	local g = grabs[p.UserId]
	if not g or now - g.since > 3600 then g = {count = 0, since = now}; grabs[p.UserId] = g end
	g.count += 1
	if g.count <= (A("GrabCap") or 12) then give(p, A("GrabPrize") or 10) return true end
	return false
end

local function setJoined(p, on)
	if on then joined[p] = true; p:SetAttribute("InChase", true)
	else
		joined[p] = nil; p:SetAttribute("InChase", nil)
		if holder == p then setHolder(nil, "left") end
	end
	F:SetAttribute("Playing", count())
end
join.OnServerEvent:Connect(function(p, on) setJoined(p, on == true) end)
PPS.PromptTriggered:Connect(function(prompt, p)
	if prompt.Name == "ChasePrompt" and prompt:IsDescendantOf(F) then setJoined(p, true); ev:FireClient(p, "joined") end
end)
Players.PlayerRemoving:Connect(function(p) setJoined(p, false); noTakeBack[p] = nil end)
local function watch(p) p.CharacterAdded:Connect(function() task.wait(0.5); if holder == p then attach(p) end end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- the holder's whereabouts for the hints, and the slow reward for keeping it
task.spawn(function()
	local lastPay = os.clock()
 local lastMemory=0
	while true do
		task.wait(1)
		if holder then F:SetAttribute("HolderWhere", where(holder)) end
  if holder and os.clock()-lastMemory>=5 then lastMemory=os.clock();recordHold(true) end
		if holder and os.clock() - lastPay >= (A("HoldEvery") or 10) then
			lastPay = os.clock()
			local cap = A("HoldCap") or 30
			if count() >= (A("MinPlayers") or 2) and earnedThisHold < cap then
				local n = math.min(A("HoldPrize") or 1, cap - earnedThisHold)
				earnedThisHold += n
				give(holder, n)
			end
		end
	end
end)

-- the chase itself
while true do
	task.wait(0.1)
	local n = count()
	if n < (A("MinPlayers") or 2) then
		if holder then setHolder(nil, "waiting") end
		if F:GetAttribute("AtBakery") then showAtBakery(false) end
	elseif not holder then
		if not F:GetAttribute("AtBakery") then
			showAtBakery(true)
			for q in pairs(joined) do if q.Parent then ev:FireClient(q, "bakery") end end
		end
		for q in pairs(joined) do                       -- first to the basket takes it
			local r, h = parts(q)
			if r and h and h.Health > 0 and (r.Position - prize.Position).Magnitude < 6 then
				setHolder(q, "bakery")
				local paid = grabPrize(q)
				ev:FireClient(q, "grabbed", paid)
				break
			end
		end
	elseif os.clock() > immuneUntil then
		local hr, hh = parts(holder)
		if hr and hh and hh.Health > 0 then
			for q in pairs(joined) do
				if q ~= holder and q.Parent and os.clock() > (noTakeBack[q] or 0) then
					local r, h = parts(q)
					if r and h and h.Health > 0 and (r.Position - hr.Position).Magnitude < (A("Range") or 4) then
						local lost = holder
						noTakeBack[lost] = os.clock() + (A("NoTakeBack") or 30)
						setHolder(q, "stolen", lost)
						local paid = grabPrize(q)
						ev:FireClient(q, "grabbed", paid)
						break
					end
				end
			end
		end
	end
end
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local join = F:WaitForChild("ChaseJoin")
local ev = F:WaitForChild("ChaseEvent")
local stand = F:WaitForChild("Stand")
local prize = stand:WaitForChild("ChaseBaguette")
local award = RS:WaitForChild("AwardAcorns", 30)
local C = Color3.fromRGB
local UP = CFrame.Angles(0, 0, math.rad(90))
local LAND = {}
for entry in string.gmatch(F:GetAttribute("Landmarks") or "", "[^;]+") do
	local name, x, z = entry:match("^(.-)|(%-?%d+)|(%-?%d+)$")
	if name then table.insert(LAND, {name, tonumber(x), tonumber(z)}) end
end
local function A(k) return F:GetAttribute(k) end

local joined = {}                                       -- player -> true
local holder, immuneUntil, heldSince, earnedThisHold = nil, 0, 0, 0
local noTakeBack = {}                                   -- player -> clock until which they can't take it back
local grabs = {}                                        -- UserId -> {count, since}

local function parts(p)
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid"), c
end
local function count() local n = 0; for p in pairs(joined) do if p.Parent then n += 1 end end; return n end
local function give(p, n)
	if n <= 0 then return end
	if award then award:Fire(p, n) end
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
end

-- the baguette on the holder's back, crumbs falling behind
local function removeHeld(p)
	local _, _, c = parts(p)
	local m = c and c:FindFirstChild("ChaseBaguette")
	if m then m:Destroy() end
end
local function attach(p)
	local hrp, _, c = parts(p)
	local torso = c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
	if not (hrp and torso) then return end
	removeHeld(p)
	local m = Instance.new("Model"); m.Name = "ChaseBaguette"
	local function piece(name, size, colour, shape, offset)
		local q = Instance.new("Part"); q.Name = name; q.Size = size; q.Color = colour; q.Material = Enum.Material.SmoothPlastic
		if shape then q.Shape = shape end
		q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.Massless = true
		local cf = CFrame.new(0, 0.2, 0.62) * CFrame.Angles(0, 0, math.rad(55)) * offset     -- slung across the back
		q.CFrame = torso.CFrame * cf
		local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = q; w.C0 = cf; w.Parent = q
		q.Parent = m
		return q
	end
	local loaf = piece("Loaf", Vector3.new(3.1, 0.44, 0.44), C(226, 172, 96), Enum.PartType.Cylinder, CFrame.new())
	for i = -1, 1 do
		piece("Slash", Vector3.new(0.4, 0.06, 0.3), C(240, 206, 150), nil, CFrame.new(i * 0.8, 0, -0.19) * CFrame.Angles(0, math.rad(35), 0))
	end
	piece("Ribbon", Vector3.new(0.3, 0.48, 0.48), C(200, 60, 70), Enum.PartType.Cylinder, CFrame.new(0, 0, 0))
	local a = Instance.new("Attachment"); a.Parent = loaf
	local crumbs = Instance.new("ParticleEmitter"); crumbs.Name = "Crumbs"; crumbs.Color = ColorSequence.new(C(214, 164, 100))
	crumbs.Size = NumberSequence.new(0.14); crumbs.Rate = 7; crumbs.Lifetime = NumberRange.new(1.2, 1.8); crumbs.Speed = NumberRange.new(0.5, 1.5)
	crumbs.Acceleration = Vector3.new(0, -18, 0); crumbs.SpreadAngle = Vector2.new(60, 60); crumbs.Parent = a
	m.Parent = c
end

local function where(p)
	local hrp = parts(p)
	if not hrp or #LAND == 0 then return "" end
	local best, bd = LAND[1][1], math.huge
	for _, l in ipairs(LAND) do
		local d = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(l[2], l[3])).Magnitude
		if d < bd then best, bd = l[1], d end
	end
	return best
end

local function showAtBakery(on)
	F:SetAttribute("AtBakery", on)
	prize.Transparency = on and 0 or 1
	prize.ShineAt.Shine.Enabled = on
end
local function setHolder(p, reason, from)
	if holder then removeHeld(holder) end
	holder = p
	if p then
local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(p, "baguette") end
			attach(p)
		F:SetAttribute("Holder", p.UserId); F:SetAttribute("HolderName", p.DisplayName); F:SetAttribute("HolderWhere", where(p))
		immuneUntil = os.clock() + (A("Immune") or 5); heldSince = os.clock(); earnedThisHold = 0
		showAtBakery(false)
	else
		F:SetAttribute("Holder", 0); F:SetAttribute("HolderName", ""); F:SetAttribute("HolderWhere", "")
	end
	for q in pairs(joined) do
		if q.Parent then ev:FireClient(q, "holder", p and p.DisplayName or "", from and from.DisplayName or "", reason or "", p and p.UserId or 0, from and from.UserId or 0) end
	end
end
local function grabPrize(p)
	local now = os.clock()
	local g = grabs[p.UserId]
	if not g or now - g.since > 3600 then g = {count = 0, since = now}; grabs[p.UserId] = g end
	g.count += 1
	if g.count <= (A("GrabCap") or 12) then give(p, A("GrabPrize") or 10) return true end
	return false
end

local function setJoined(p, on)
	if on then joined[p] = true; p:SetAttribute("InChase", true)
	else
		joined[p] = nil; p:SetAttribute("InChase", nil)
		if holder == p then setHolder(nil, "left") end
	end
	F:SetAttribute("Playing", count())
end
join.OnServerEvent:Connect(function(p, on) setJoined(p, on == true) end)
PPS.PromptTriggered:Connect(function(prompt, p)
	if prompt.Name == "ChasePrompt" and prompt:IsDescendantOf(F) then setJoined(p, true); ev:FireClient(p, "joined") end
end)
Players.PlayerRemoving:Connect(function(p) setJoined(p, false); noTakeBack[p] = nil end)
local function watch(p) p.CharacterAdded:Connect(function() task.wait(0.5); if holder == p then attach(p) end end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- the holder's whereabouts for the hints, and the slow reward for keeping it
task.spawn(function()
	local lastPay = os.clock()
	while true do
		task.wait(1)
		if holder then F:SetAttribute("HolderWhere", where(holder)) end
		if holder and os.clock() - lastPay >= (A("HoldEvery") or 10) then
			lastPay = os.clock()
			local cap = A("HoldCap") or 30
			if count() >= (A("MinPlayers") or 2) and earnedThisHold < cap then
				local n = math.min(A("HoldPrize") or 1, cap - earnedThisHold)
				earnedThisHold += n
				give(holder, n)
			end
		end
	end
end)

-- the chase itself
while true do
	task.wait(0.1)
	local n = count()
	if n < (A("MinPlayers") or 2) then
		if holder then setHolder(nil, "waiting") end
		if F:GetAttribute("AtBakery") then showAtBakery(false) end
	elseif not holder then
		if not F:GetAttribute("AtBakery") then
			showAtBakery(true)
			for q in pairs(joined) do if q.Parent then ev:FireClient(q, "bakery") end end
		end
		for q in pairs(joined) do                       -- first to the basket takes it
			local r, h = parts(q)
			if r and h and h.Health > 0 and (r.Position - prize.Position).Magnitude < 6 then
				setHolder(q, "bakery")
				local paid = grabPrize(q)
				ev:FireClient(q, "grabbed", paid)
				break
			end
		end
	elseif os.clock() > immuneUntil then
		local hr, hh = parts(holder)
		if hr and hh and hh.Health > 0 then
			for q in pairs(joined) do
				if q ~= holder and q.Parent and os.clock() > (noTakeBack[q] or 0) then
					local r, h = parts(q)
					if r and h and h.Health > 0 and (r.Position - hr.Position).Magnitude < (A("Range") or 4) then
						local lost = holder
						noTakeBack[lost] = os.clock() + (A("NoTakeBack") or 30)
						setHolder(q, "stolen", lost)
						local paid = grabPrize(q)
						ev:FireClient(q, "grabbed", paid)
						break
					end
				end
			end
		end
	end
end
]====]})
table.insert(changes,{target=workspace.Bookshop.BookServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out past the walls: a short zoom leash, given back at the door (or on respawn)
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player)
	player.CharacterAdded:Connect(function() leash(player, false) end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)
-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InBookshop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "BookPrompt" then
		local id = prompt:GetAttribute("BookId")
		local b = byId[id]
		if not b or b.soon then return end
		ev:FireClient(player, "book", id, true) -- everyone may read
	end
end)
-- Free reading: no purchase, ownership grant, or acorn deduction.
action.OnServerInvoke = function(player, what, id)
	local b = type(id) == "string" and byId[id]
	if not b or b.soon then return false, "no such book" end
	if what == "buy" or what == "owned" then return true, "Free to read" end
	if what == "read" then
		local char = player.Character
		local passport = RS:FindFirstChild("PassportActivity")
		if passport and char and char:GetAttribute("InBookshop") then passport:Fire(player,"book",{title=b.title,character=({crumbs="the amazing International Spy Squirrel",story2="the charming Gérard and the determined Margaux Delacroix-Pim",story3="the wonderfully stubborn Picnic Pierre"})[id]}) end
		return true, {title = b.title, by = b.by, text = b.text, audio = b.audio or 0}
	end
	return false, "no such thing"
end
print("BookServer: ready - " .. #Books .. " books on the table")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out past the walls: a short zoom leash, given back at the door (or on respawn)
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player)
	player.CharacterAdded:Connect(function() leash(player, false) end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)
-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InBookshop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "BookPrompt" then
		local id = prompt:GetAttribute("BookId")
		local b = byId[id]
		if not b or b.soon then return end
		ev:FireClient(player, "book", id, true) -- everyone may read
	end
end)
-- Free reading: no purchase, ownership grant, or acorn deduction.
action.OnServerInvoke = function(player, what, id)
	local b = type(id) == "string" and byId[id]
	if not b or b.soon then return false, "no such book" end
	if what == "buy" or what == "owned" then return true, "Free to read" end
	if what == "read" then
		local char = player.Character
		local passport = RS:FindFirstChild("PassportActivity")
		if passport and char and char:GetAttribute("InBookshop") then passport:Fire(player,"book") end
		return true, {title = b.title, by = b.by, text = b.text, audio = b.audio or 0}
	end
	return false, "no such thing"
end
print("BookServer: ready - " .. #Books .. " books on the table")
]====]})
table.insert(changes,{target=workspace.Champion.ChampionServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local F = script.Parent
local ev = RS:WaitForChild("ChampionEvent")
local awardItems = RS:WaitForChild("AwardItems")
local TOPIC = "DayChampion_v1"
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("DayChampion_v1") end) end
local MARBLE = Color3.fromRGB(232, 228, 218)

local function offsetHours() local d = workspace:FindFirstChild("Daily"); return (d and d:GetAttribute("DayOffsetHours")) or 9 end
local function today() return math.floor((os.time() - offsetHours() * 3600) / 86400) end
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function titleFor(no) return ordinal(no) .. " Grand Keeper of the Great Acorn" end
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and not ids[id] then ids[id] = true; n += 1 end
	end
	return n
end
local function dateOf(day) return os.date("!%B %d, %Y", day * 86400 + 12 * 3600) end

-- ---- the statue ----
local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
local FX = F:GetAttribute("FigureX") or PX                               -- the champion's place on the plinth
local words = F:WaitForChild("Plinth"):WaitForChild("Plaque"):WaitForChild("Words")
local function strip(model)
	for _, t in ipairs(CollectionService:GetTags(model)) do CollectionService:RemoveTag(model, t) end
	for k in pairs(model:GetAttributes()) do if not k:match("^RBX_") then pcall(function() model:SetAttribute(k, nil) end) end end
	for _, d in ipairs(model:GetDescendants()) do
		for _, t in ipairs(CollectionService:GetTags(d)) do CollectionService:RemoveTag(d, t) end
		for k in pairs(d:GetAttributes()) do if not k:match("^RBX_") then pcall(function() d:SetAttribute(k, nil) end) end end
	end
end
local function stoneify(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") or d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("BodyColors")
			or d:IsA("BaseScript") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter")
			or d:IsA("Light") or d:IsA("Sound") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			if p:IsA("MeshPart") then p.TextureID = "" end
			p.Color = MARBLE; p.Material = Enum.Material.Marble; p.Reflectance = 0
		end
	end
end
local function placeOn(model, x, topY, z)
	local cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - (cf.Position.Y - size.Y / 2), z - cf.Position.Z))
end
-- A FIGURE STANDS ON ITS FEET. placeOn stands a model on the bottom of its bounding box - but a figure's box also holds
-- the invisible HumanoidRootPart, a fixed-size block at the hips, and on a short avatar (a baby with tiny legs) that block
-- reaches below the feet, so the statue floated over the plinth (Shannon, Sep 26: "a very short baby avatar and the
-- statue formed with him floating"; "some avatars are bigger ... I also want them on their feet and not buried"). The
-- lowest corner of the feet goes on the plinth top, whatever the avatar's size or shape; without visible feet, the
-- lowest visible part of the body (never the root, never anything worn).
local BODY = {LeftFoot = true, RightFoot = true, LeftLowerLeg = true, RightLowerLeg = true, LeftUpperLeg = true, RightUpperLeg = true,
	LowerTorso = true, UpperTorso = true, Head = true, LeftHand = true, RightHand = true, LeftLowerArm = true, RightLowerArm = true,
	LeftUpperArm = true, RightUpperArm = true}
local function lowestPoint(model)
	local low = math.huge
	local function consider(p)
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			low = math.min(low, (p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
		end end end
	end
	for _, n in ipairs({"LeftFoot", "RightFoot"}) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") and p.Transparency < 0.95 then consider(p) end
	end
	if low == math.huge then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and BODY[p.Name] and p.Transparency < 0.95 then consider(p) end
		end
	end
	return low
end
local function standOn(model, x, topY, z)
	local cf = model:GetBoundingBox()
	local low = lowestPoint(model)
	if low == math.huge then placeOn(model, x, topY, z) return end
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - low, z - cf.Position.Z))
end
local function giantAcorn(height, parent)
	local src = ServerStorage:FindFirstChild("ChampionAcorn")
	if not src then return nil end
	local a = src:Clone(); a.Name = "GiantAcorn"
	local _, size = a:GetBoundingBox()
	if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * height / size.Y) end) end
	a.Parent = parent or F
	return a
end
local function setPlaque(rec)
	local all = tonumber(rec and rec.total) or totalSquirrels()
	if all <= 0 then all = 44 end
	if rec then
		words.Title.Text = rec.no and ("THE " .. ordinal(rec.no):upper() .. " GRAND KEEPER") or "THE GRAND KEEPER"
		words.Day.Text = "OF THE GREAT ACORN"
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(all) .. " squirrels on " .. dateOf(rec.day)
	else
		words.Title.Text = "THE GRAND KEEPER"
		words.Day.Text = ""
		words.Who.Text = "This could be you"
		words.Note.Text = "Be the first to find all " .. tostring(all) .. " squirrels in a day and your statue will stand here."
	end
end
local building = false
-- THE FIGURE, made anywhere: o = {x, top, z (its feet go there), parent, name, scale, look (the way it faces)}. Returns the
-- posed marble figure and the gilded acorn in its raised hand. The fountain's statue and every statue in the Hall of
-- Fame at the Chateau (asked for through MakeStatue) come from this one function, so they always match.
local function makeFigure(rec, o)
	local okD, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(rec.uid) end)
	if not okD or not desc then desc = Instance.new("HumanoidDescription") end
	local okM, model = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not okM or not model then
		warn("Champion: could not make the figure: " .. tostring(model))
		return nil
	end
	local FX, TOP, PZ = o.x, o.top, o.z                                     -- (the names the pose code below always used)
	model.Name = o.name or "Figure"
	for _, s in ipairs(model:GetDescendants()) do if s:IsA("BaseScript") then s:Destroy() end end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end
	local scale = o.scale or F:GetAttribute("Scale") or 1.5
	pcall(function() model:ScaleTo(scale) end)
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = (p == root); p.CanCollide = false end end
	local up = Vector3.new(FX, TOP + 30, PZ)
	model:PivotTo(CFrame.lookAt(up, up + (o.look or Vector3.new(0, 0, -1))))   -- the fountain's faces north, toward the fountain
	model.Parent = o.parent or F
	for _ = 1, 6 do RunService.Heartbeat:Wait() end                        -- let the body settle, then freeze it
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	-- One hand holds the acorn up high, the other arm hangs relaxed at the side. The pose is carved rather than
	-- animated: with everything anchored, each arm - and anything worn on it - comes off its joints and is AIMED about
	-- its shoulder (the torso's ShoulderRigAttachment), whatever pose it started in. Avatar rigs come two ways - Motor6D
	-- joints, or the newer AnimationConstraint + BallSocketConstraint pairs - and this works on both (Sep 25: editing
	-- Motor6D joints did nothing on a constraint rig, which is why the first statue kept its arms down).
	local torso = model:FindFirstChild("UpperTorso")
	local function linked(d, moving)
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			return (d.Part0 and moving[d.Part0]) or (d.Part1 and moving[d.Part1])
		elseif d:IsA("Constraint") then
			local a0, a1 = d.Attachment0, d.Attachment1
			return (a0 and moving[a0.Parent]) or (a1 and moving[a1.Parent])
		end
		return false
	end
	local function aim(side, dir, bendDeg)
		local att = torso and torso:FindFirstChild(side .. "ShoulderRigAttachment")
		local hand = model:FindFirstChild(side .. "Hand")
		if not (att and hand and typeof(dir) == "Vector3") then return false end
		local pivot = att.WorldPosition
		local cf = torso.CFrame
		local outward = cf.RightVector * ((side == "Right") and 1 or -1)
		local w = (outward * dir.X + cf.UpVector * dir.Y + cf.LookVector * dir.Z).Unit
		-- the arm's parts, and anything worn on each of them (held on by a weld, or hung from one of their attachments)
		local armParts, owner = {}, {}
		for _, n in ipairs({"UpperArm", "LowerArm", "Hand"}) do local pp = model:FindFirstChild(side .. n); if pp then armParts[pp] = n; owner[pp] = n end end
		for _, acc in ipairs(model:GetChildren()) do
			local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
			if h then
				for _, d in ipairs(h:GetChildren()) do
					if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
						local other = (d.Part0 == h) and d.Part1 or d.Part0
						if other and armParts[other] then owner[h] = armParts[other] end
					end
				end
				local ha = h:FindFirstChildWhichIsA("Attachment")
				if ha and not owner[h] then
					for pp, n in pairs(armParts) do if pp:FindFirstChild(ha.Name) then owner[h] = n end end
				end
			end
		end
		for _, d in ipairs(model:GetDescendants()) do if linked(d, owner) then d:Destroy() end end
		local v = hand.Position - pivot
		local axis = v:Cross(w)
		if axis.Magnitude > 1e-6 then
			local rot = CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(v.Unit:Dot(w), -1, 1)))
			for pp in pairs(owner) do pp.CFrame = (rot * (pp.CFrame - pivot)) + pivot end
		end
		-- a soft bend at the elbow: the forearm and hand swing forward a little (never back)
		local upper = model:FindFirstChild(side .. "UpperArm")
		local elbow = upper and upper:FindFirstChild(side .. "ElbowRigAttachment")
		if bendDeg and bendDeg ~= 0 and elbow then
			local e = elbow.WorldPosition
			local bendAxis = w:Cross(cf.LookVector)
			if bendAxis.Magnitude > 1e-6 then
				local rot = CFrame.fromAxisAngle(bendAxis.Unit, math.rad(bendDeg))
				local rel = hand.Position - e
				if ((rot * rel) - rel):Dot(cf.LookVector) < 0 then rot = CFrame.fromAxisAngle(bendAxis.Unit, -math.rad(bendDeg)) end
				for pp, n in pairs(owner) do if n ~= "UpperArm" then pp.CFrame = (rot * (pp.CFrame - e)) + e end end
			end
		end
		return true
	end
	local holdSide = (F:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
	local freeSide = (holdSide == "Left") and "Right" or "Left"
	local upR = aim(holdSide, F:GetAttribute("HoldArm") or Vector3.new(0.45, 1, 0.15), 0)                           -- the acorn, held up high
	local upL = aim(freeSide, F:GetAttribute("FreeArm") or Vector3.new(0.22, -1, 0.12), F:GetAttribute("FreeBend") or 15)   -- relaxed at the side
	if hum then hum:Destroy() end
	stoneify(model)
	strip(model)
	standOn(model, FX, TOP, PZ)                                        -- on its feet (not on the bottom of its box)
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and p ~= root then p.CanCollide = true end end
	local holding = model:FindFirstChild(holdSide .. "Hand")
	-- the acorn is sized to the sitter (Shannon: "for short or tall avatars will the acorn position correctly too?"): the
	-- same share of their height as on an ordinary avatar, so a baby holds a baby-sized giant acorn and a giant a giant's
	local head = model:FindFirstChild("Head")
	local feet = lowestPoint(model)
	local bodyH = (head and feet < math.huge) and (head.Position.Y + head.Size.Y / 2 - feet) or 5.2 * scale
	local a = giantAcorn(math.clamp(bodyH * 0.385, 1.2, 5), o.parent)
	if a then
		if holding then
			placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z)   -- resting on the raised hand
		else
			local cf, size = model:GetBoundingBox()
			placeOn(a, cf.Position.X, cf.Position.Y + size.Y / 2, cf.Position.Z)
		end
	end
	return model, a, upR, upL
end
local function buildStatue(rec)
	while building do task.wait(0.2) end
	building = true
	for _, n in ipairs({"Figure", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	if not rec then
		local a = giantAcorn(2.6)
		if a then placeOn(a, FX, TOP, PZ) end
		building = false
		return
	end
	local model, _, upR, upL = makeFigure(rec, {x = FX, top = TOP, z = PZ, parent = F, name = "Figure", scale = F:GetAttribute("Scale") or 1.5, look = Vector3.new(0, 0, -1)})
	if not model then local a = giantAcorn(2.6); if a then placeOn(a, FX, TOP, PZ) end end
	building = false
	print(string.format("Champion: the statue of %s (No. %s) stands by the fountain (arms posed %s/%s)", tostring(rec.name), tostring(rec.no), tostring(upR), tostring(upL)))
end

-- the squirrel that stands to attention, looking up at the statue, tail raised in salute. o = {x, y, z (where it stands),
-- tx, tz (the statue it looks up at), parent, name, scale}; the fountain's is built once, the Hall's through MakeSquirrel
local function makeSquirrel(o)
	local want = F:GetAttribute("SaluteSquirrel") or "ranger_squirrel"
	local src
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do if m:GetAttribute("SquirrelId") == want then src = m break end end
	if not src then warn("Champion: no " .. want .. " to stand by the statue") return nil end
	local m = src:Clone(); m.Name = o.name or "Monument"
	strip(m)
	stoneify(m)
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true end end
	pcall(function() m:ScaleTo(m:GetScale() * (o.scale or F:GetAttribute("SquirrelScale") or 1.7)) end)
	m.Parent = o.parent or F
	local bones = {}
	for _, b in ipairs(m:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local spot = Vector3.new(o.x, o.y, o.z)
	local FX, PZ = o.tx, o.tz
	if bones.Root and bones.Head then
		-- which way it faces: root -> head, flattened (the rule SquirrelAnim uses); turn it to face the statue
		local f = bones.Head.WorldPosition - bones.Root.WorldPosition
		f = Vector3.new(f.X, 0, f.Z)
		local to = Vector3.new(FX - spot.X, 0, PZ - spot.Z)
		if f.Magnitude > 0.01 and to.Magnitude > 0.01 then
			local pivot = m:GetPivot()
			m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.atan2(to.X, to.Z) - math.atan2(f.X, f.Z), 0) * pivot.Rotation)
		end
		local fw = bones.Head.WorldPosition - bones.Root.WorldPosition
		fw = Vector3.new(fw.X, 0, fw.Z)
		if fw.Magnitude > 0.01 then
			local left = Vector3.yAxis:Cross(fw.Unit)
			local function tilt(b, deg)
				if not b or not deg or deg == 0 then return end
				local axis = b.WorldCFrame:VectorToObjectSpace(left)
				b.CFrame = b.CFrame * CFrame.fromAxisAngle(axis, math.rad(deg))
			end
			tilt(bones.Chest, F:GetAttribute("ChestTilt"))
			tilt(bones.Head, F:GetAttribute("HeadTilt"))
			tilt(bones.Tail1, F:GetAttribute("TailTilt"))
		end
	end
	placeOn(m, spot.X, spot.Y, spot.Z)
	return m
end
local function buildSquirrel()
	if F:FindFirstChild("Monument") then return end
	makeSquirrel({x = F:GetAttribute("SquirrelX"), y = F:GetAttribute("SquirrelY"), z = F:GetAttribute("SquirrelZ"), tx = FX, tz = PZ, parent = F, name = "Monument"})
end

-- ---- claiming the day ----
local localClaims = {}
local function claim(rec)
	if STUDIO or not store then
		if localClaims[rec.day] then return false, localClaims[rec.day] end
		localClaims[rec.day] = rec
		return true
	end
	for attempt = 1, 3 do
		local won, holder = false, nil
		local ok = pcall(function()
			store:UpdateAsync("day_" .. tostring(rec.day), function(oldRec)
				if oldRec ~= nil then won = false; holder = oldRec; return nil end
				won = true; holder = nil
				return rec
			end)
		end)
		if ok then return won, holder end
		task.wait(2 * attempt)
	end
	return false, nil
end
local function saveLatest(rec)
	if STUDIO or not store then return end
	pcall(function()
		store:UpdateAsync("latest", function(oldRec)
			if type(oldRec) == "table" and (oldRec.day or 0) > rec.day then return nil end
			return rec
		end)
	end)
end
-- the Roblox badge: on the win, and on joining for anyone who won before the badge existed (live servers only)
local BadgeService = game:GetService("BadgeService")
local function giveBadge(player)
	local id = tonumber(F:GetAttribute("Badge_champion")) or 0
	if id <= 0 or STUDIO then return end
	task.spawn(function()
		local okH, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, id) end)
		if okH and not has then
			local ok, err = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)            -- the current name
			if not ok then ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, id) end) end    -- the older one
			if not ok then warn("Champion: badge award failed: " .. tostring(err)) end
		end
	end)
end

-- ---- the hall: every Grand Keeper in order, 1st, 2nd, 3rd ... (what the Hall of Fame at the Chateau shows) ----
local hall, hallLoaded = {}, false
local function sortHall() table.sort(hall, function(a, b) return (tonumber(a.no) or 0) < (tonumber(b.no) or 0) end) end
local function hallFind(uid)                                         -- the player's latest win
	local best
	for _, e in ipairs(hall) do if e.uid == uid and (not best or e.no > best.no) then best = e end end
	return best
end
local function hallWins(uid) local n = 0; for _, e in ipairs(hall) do if e.uid == uid then n += 1 end end; return n end
local function hallHas(uid, total)                                   -- already won with this many squirrels (or more)?
	for _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end
	return false
end
-- every player's screen gets the list (for the Hall of Fame at the Chateau): HallJson on this folder, in order
local HttpService = game:GetService("HttpService")
local function publishHall()
	local out = {}
	for _, e in ipairs(hall) do table.insert(out, {no = e.no, uid = e.uid, name = e.name, day = e.day, total = e.total}) end
	local ok, s = pcall(function() return HttpService:JSONEncode(out) end)
	if ok then F:SetAttribute("HallJson", s) end
end
local function hallMerge(e)                                          -- an entry this server heard about: kept in order, never twice
	if type(e) ~= "table" or not e.no then return end
	for _, x in ipairs(hall) do if x.no == e.no then return end end
	table.insert(hall, {no = e.no, uid = e.uid, name = e.name, user = e.user, day = e.day, t = e.t, total = e.total})
	sortHall()
	publishHall()
end
-- a day's winner takes the next number: atomic across servers, and safe to repeat (one uid + day is never added twice)
local function hallAppend(rec)
	local function entryFor(list)
		for _, x in ipairs(list) do if x.uid == rec.uid and x.day == rec.day then return x, false end end
		local top = 0
		for _, x in ipairs(list) do top = math.max(top, tonumber(x.no) or 0) end
		return {no = top + 1, uid = rec.uid, name = rec.name, user = rec.user, day = rec.day, t = rec.t, total = rec.total or 44}, true
	end
	if STUDIO or not store then
		local e, new = entryFor(hall)
		if new then table.insert(hall, e); sortHall(); publishHall() end
		return e
	end
	for attempt = 1, 4 do
		local mine
		local ok, final = pcall(function()
			return store:UpdateAsync("hall", function(old)
				local list = (type(old) == "table" and type(old.list) == "table") and old.list or {}
				local e, new = entryFor(list)
				mine = e
				if not new then return nil end
				table.insert(list, e)
				return {list = list}
			end)
		end)
		if ok and mine then
			if type(final) == "table" and type(final.list) == "table" then hall = final.list; sortHall() end
			hallMerge(mine)
			publishHall()
			return mine
		end
		task.wait(2 * attempt)
	end
	warn("Champion: could not save the hall number for " .. tostring(rec.name) .. " - the next server start mends it")
	return nil
end
-- on start: read the hall, then make sure every day winner of the last fortnight is in it (the first time, every day from
-- LaunchDay: that is how the Day winners from before the numbering got their numbers, in the order they won)
local function loadHall()
	if STUDIO or not store then publishHall(); hallLoaded = true; return end
	local got = false
	for attempt = 1, 5 do
		local ok, v = pcall(function() return store:GetAsync("hall") end)
		if ok then
			hall = (type(v) == "table" and type(v.list) == "table") and v.list or {}
			sortHall()
			got = true
			break
		end
		task.wait(2 * attempt)
	end
	if got then
		local launch = F:GetAttribute("LaunchDay") or 20721
		local from = (#hall == 0) and launch or math.max(launch, today() - 14)
		local added = 0
		for d = from, today() do
			local ok, rec = pcall(function() return store:GetAsync("day_" .. tostring(d)) end)
			if ok and type(rec) == "table" and rec.uid then
				rec.day = rec.day or d
				local known = false
				for _, x in ipairs(hall) do if x.uid == rec.uid and x.day == rec.day then known = true end end
				if not known and hallAppend(rec) then added += 1 end
			end
		end
		print(string.format("Champion: the hall has %d keepers (%d added from the day records)", #hall, added))
	end
	publishHall()
	hallLoaded = true
end
task.spawn(loadHall)
-- the title and the numbers the badge case shows, all from the hall (nothing new in the save)
local function applyTitle(player)
	local e = hallFind(player.UserId)
	if e then
		player:SetAttribute("ChampionNo", e.no)
		player:SetAttribute("ChampionDay", e.day)
		player:SetAttribute("ChampionTotal", tonumber(e.total) or 44)
		player:SetAttribute("ChampionWins", hallWins(player.UserId))
		player:SetAttribute("ChampionTitle", titleFor(e.no))
		giveBadge(player)
	elseif item(player, "champion_day") > 0 then                        -- a Keeper the hall has not got (the store was down)
		player:SetAttribute("ChampionTitle", "Grand Keeper of the Great Acorn")
		giveBadge(player)
	end
end

local celebrated = {}
local function celebrate(rec)
	if type(rec) ~= "table" or not rec.day or celebrated[rec.day] then return end
	celebrated[rec.day] = true
	hallMerge(rec)
	ev:FireAllClients("crowned", rec)
	task.spawn(buildStatue, rec)
end
local function crown(player)
	local day = today()
	local launch = F:GetAttribute("LaunchDay") or 20721
	if day < launch and not STUDIO then return end
	local t0 = os.clock()
	while not hallLoaded and os.clock() - t0 < 60 do task.wait(0.5) end
	local total = totalSquirrels()
	if hallHas(player.UserId, total) then                              -- a Keeper already, for this many squirrels
		local e = hallFind(player.UserId)
		ev:FireClient(player, "already", e and e.no or 0, total)
		return
	end
	local n = math.max(1, day - launch + 1)
	local rec = {day = day, n = n, uid = player.UserId, name = player.DisplayName, user = player.Name, t = os.time(), total = total}
	local won, holder = claim(rec)
	if not won then
		if holder and holder.name then ev:FireClient(player, "late", holder.name, holder.n, total) end
		return
	end
	local e = hallAppend(rec)
	rec.no = e and e.no or nil
	if item(player, "champion_day") <= 0 then setItem(player, "champion_day", n) end   -- (the first day won, kept as before)
	awardItems:Fire(player, "champion_wins", 1)                          -- the days won
	player:SetAttribute("ChampionNew", true)                            -- the badge case says "new badge" only for this
	applyTitle(player)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"keeper",{keeperNo=rec.no or 0}) end
	print(string.format("Champion: %s is the %s Grand Keeper (day %d)", player.Name, rec.no and ordinal(rec.no) or "?", day))
	saveLatest(rec)
	celebrate(rec)
	if not STUDIO then pcall(function() MS:PublishAsync(TOPIC, rec) end) end
end
if not STUDIO then
	pcall(function() MS:SubscribeAsync(TOPIC, function(msg) celebrate(msg.Data) end) end)
end

-- ---- watching every player's finds ----
local function watch(player)
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 20 do task.wait(0.25) end
		task.wait(2)                                           -- the saved count lands just after SaveLoaded
		while player.Parent and not hallLoaded and os.clock() - t0 < 80 do task.wait(0.5) end
		if not player.Parent then return end
		applyTitle(player)
		local last = tonumber(player:GetAttribute("SquirrelsFound")) or 0
		player:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
			local now = tonumber(player:GetAttribute("SquirrelsFound")) or 0
			local total = totalSquirrels()
			if total > 0 and now >= total and last < total then task.spawn(crown, player) end
			last = now
		end)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- on start: the newest Keeper (or the empty plinth), and the squirrel ----
task.spawn(function()
	local t0 = os.clock()
	while totalSquirrels() == 0 and os.clock() - t0 < 30 do task.wait(0.5) end
	buildSquirrel()
	while not hallLoaded and os.clock() - t0 < 90 do task.wait(0.5) end
	local latest = hall[#hall]
	if not latest and not STUDIO and store then                         -- (the hall could not be read: the last one saved)
		local ok, rec = pcall(function() return store:GetAsync("latest") end)
		if ok and type(rec) == "table" then latest = rec end
	end
	if latest and latest.day then celebrated[latest.day] = true end
	buildStatue(latest)
end)
-- for the Hall of Fame at the Chateau (its HallServer): the same statue and the same saluting squirrel, made where it asks
local mk = Instance.new("BindableFunction"); mk.Name = "MakeStatue"; mk.Parent = F
mk.OnInvoke = function(rec, o) return makeFigure(rec, o) end
local msq = Instance.new("BindableFunction"); msq.Name = "MakeSquirrel"; msq.Parent = F
msq.OnInvoke = function(o) return makeSquirrel(o) end
if STUDIO then
	-- (a hall full of Keepers to look at: HallDebug:Invoke({{uid = ..., name = ...}, ...}) adds them, a day apart)
	local hd = Instance.new("BindableFunction"); hd.Name = "HallDebug"; hd.Parent = F
	hd.OnInvoke = function(list)
		for _, e in ipairs(list) do
			local day = (hall[#hall] and hall[#hall].day or (today() - 20)) + 1
			hallAppend({uid = e.uid, name = e.name, user = e.name, day = day, t = os.time(), total = e.total or 44})
		end
		return #hall
	end
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ChampionDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) crown(player); return player:GetAttribute("ChampionTitle") end
	-- (a statue of anyone, to check a body shape: StatueDebug:Invoke(userId, name) -> where the feet ended up)
	local sdbg = Instance.new("BindableFunction"); sdbg.Name = "StatueDebug"; sdbg.Parent = F
	sdbg.OnInvoke = function(uid, name)
		buildStatue({uid = uid, name = name or "Test", n = 0, day = 20721})
		local fig = F:FindFirstChild("Figure")
		if not fig then return "no figure" end
		local cf, size = fig:GetBoundingBox()
		return string.format("feet %.2f | plinth top %.2f | box bottom %.2f | height %.1f", lowestPoint(fig), TOP, cf.Position.Y - size.Y / 2, size.Y)
	end
end
print("Champion: ready")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local F = script.Parent
local ev = RS:WaitForChild("ChampionEvent")
local awardItems = RS:WaitForChild("AwardItems")
local TOPIC = "DayChampion_v1"
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("DayChampion_v1") end) end
local MARBLE = Color3.fromRGB(232, 228, 218)

local function offsetHours() local d = workspace:FindFirstChild("Daily"); return (d and d:GetAttribute("DayOffsetHours")) or 9 end
local function today() return math.floor((os.time() - offsetHours() * 3600) / 86400) end
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function titleFor(no) return ordinal(no) .. " Grand Keeper of the Great Acorn" end
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and not ids[id] then ids[id] = true; n += 1 end
	end
	return n
end
local function dateOf(day) return os.date("!%B %d, %Y", day * 86400 + 12 * 3600) end

-- ---- the statue ----
local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
local FX = F:GetAttribute("FigureX") or PX                               -- the champion's place on the plinth
local words = F:WaitForChild("Plinth"):WaitForChild("Plaque"):WaitForChild("Words")
local function strip(model)
	for _, t in ipairs(CollectionService:GetTags(model)) do CollectionService:RemoveTag(model, t) end
	for k in pairs(model:GetAttributes()) do if not k:match("^RBX_") then pcall(function() model:SetAttribute(k, nil) end) end end
	for _, d in ipairs(model:GetDescendants()) do
		for _, t in ipairs(CollectionService:GetTags(d)) do CollectionService:RemoveTag(d, t) end
		for k in pairs(d:GetAttributes()) do if not k:match("^RBX_") then pcall(function() d:SetAttribute(k, nil) end) end end
	end
end
local function stoneify(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") or d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("BodyColors")
			or d:IsA("BaseScript") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter")
			or d:IsA("Light") or d:IsA("Sound") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			if p:IsA("MeshPart") then p.TextureID = "" end
			p.Color = MARBLE; p.Material = Enum.Material.Marble; p.Reflectance = 0
		end
	end
end
local function placeOn(model, x, topY, z)
	local cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - (cf.Position.Y - size.Y / 2), z - cf.Position.Z))
end
-- A FIGURE STANDS ON ITS FEET. placeOn stands a model on the bottom of its bounding box - but a figure's box also holds
-- the invisible HumanoidRootPart, a fixed-size block at the hips, and on a short avatar (a baby with tiny legs) that block
-- reaches below the feet, so the statue floated over the plinth (Shannon, Sep 26: "a very short baby avatar and the
-- statue formed with him floating"; "some avatars are bigger ... I also want them on their feet and not buried"). The
-- lowest corner of the feet goes on the plinth top, whatever the avatar's size or shape; without visible feet, the
-- lowest visible part of the body (never the root, never anything worn).
local BODY = {LeftFoot = true, RightFoot = true, LeftLowerLeg = true, RightLowerLeg = true, LeftUpperLeg = true, RightUpperLeg = true,
	LowerTorso = true, UpperTorso = true, Head = true, LeftHand = true, RightHand = true, LeftLowerArm = true, RightLowerArm = true,
	LeftUpperArm = true, RightUpperArm = true}
local function lowestPoint(model)
	local low = math.huge
	local function consider(p)
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			low = math.min(low, (p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
		end end end
	end
	for _, n in ipairs({"LeftFoot", "RightFoot"}) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") and p.Transparency < 0.95 then consider(p) end
	end
	if low == math.huge then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and BODY[p.Name] and p.Transparency < 0.95 then consider(p) end
		end
	end
	return low
end
local function standOn(model, x, topY, z)
	local cf = model:GetBoundingBox()
	local low = lowestPoint(model)
	if low == math.huge then placeOn(model, x, topY, z) return end
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - low, z - cf.Position.Z))
end
local function giantAcorn(height, parent)
	local src = ServerStorage:FindFirstChild("ChampionAcorn")
	if not src then return nil end
	local a = src:Clone(); a.Name = "GiantAcorn"
	local _, size = a:GetBoundingBox()
	if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * height / size.Y) end) end
	a.Parent = parent or F
	return a
end
local function setPlaque(rec)
	local all = tonumber(rec and rec.total) or totalSquirrels()
	if all <= 0 then all = 44 end
	if rec then
		words.Title.Text = rec.no and ("THE " .. ordinal(rec.no):upper() .. " GRAND KEEPER") or "THE GRAND KEEPER"
		words.Day.Text = "OF THE GREAT ACORN"
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(all) .. " squirrels on " .. dateOf(rec.day)
	else
		words.Title.Text = "THE GRAND KEEPER"
		words.Day.Text = ""
		words.Who.Text = "This could be you"
		words.Note.Text = "Be the first to find all " .. tostring(all) .. " squirrels in a day and your statue will stand here."
	end
end
local building = false
-- THE FIGURE, made anywhere: o = {x, top, z (its feet go there), parent, name, scale, look (the way it faces)}. Returns the
-- posed marble figure and the gilded acorn in its raised hand. The fountain's statue and every statue in the Hall of
-- Fame at the Chateau (asked for through MakeStatue) come from this one function, so they always match.
local function makeFigure(rec, o)
	local okD, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(rec.uid) end)
	if not okD or not desc then desc = Instance.new("HumanoidDescription") end
	local okM, model = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not okM or not model then
		warn("Champion: could not make the figure: " .. tostring(model))
		return nil
	end
	local FX, TOP, PZ = o.x, o.top, o.z                                     -- (the names the pose code below always used)
	model.Name = o.name or "Figure"
	for _, s in ipairs(model:GetDescendants()) do if s:IsA("BaseScript") then s:Destroy() end end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end
	local scale = o.scale or F:GetAttribute("Scale") or 1.5
	pcall(function() model:ScaleTo(scale) end)
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = (p == root); p.CanCollide = false end end
	local up = Vector3.new(FX, TOP + 30, PZ)
	model:PivotTo(CFrame.lookAt(up, up + (o.look or Vector3.new(0, 0, -1))))   -- the fountain's faces north, toward the fountain
	model.Parent = o.parent or F
	for _ = 1, 6 do RunService.Heartbeat:Wait() end                        -- let the body settle, then freeze it
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	-- One hand holds the acorn up high, the other arm hangs relaxed at the side. The pose is carved rather than
	-- animated: with everything anchored, each arm - and anything worn on it - comes off its joints and is AIMED about
	-- its shoulder (the torso's ShoulderRigAttachment), whatever pose it started in. Avatar rigs come two ways - Motor6D
	-- joints, or the newer AnimationConstraint + BallSocketConstraint pairs - and this works on both (Sep 25: editing
	-- Motor6D joints did nothing on a constraint rig, which is why the first statue kept its arms down).
	local torso = model:FindFirstChild("UpperTorso")
	local function linked(d, moving)
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			return (d.Part0 and moving[d.Part0]) or (d.Part1 and moving[d.Part1])
		elseif d:IsA("Constraint") then
			local a0, a1 = d.Attachment0, d.Attachment1
			return (a0 and moving[a0.Parent]) or (a1 and moving[a1.Parent])
		end
		return false
	end
	local function aim(side, dir, bendDeg)
		local att = torso and torso:FindFirstChild(side .. "ShoulderRigAttachment")
		local hand = model:FindFirstChild(side .. "Hand")
		if not (att and hand and typeof(dir) == "Vector3") then return false end
		local pivot = att.WorldPosition
		local cf = torso.CFrame
		local outward = cf.RightVector * ((side == "Right") and 1 or -1)
		local w = (outward * dir.X + cf.UpVector * dir.Y + cf.LookVector * dir.Z).Unit
		-- the arm's parts, and anything worn on each of them (held on by a weld, or hung from one of their attachments)
		local armParts, owner = {}, {}
		for _, n in ipairs({"UpperArm", "LowerArm", "Hand"}) do local pp = model:FindFirstChild(side .. n); if pp then armParts[pp] = n; owner[pp] = n end end
		for _, acc in ipairs(model:GetChildren()) do
			local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
			if h then
				for _, d in ipairs(h:GetChildren()) do
					if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
						local other = (d.Part0 == h) and d.Part1 or d.Part0
						if other and armParts[other] then owner[h] = armParts[other] end
					end
				end
				local ha = h:FindFirstChildWhichIsA("Attachment")
				if ha and not owner[h] then
					for pp, n in pairs(armParts) do if pp:FindFirstChild(ha.Name) then owner[h] = n end end
				end
			end
		end
		for _, d in ipairs(model:GetDescendants()) do if linked(d, owner) then d:Destroy() end end
		local v = hand.Position - pivot
		local axis = v:Cross(w)
		if axis.Magnitude > 1e-6 then
			local rot = CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(v.Unit:Dot(w), -1, 1)))
			for pp in pairs(owner) do pp.CFrame = (rot * (pp.CFrame - pivot)) + pivot end
		end
		-- a soft bend at the elbow: the forearm and hand swing forward a little (never back)
		local upper = model:FindFirstChild(side .. "UpperArm")
		local elbow = upper and upper:FindFirstChild(side .. "ElbowRigAttachment")
		if bendDeg and bendDeg ~= 0 and elbow then
			local e = elbow.WorldPosition
			local bendAxis = w:Cross(cf.LookVector)
			if bendAxis.Magnitude > 1e-6 then
				local rot = CFrame.fromAxisAngle(bendAxis.Unit, math.rad(bendDeg))
				local rel = hand.Position - e
				if ((rot * rel) - rel):Dot(cf.LookVector) < 0 then rot = CFrame.fromAxisAngle(bendAxis.Unit, -math.rad(bendDeg)) end
				for pp, n in pairs(owner) do if n ~= "UpperArm" then pp.CFrame = (rot * (pp.CFrame - e)) + e end end
			end
		end
		return true
	end
	local holdSide = (F:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
	local freeSide = (holdSide == "Left") and "Right" or "Left"
	local upR = aim(holdSide, F:GetAttribute("HoldArm") or Vector3.new(0.45, 1, 0.15), 0)                           -- the acorn, held up high
	local upL = aim(freeSide, F:GetAttribute("FreeArm") or Vector3.new(0.22, -1, 0.12), F:GetAttribute("FreeBend") or 15)   -- relaxed at the side
	if hum then hum:Destroy() end
	stoneify(model)
	strip(model)
	standOn(model, FX, TOP, PZ)                                        -- on its feet (not on the bottom of its box)
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and p ~= root then p.CanCollide = true end end
	local holding = model:FindFirstChild(holdSide .. "Hand")
	-- the acorn is sized to the sitter (Shannon: "for short or tall avatars will the acorn position correctly too?"): the
	-- same share of their height as on an ordinary avatar, so a baby holds a baby-sized giant acorn and a giant a giant's
	local head = model:FindFirstChild("Head")
	local feet = lowestPoint(model)
	local bodyH = (head and feet < math.huge) and (head.Position.Y + head.Size.Y / 2 - feet) or 5.2 * scale
	local a = giantAcorn(math.clamp(bodyH * 0.385, 1.2, 5), o.parent)
	if a then
		if holding then
			placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z)   -- resting on the raised hand
		else
			local cf, size = model:GetBoundingBox()
			placeOn(a, cf.Position.X, cf.Position.Y + size.Y / 2, cf.Position.Z)
		end
	end
	return model, a, upR, upL
end
local function buildStatue(rec)
	while building do task.wait(0.2) end
	building = true
	for _, n in ipairs({"Figure", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	if not rec then
		local a = giantAcorn(2.6)
		if a then placeOn(a, FX, TOP, PZ) end
		building = false
		return
	end
	local model, _, upR, upL = makeFigure(rec, {x = FX, top = TOP, z = PZ, parent = F, name = "Figure", scale = F:GetAttribute("Scale") or 1.5, look = Vector3.new(0, 0, -1)})
	if not model then local a = giantAcorn(2.6); if a then placeOn(a, FX, TOP, PZ) end end
	building = false
	print(string.format("Champion: the statue of %s (No. %s) stands by the fountain (arms posed %s/%s)", tostring(rec.name), tostring(rec.no), tostring(upR), tostring(upL)))
end

-- the squirrel that stands to attention, looking up at the statue, tail raised in salute. o = {x, y, z (where it stands),
-- tx, tz (the statue it looks up at), parent, name, scale}; the fountain's is built once, the Hall's through MakeSquirrel
local function makeSquirrel(o)
	local want = F:GetAttribute("SaluteSquirrel") or "ranger_squirrel"
	local src
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do if m:GetAttribute("SquirrelId") == want then src = m break end end
	if not src then warn("Champion: no " .. want .. " to stand by the statue") return nil end
	local m = src:Clone(); m.Name = o.name or "Monument"
	strip(m)
	stoneify(m)
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true end end
	pcall(function() m:ScaleTo(m:GetScale() * (o.scale or F:GetAttribute("SquirrelScale") or 1.7)) end)
	m.Parent = o.parent or F
	local bones = {}
	for _, b in ipairs(m:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local spot = Vector3.new(o.x, o.y, o.z)
	local FX, PZ = o.tx, o.tz
	if bones.Root and bones.Head then
		-- which way it faces: root -> head, flattened (the rule SquirrelAnim uses); turn it to face the statue
		local f = bones.Head.WorldPosition - bones.Root.WorldPosition
		f = Vector3.new(f.X, 0, f.Z)
		local to = Vector3.new(FX - spot.X, 0, PZ - spot.Z)
		if f.Magnitude > 0.01 and to.Magnitude > 0.01 then
			local pivot = m:GetPivot()
			m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.atan2(to.X, to.Z) - math.atan2(f.X, f.Z), 0) * pivot.Rotation)
		end
		local fw = bones.Head.WorldPosition - bones.Root.WorldPosition
		fw = Vector3.new(fw.X, 0, fw.Z)
		if fw.Magnitude > 0.01 then
			local left = Vector3.yAxis:Cross(fw.Unit)
			local function tilt(b, deg)
				if not b or not deg or deg == 0 then return end
				local axis = b.WorldCFrame:VectorToObjectSpace(left)
				b.CFrame = b.CFrame * CFrame.fromAxisAngle(axis, math.rad(deg))
			end
			tilt(bones.Chest, F:GetAttribute("ChestTilt"))
			tilt(bones.Head, F:GetAttribute("HeadTilt"))
			tilt(bones.Tail1, F:GetAttribute("TailTilt"))
		end
	end
	placeOn(m, spot.X, spot.Y, spot.Z)
	return m
end
local function buildSquirrel()
	if F:FindFirstChild("Monument") then return end
	makeSquirrel({x = F:GetAttribute("SquirrelX"), y = F:GetAttribute("SquirrelY"), z = F:GetAttribute("SquirrelZ"), tx = FX, tz = PZ, parent = F, name = "Monument"})
end

-- ---- claiming the day ----
local localClaims = {}
local function claim(rec)
	if STUDIO or not store then
		if localClaims[rec.day] then return false, localClaims[rec.day] end
		localClaims[rec.day] = rec
		return true
	end
	for attempt = 1, 3 do
		local won, holder = false, nil
		local ok = pcall(function()
			store:UpdateAsync("day_" .. tostring(rec.day), function(oldRec)
				if oldRec ~= nil then won = false; holder = oldRec; return nil end
				won = true; holder = nil
				return rec
			end)
		end)
		if ok then return won, holder end
		task.wait(2 * attempt)
	end
	return false, nil
end
local function saveLatest(rec)
	if STUDIO or not store then return end
	pcall(function()
		store:UpdateAsync("latest", function(oldRec)
			if type(oldRec) == "table" and (oldRec.day or 0) > rec.day then return nil end
			return rec
		end)
	end)
end
-- the Roblox badge: on the win, and on joining for anyone who won before the badge existed (live servers only)
local BadgeService = game:GetService("BadgeService")
local function giveBadge(player)
	local id = tonumber(F:GetAttribute("Badge_champion")) or 0
	if id <= 0 or STUDIO then return end
	task.spawn(function()
		local okH, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, id) end)
		if okH and not has then
			local ok, err = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)            -- the current name
			if not ok then ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, id) end) end    -- the older one
			if not ok then warn("Champion: badge award failed: " .. tostring(err)) end
		end
	end)
end

-- ---- the hall: every Grand Keeper in order, 1st, 2nd, 3rd ... (what the Hall of Fame at the Chateau shows) ----
local hall, hallLoaded = {}, false
local function sortHall() table.sort(hall, function(a, b) return (tonumber(a.no) or 0) < (tonumber(b.no) or 0) end) end
local function hallFind(uid)                                         -- the player's latest win
	local best
	for _, e in ipairs(hall) do if e.uid == uid and (not best or e.no > best.no) then best = e end end
	return best
end
local function hallWins(uid) local n = 0; for _, e in ipairs(hall) do if e.uid == uid then n += 1 end end; return n end
local function hallHas(uid, total)                                   -- already won with this many squirrels (or more)?
	for _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end
	return false
end
-- every player's screen gets the list (for the Hall of Fame at the Chateau): HallJson on this folder, in order
local HttpService = game:GetService("HttpService")
local function publishHall()
	local out = {}
	for _, e in ipairs(hall) do table.insert(out, {no = e.no, uid = e.uid, name = e.name, day = e.day, total = e.total}) end
	local ok, s = pcall(function() return HttpService:JSONEncode(out) end)
	if ok then F:SetAttribute("HallJson", s) end
end
local function hallMerge(e)                                          -- an entry this server heard about: kept in order, never twice
	if type(e) ~= "table" or not e.no then return end
	for _, x in ipairs(hall) do if x.no == e.no then return end end
	table.insert(hall, {no = e.no, uid = e.uid, name = e.name, user = e.user, day = e.day, t = e.t, total = e.total})
	sortHall()
	publishHall()
end
-- a day's winner takes the next number: atomic across servers, and safe to repeat (one uid + day is never added twice)
local function hallAppend(rec)
	local function entryFor(list)
		for _, x in ipairs(list) do if x.uid == rec.uid and x.day == rec.day then return x, false end end
		local top = 0
		for _, x in ipairs(list) do top = math.max(top, tonumber(x.no) or 0) end
		return {no = top + 1, uid = rec.uid, name = rec.name, user = rec.user, day = rec.day, t = rec.t, total = rec.total or 44}, true
	end
	if STUDIO or not store then
		local e, new = entryFor(hall)
		if new then table.insert(hall, e); sortHall(); publishHall() end
		return e
	end
	for attempt = 1, 4 do
		local mine
		local ok, final = pcall(function()
			return store:UpdateAsync("hall", function(old)
				local list = (type(old) == "table" and type(old.list) == "table") and old.list or {}
				local e, new = entryFor(list)
				mine = e
				if not new then return nil end
				table.insert(list, e)
				return {list = list}
			end)
		end)
		if ok and mine then
			if type(final) == "table" and type(final.list) == "table" then hall = final.list; sortHall() end
			hallMerge(mine)
			publishHall()
			return mine
		end
		task.wait(2 * attempt)
	end
	warn("Champion: could not save the hall number for " .. tostring(rec.name) .. " - the next server start mends it")
	return nil
end
-- on start: read the hall, then make sure every day winner of the last fortnight is in it (the first time, every day from
-- LaunchDay: that is how the Day winners from before the numbering got their numbers, in the order they won)
local function loadHall()
	if STUDIO or not store then publishHall(); hallLoaded = true; return end
	local got = false
	for attempt = 1, 5 do
		local ok, v = pcall(function() return store:GetAsync("hall") end)
		if ok then
			hall = (type(v) == "table" and type(v.list) == "table") and v.list or {}
			sortHall()
			got = true
			break
		end
		task.wait(2 * attempt)
	end
	if got then
		local launch = F:GetAttribute("LaunchDay") or 20721
		local from = (#hall == 0) and launch or math.max(launch, today() - 14)
		local added = 0
		for d = from, today() do
			local ok, rec = pcall(function() return store:GetAsync("day_" .. tostring(d)) end)
			if ok and type(rec) == "table" and rec.uid then
				rec.day = rec.day or d
				local known = false
				for _, x in ipairs(hall) do if x.uid == rec.uid and x.day == rec.day then known = true end end
				if not known and hallAppend(rec) then added += 1 end
			end
		end
		print(string.format("Champion: the hall has %d keepers (%d added from the day records)", #hall, added))
	end
	publishHall()
	hallLoaded = true
end
task.spawn(loadHall)
-- the title and the numbers the badge case shows, all from the hall (nothing new in the save)
local function applyTitle(player)
	local e = hallFind(player.UserId)
	if e then
		player:SetAttribute("ChampionNo", e.no)
		player:SetAttribute("ChampionDay", e.day)
		player:SetAttribute("ChampionTotal", tonumber(e.total) or 44)
		player:SetAttribute("ChampionWins", hallWins(player.UserId))
		player:SetAttribute("ChampionTitle", titleFor(e.no))
		giveBadge(player)
	elseif item(player, "champion_day") > 0 then                        -- a Keeper the hall has not got (the store was down)
		player:SetAttribute("ChampionTitle", "Grand Keeper of the Great Acorn")
		giveBadge(player)
	end
end

local celebrated = {}
local function celebrate(rec)
	if type(rec) ~= "table" or not rec.day or celebrated[rec.day] then return end
	celebrated[rec.day] = true
	hallMerge(rec)
	ev:FireAllClients("crowned", rec)
	task.spawn(buildStatue, rec)
end
local function crown(player)
	local day = today()
	local launch = F:GetAttribute("LaunchDay") or 20721
	if day < launch and not STUDIO then return end
	local t0 = os.clock()
	while not hallLoaded and os.clock() - t0 < 60 do task.wait(0.5) end
	local total = totalSquirrels()
	if hallHas(player.UserId, total) then                              -- a Keeper already, for this many squirrels
		local e = hallFind(player.UserId)
		ev:FireClient(player, "already", e and e.no or 0, total)
		return
	end
	local n = math.max(1, day - launch + 1)
	local rec = {day = day, n = n, uid = player.UserId, name = player.DisplayName, user = player.Name, t = os.time(), total = total}
	local won, holder = claim(rec)
	if not won then
		if holder and holder.name then ev:FireClient(player, "late", holder.name, holder.n, total) end
		return
	end
	local e = hallAppend(rec)
	rec.no = e and e.no or nil
	if item(player, "champion_day") <= 0 then setItem(player, "champion_day", n) end   -- (the first day won, kept as before)
	awardItems:Fire(player, "champion_wins", 1)                          -- the days won
	player:SetAttribute("ChampionNew", true)                            -- the badge case says "new badge" only for this
	applyTitle(player)
	print(string.format("Champion: %s is the %s Grand Keeper (day %d)", player.Name, rec.no and ordinal(rec.no) or "?", day))
	saveLatest(rec)
	celebrate(rec)
	if not STUDIO then pcall(function() MS:PublishAsync(TOPIC, rec) end) end
end
if not STUDIO then
	pcall(function() MS:SubscribeAsync(TOPIC, function(msg) celebrate(msg.Data) end) end)
end

-- ---- watching every player's finds ----
local function watch(player)
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 20 do task.wait(0.25) end
		task.wait(2)                                           -- the saved count lands just after SaveLoaded
		while player.Parent and not hallLoaded and os.clock() - t0 < 80 do task.wait(0.5) end
		if not player.Parent then return end
		applyTitle(player)
		local last = tonumber(player:GetAttribute("SquirrelsFound")) or 0
		player:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
			local now = tonumber(player:GetAttribute("SquirrelsFound")) or 0
			local total = totalSquirrels()
			if total > 0 and now >= total and last < total then task.spawn(crown, player) end
			last = now
		end)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- on start: the newest Keeper (or the empty plinth), and the squirrel ----
task.spawn(function()
	local t0 = os.clock()
	while totalSquirrels() == 0 and os.clock() - t0 < 30 do task.wait(0.5) end
	buildSquirrel()
	while not hallLoaded and os.clock() - t0 < 90 do task.wait(0.5) end
	local latest = hall[#hall]
	if not latest and not STUDIO and store then                         -- (the hall could not be read: the last one saved)
		local ok, rec = pcall(function() return store:GetAsync("latest") end)
		if ok and type(rec) == "table" then latest = rec end
	end
	if latest and latest.day then celebrated[latest.day] = true end
	buildStatue(latest)
end)
-- for the Hall of Fame at the Chateau (its HallServer): the same statue and the same saluting squirrel, made where it asks
local mk = Instance.new("BindableFunction"); mk.Name = "MakeStatue"; mk.Parent = F
mk.OnInvoke = function(rec, o) return makeFigure(rec, o) end
local msq = Instance.new("BindableFunction"); msq.Name = "MakeSquirrel"; msq.Parent = F
msq.OnInvoke = function(o) return makeSquirrel(o) end
if STUDIO then
	-- (a hall full of Keepers to look at: HallDebug:Invoke({{uid = ..., name = ...}, ...}) adds them, a day apart)
	local hd = Instance.new("BindableFunction"); hd.Name = "HallDebug"; hd.Parent = F
	hd.OnInvoke = function(list)
		for _, e in ipairs(list) do
			local day = (hall[#hall] and hall[#hall].day or (today() - 20)) + 1
			hallAppend({uid = e.uid, name = e.name, user = e.name, day = day, t = os.time(), total = e.total or 44})
		end
		return #hall
	end
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ChampionDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) crown(player); return player:GetAttribute("ChampionTitle") end
	-- (a statue of anyone, to check a body shape: StatueDebug:Invoke(userId, name) -> where the feet ended up)
	local sdbg = Instance.new("BindableFunction"); sdbg.Name = "StatueDebug"; sdbg.Parent = F
	sdbg.OnInvoke = function(uid, name)
		buildStatue({uid = uid, name = name or "Test", n = 0, day = 20721})
		local fig = F:FindFirstChild("Figure")
		if not fig then return "no figure" end
		local cf, size = fig:GetBoundingBox()
		return string.format("feet %.2f | plinth top %.2f | box bottom %.2f | height %.1f", lowestPoint(fig), TOP, cf.Position.Y - size.Y / 2, size.Y)
	end
end
print("Champion: ready")
]====]})
table.insert(changes,{target=workspace.Chapel.ChapelServer,source=[====[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local F = script.Parent
local ev = F:WaitForChild("ChapelEvent")
local room = F:WaitForChild("Room")
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out through the walls: a short zoom leash, given back at the door (or on respawn)
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = F:GetAttribute("InsideZoom") or 18
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player) player.CharacterAdded:Connect(function() leash(player, false) end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)

-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if hum and hum.SeatPart then hum.Sit = false end
			local p = toInside and v3("In") or v3("Out")
			local look = toInside and Vector3.new(F:GetAttribute("InLookX"), 0, F:GetAttribute("InLookZ")) or Vector3.new(F:GetAttribute("OutLookX"), 0, F:GetAttribute("OutLookZ"))
			char:PivotTo(CFrame.lookAt(p, p + look))
			char:SetAttribute("InChapel", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end

-- the votive candles: each prompt lights the next dark one, for everyone, for CandleSeconds
local votive = room:WaitForChild("Votive")
local flames = {}
for _, d in ipairs(votive:GetChildren()) do if d.Name:match("^VotiveFlame") then flames[#flames + 1] = d end end
table.sort(flames, function(a, b) return tonumber(a.Name:match("%d+")) < tonumber(b.Name:match("%d+")) end)
local litUntil = {}
local function setLit(fl, on)
	fl.Transparency = on and 0 or 1
	local l = fl:FindFirstChildOfClass("PointLight"); if l then l.Enabled = on end
end
local function lightOne(player)
	local now = os.clock()
	local pick
	for _, fl in ipairs(flames) do if (litUntil[fl] or 0) < now then pick = fl break end end
	if not pick then                                                   -- all lit: the one that has burned longest is renewed
		for _, fl in ipairs(flames) do if not pick or litUntil[fl] < litUntil[pick] then pick = fl end end
	end
	local secs = F:GetAttribute("CandleSeconds") or 120
	litUntil[pick] = now + secs
	setLit(pick, true)
	ev:FireClient(player, "candle")
	task.delay(secs + 0.1, function() if (litUntil[pick] or 0) <= os.clock() then setLit(pick, false) end end)
end

-- the bell: out of the belfry for everyone near the chapel, and in here; the rope gives
local bellAt = 0
local rope = room:WaitForChild("BellRope")
local function ring(player)
	if os.clock() - bellAt < 4 then return end
	bellAt = os.clock()
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"church",{}) end
	local id, vol = F:GetAttribute("BellSound") or "rbxassetid://9113804436", F:GetAttribute("BellVolume") or 0.8
	for _, where in ipairs({F:FindFirstChild("BellVoice"), rope:FindFirstChild("Hole")}) do
		if where then
			local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = where.Name == "BellVoice" and 260 or 80
			s.RollOffMinDistance = 12; s.Parent = where; s:Play()
			game:GetService("Debris"):AddItem(s, 12)
		end
	end
	-- the rope and its sally go down a stud and a half and come back
	local parts = {}
	for _, p in ipairs(rope:GetChildren()) do if p:IsA("BasePart") and p.Name ~= "Hole" and p.Name ~= "RopePad" then parts[#parts + 1] = p end end
	for _, p in ipairs(parts) do
		local home = p:GetAttribute("Home") or p.CFrame
		p:SetAttribute("Home", home)
		local tw = TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {CFrame = home * CFrame.new(0, -1.5, 0)})
		tw:Play()
	end
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "CandlePrompt" then lightOne(player)
	elseif prompt.Name == "BellPrompt" then ring(player)
	end
end)
print("ChapelServer: ready")
]====],before=[====[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local F = script.Parent
local ev = F:WaitForChild("ChapelEvent")
local room = F:WaitForChild("Room")
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out through the walls: a short zoom leash, given back at the door (or on respawn)
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = F:GetAttribute("InsideZoom") or 18
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player) player.CharacterAdded:Connect(function() leash(player, false) end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)

-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if hum and hum.SeatPart then hum.Sit = false end
			local p = toInside and v3("In") or v3("Out")
			local look = toInside and Vector3.new(F:GetAttribute("InLookX"), 0, F:GetAttribute("InLookZ")) or Vector3.new(F:GetAttribute("OutLookX"), 0, F:GetAttribute("OutLookZ"))
			char:PivotTo(CFrame.lookAt(p, p + look))
			char:SetAttribute("InChapel", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end

-- the votive candles: each prompt lights the next dark one, for everyone, for CandleSeconds
local votive = room:WaitForChild("Votive")
local flames = {}
for _, d in ipairs(votive:GetChildren()) do if d.Name:match("^VotiveFlame") then flames[#flames + 1] = d end end
table.sort(flames, function(a, b) return tonumber(a.Name:match("%d+")) < tonumber(b.Name:match("%d+")) end)
local litUntil = {}
local function setLit(fl, on)
	fl.Transparency = on and 0 or 1
	local l = fl:FindFirstChildOfClass("PointLight"); if l then l.Enabled = on end
end
local function lightOne(player)
	local now = os.clock()
	local pick
	for _, fl in ipairs(flames) do if (litUntil[fl] or 0) < now then pick = fl break end end
	if not pick then                                                   -- all lit: the one that has burned longest is renewed
		for _, fl in ipairs(flames) do if not pick or litUntil[fl] < litUntil[pick] then pick = fl end end
	end
	local secs = F:GetAttribute("CandleSeconds") or 120
	litUntil[pick] = now + secs
	setLit(pick, true)
	ev:FireClient(player, "candle")
	task.delay(secs + 0.1, function() if (litUntil[pick] or 0) <= os.clock() then setLit(pick, false) end end)
end

-- the bell: out of the belfry for everyone near the chapel, and in here; the rope gives
local bellAt = 0
local rope = room:WaitForChild("BellRope")
local function ring(player)
	if os.clock() - bellAt < 4 then return end
	bellAt = os.clock()
	local id, vol = F:GetAttribute("BellSound") or "rbxassetid://9113804436", F:GetAttribute("BellVolume") or 0.8
	for _, where in ipairs({F:FindFirstChild("BellVoice"), rope:FindFirstChild("Hole")}) do
		if where then
			local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = where.Name == "BellVoice" and 260 or 80
			s.RollOffMinDistance = 12; s.Parent = where; s:Play()
			game:GetService("Debris"):AddItem(s, 12)
		end
	end
	-- the rope and its sally go down a stud and a half and come back
	local parts = {}
	for _, p in ipairs(rope:GetChildren()) do if p:IsA("BasePart") and p.Name ~= "Hole" and p.Name ~= "RopePad" then parts[#parts + 1] = p end end
	for _, p in ipairs(parts) do
		local home = p:GetAttribute("Home") or p.CFrame
		p:SetAttribute("Home", home)
		local tw = TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {CFrame = home * CFrame.new(0, -1.5, 0)})
		tw:Play()
	end
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "CandlePrompt" then lightOne(player)
	elseif prompt.Name == "BellPrompt" then ring(player)
	end
end)
print("ChapelServer: ready")
]====]})
table.insert(changes,{target=workspace.Daily.DailyServer,source=[====[local Players = game:GetService("Players")
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
]====],before=[====[local Players = game:GetService("Players")
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
local function goldFound(player)
	local day = today()
	if item(player, "daily_gold") == day then return end
	setItem(player, "daily_gold", day)
	local r = F:GetAttribute("GoldReward") or 30
	giveAcorns(player, r)
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
]====]})
table.insert(changes,{target=workspace.Domaine.DomaineLife,source=[====[-- DomaineLife (server): the two prompts. It only records what happened as attributes; every client animates from them.
local domaine = script.Parent
local props = domaine:WaitForChild("Props")

local bin = props:FindFirstChild("FeedBin")
local binPrompt = bin and bin:FindFirstChildOfClass("ProximityPrompt")
if binPrompt then
	binPrompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		domaine:SetAttribute("FeedBy", player.UserId)
		domaine:SetAttribute("FeedAt", hrp.Position - Vector3.new(0, 2.6, 0) + hrp.CFrame.LookVector * 2.5)
		domaine:SetAttribute("FeedUntil", workspace:GetServerTimeNow() + 30)
		local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"chickens",{}) end
	end)
end

for _, m in ipairs(props:GetChildren()) do
	if m.Name == "trough" then
		local handle = m:FindFirstChild("Handle")
		local prompt = handle and handle:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			local busyUntil = 0
			prompt.Triggered:Connect(function()
				local now = workspace:GetServerTimeNow()
				if now < busyUntil then return end
				busyUntil = now + 3
				m:SetAttribute("PumpAt", now)
			end)
		end
	end
end
]====],before=[====[-- DomaineLife (server): the two prompts. It only records what happened as attributes; every client animates from them.
local domaine = script.Parent
local props = domaine:WaitForChild("Props")

local bin = props:FindFirstChild("FeedBin")
local binPrompt = bin and bin:FindFirstChildOfClass("ProximityPrompt")
if binPrompt then
	binPrompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		domaine:SetAttribute("FeedBy", player.UserId)
		domaine:SetAttribute("FeedAt", hrp.Position - Vector3.new(0, 2.6, 0) + hrp.CFrame.LookVector * 2.5)
		domaine:SetAttribute("FeedUntil", workspace:GetServerTimeNow() + 30)
	end)
end

for _, m in ipairs(props:GetChildren()) do
	if m.Name == "trough" then
		local handle = m:FindFirstChild("Handle")
		local prompt = handle and handle:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			local busyUntil = 0
			prompt.Triggered:Connect(function()
				local now = workspace:GetServerTimeNow()
				if now < busyUntil then return end
				busyUntil = now + 3
				m:SetAttribute("PumpAt", now)
			end)
		end
	end
end
]====]})
table.insert(changes,{target=workspace.ForestRace.RaceServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("RaceEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local MAP = F:GetAttribute("Map") or "forest"
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local isRace = {}
for _, e in ipairs(Registry.squirrels) do if e.map == MAP then isRace[e.id] = true end end

local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- which squirrels are in the race, and hearing their clicks ----
local races = {}                                            -- player -> {phase, found, n, total, t0}
local ids, total = {}, 0
local hooked = setmetatable({}, {__mode = "k"})
local finish
local function stop(player, why)
	if not races[player] then return end
	races[player] = nil
	player:SetAttribute("Racing", nil)
	ev:FireClient(player, "stop", why)
end
local function onClick(player, id)
	local r = races[player]
	if not r or r.phase ~= "run" or r.found[id] then return end
	r.found[id] = true; r.n += 1
	ev:FireClient(player, "tick", id, r.n, r.total, os.clock() - r.t0)
	if r.n >= r.total then finish(player) end
end
local function scan()
	local list, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and isRace[id] and not list[id] then
			list[id] = true; n += 1
   for _,part in ipairs(m:GetDescendants()) do
    if part:IsA("BasePart") and not hooked[part] then
     hooked[part]=true;part.CanTouch=true
     part.Touched:Connect(function(hit)
      local char=hit:FindFirstAncestorOfClass("Model");local player=char and Players:GetPlayerFromCharacter(char)
      if player then onClick(player,id) end
     end)
    end
   end
			for _, cd in ipairs(m:GetDescendants()) do
				if cd:IsA("ClickDetector") and not hooked[cd] then
					hooked[cd] = true
					cd.MouseClick:Connect(function(player) onClick(player, id) end)
				end
			end
		end
	end
	ids, total = list, n
	F:SetAttribute("Total", n)
end
task.spawn(function() while true do scan(); task.wait(total == 0 and 1 or 8) end end)

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "ForestRace_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("RaceBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}     -- gold, silver, bronze
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil                                   -- no empty stripes
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a squirrel finder"
			end
		end
	end
 local ranks={};for i,e in ipairs(list) do if i<=10 then ranks[e.uid]=i end end
 for _,p in ipairs(Players:GetPlayers()) do
  local scope=ok and "global" or (RunService:IsStudio() and "server" or "unavailable")
  p:SetAttribute("PassportBoard_race",game:GetService("HttpService"):JSONEncode({rank=scope~="unavailable" and (ranks[p.UserId] or 0) or 0,scope=scope,checked=workspace:GetServerTimeNow()}))
 end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end         -- the board keeps a player's fastest
				return cs
			end)
		end)
		if not ok then warn("ForestRace: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a race ----
local function idList() local t = {} for id in pairs(ids) do t[#t + 1] = id end return t end
local function start(player)
	if races[player] or total == 0 or not player:GetAttribute("SaveLoaded") then return end
	local r = {phase = "count", found = {}, n = 0, total = total}
	races[player] = r
	player:SetAttribute("Racing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, r.total, idList(), item(player, "race_best"))
	task.delay(cd, function()
		if races[player] ~= r then return end
		r.phase = "run"; r.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 20) * 60, function() if races[player] == r then stop(player, "time") end end)
	end)
end
finish = function(player)
	local r = races[player]
	if not r then return end
	local secs = os.clock() - r.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	races[player] = nil
	player:SetAttribute("Racing", nil)
	local best = item(player, "race_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "race_best", cs) end
	-- a few acorns for beating your own best (Shannon: "a few acorns if you beat your best time ok"); not for a time too
	-- quick to be real (the same MinSeconds that keeps it off the board)
	local prize = 0
	if isBest and secs >= (F:GetAttribute("MinSeconds") or 45) then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player,"race",{cs=cs,previousBest=best,improvement=best>cs and best-cs or 0,prize=prize,boardReady=false}) end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("ForestRace: %s ran the forest in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= (F:GetAttribute("MinSeconds") or 45) then
		task.spawn(submit, player, isBest and cs or best)
	else
		player:SetAttribute("PassportBoard_race",game:GetService("HttpService"):JSONEncode({rank=0,scope="unavailable",time=workspace:GetServerTimeNow()}))
		warn(string.format("ForestRace: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not races[player] then
		local char = player.Character
		local p = Vector3.new(F:GetAttribute("StartX"), F:GetAttribute("StartY"), F:GetAttribute("StartZ"))
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(1, 0, 0))) end
		task.wait(0.3)
		start(player)
	end
end)
Players.PlayerRemoving:Connect(function(p) races[p] = nil end)
if RunService:IsStudio() then                               -- Studio only: count n more squirrels as found, as if clicked
	local dbg = Instance.new("BindableFunction"); dbg.Name = "RaceDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player, n)
		local r = races[player]
		if not r or r.phase ~= "run" then return "not racing" end
		local k = 0
		for id in pairs(ids) do
			if k >= n then break end
			if not r.found[id] then k += 1; onClick(player, id) end
		end
		return tostring(r.n) .. "/" .. tostring(r.total)
	end
end
print("ForestRace: ready")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("RaceEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local MAP = F:GetAttribute("Map") or "forest"
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local isRace = {}
for _, e in ipairs(Registry.squirrels) do if e.map == MAP then isRace[e.id] = true end end

local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- which squirrels are in the race, and hearing their clicks ----
local races = {}                                            -- player -> {phase, found, n, total, t0}
local ids, total = {}, 0
local hooked = setmetatable({}, {__mode = "k"})
local finish
local function stop(player, why)
	if not races[player] then return end
	races[player] = nil
	player:SetAttribute("Racing", nil)
	ev:FireClient(player, "stop", why)
end
local function onClick(player, id)
	local r = races[player]
	if not r or r.phase ~= "run" or r.found[id] then return end
	r.found[id] = true; r.n += 1
	ev:FireClient(player, "tick", id, r.n, r.total, os.clock() - r.t0)
	if r.n >= r.total then finish(player) end
end
local function scan()
	local list, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and isRace[id] and not list[id] then
			list[id] = true; n += 1
			for _, cd in ipairs(m:GetDescendants()) do
				if cd:IsA("ClickDetector") and not hooked[cd] then
					hooked[cd] = true
					cd.MouseClick:Connect(function(player) onClick(player, id) end)
				end
			end
		end
	end
	ids, total = list, n
	F:SetAttribute("Total", n)
end
task.spawn(function() while true do scan(); task.wait(total == 0 and 1 or 8) end end)

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "ForestRace_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("RaceBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}     -- gold, silver, bronze
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil                                   -- no empty stripes
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a squirrel finder"
			end
		end
	end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end         -- the board keeps a player's fastest
				return cs
			end)
		end)
		if not ok then warn("ForestRace: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a race ----
local function idList() local t = {} for id in pairs(ids) do t[#t + 1] = id end return t end
local function start(player)
	if races[player] or total == 0 or not player:GetAttribute("SaveLoaded") then return end
	local r = {phase = "count", found = {}, n = 0, total = total}
	races[player] = r
	player:SetAttribute("Racing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, r.total, idList(), item(player, "race_best"))
	task.delay(cd, function()
		if races[player] ~= r then return end
		r.phase = "run"; r.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 20) * 60, function() if races[player] == r then stop(player, "time") end end)
	end)
end
finish = function(player)
	local r = races[player]
	if not r then return end
	local secs = os.clock() - r.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	races[player] = nil
	player:SetAttribute("Racing", nil)
	local best = item(player, "race_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "race_best", cs) end
	-- a few acorns for beating your own best (Shannon: "a few acorns if you beat your best time ok"); not for a time too
	-- quick to be real (the same MinSeconds that keeps it off the board)
	local prize = 0
	if isBest and secs >= (F:GetAttribute("MinSeconds") or 45) then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "race") end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("ForestRace: %s ran the forest in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= (F:GetAttribute("MinSeconds") or 45) then
		if isBest then task.spawn(submit, player, cs) end
	else
		warn(string.format("ForestRace: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not races[player] then
		local char = player.Character
		local p = Vector3.new(F:GetAttribute("StartX"), F:GetAttribute("StartY"), F:GetAttribute("StartZ"))
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(1, 0, 0))) end
		task.wait(0.3)
		start(player)
	end
end)
Players.PlayerRemoving:Connect(function(p) races[p] = nil end)
if RunService:IsStudio() then                               -- Studio only: count n more squirrels as found, as if clicked
	local dbg = Instance.new("BindableFunction"); dbg.Name = "RaceDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player, n)
		local r = races[player]
		if not r or r.phase ~= "run" then return "not racing" end
		local k = 0
		for id in pairs(ids) do
			if k >= n then break end
			if not r.found[id] then k += 1; onClick(player, id) end
		end
		return tostring(r.n) .. "/" .. tostring(r.total)
	end
end
print("ForestRace: ready")
]====]})
table.insert(changes,{target=workspace.Glaces.GlaceServer,source=[====[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local F = script.Parent
local ev = F:WaitForChild("GlaceEvent")
local C = Color3.fromRGB
local FLAVOURS = {{"Lavande", C(186, 160, 222)}, {"Pistache", C(170, 210, 130)}, {"Fraise", C(245, 150, 170)},
	{"Chocolat", C(125, 78, 52)}, {"Citron", C(250, 232, 120)}, {"Vanille", C(252, 244, 220)}}
local WAFFLE, WAFFLE2 = C(214, 166, 96), C(190, 140, 78)
local UP = CFrame.Angles(0, 0, math.rad(90))
local MYSTERE = "Myst" .. utf8.char(232) .. "re"
local SPRINKLES = {C(255, 90, 110), C(255, 200, 60), C(90, 200, 120), C(90, 160, 255), C(200, 110, 230), C(255, 140, 60)}

local function sound(key, parent)
	local id = tonumber(F:GetAttribute(key)) or 0
	if id <= 0 or not parent then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = 0.7
	s.RollOffMinDistance = 8; s.RollOffMaxDistance = 60; s.Parent = parent; s:Play()
	Debris:AddItem(s, 7)
	return s
end

local function piece(name, size, colour, shape, handle, offset, tool)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = colour; p.Material = Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("Weld"); w.Part0 = handle; w.Part1 = p; w.C0 = offset; w.Parent = p
	p.Parent = tool
	return p, w
end

-- the cone: five waffle rings narrowing to a point, the Handle an invisible block at the rim; scoops of 0.56
-- stacked on top, each on its own weld so a lick can shrink it and settle it back down on the one below
local function makeCone(n)
	local tool = Instance.new("Tool"); tool.Name = "Ice Cream"; tool.CanBeDropped = false; tool.RequiresHandle = true
	tool.ToolTip = "Tap to lick!"
	local gx, gy, gz = F:GetAttribute("GripX") or 0, F:GetAttribute("GripY") or 0, F:GetAttribute("GripZ") or 0
	tool.Grip = CFrame.Angles(math.rad(gx), math.rad(gy), math.rad(gz))
	local h = Instance.new("Part"); h.Name = "Handle"; h.Size = Vector3.new(0.3, 0.3, 0.3); h.Transparency = 1
	h.CanCollide = false; h.CanQuery = false; h.CanTouch = false; h.Massless = true; h.CFrame = CFrame.new(0, 100, 0); h.Parent = tool
	for i, r in ipairs({0.07, 0.12, 0.17, 0.22, 0.27}) do
		piece("Cone", Vector3.new(0.14, r * 2, r * 2), (i % 2 == 0) and WAFFLE2 or WAFFLE, Enum.PartType.Cylinder, h,
			CFrame.new(0, -0.62 + i * 0.13, 0) * UP, tool)
	end
	local scoops, names, mystery = {}, {}, false
	for i = 1, n do
		-- the secret flavour: now and then one scoop is the Mystere - white, with rainbow sprinkles - just for the surprise
		local secret = not mystery and math.random() < (F:GetAttribute("MysteryChance") or 0.12)
		local f = secret and {MYSTERE, C(252, 244, 250)} or FLAVOURS[math.random(#FLAVOURS)]
		local p, w = piece("Scoop", Vector3.new(0.56, 0.56, 0.56), f[2], Enum.PartType.Ball, h, CFrame.new(0, 0.28 + (i - 1) * 0.42, 0), tool)
		if secret then
			mystery = true
			for k = 1, 9 do                                      -- sprinkles, riding on the scoop (and gone with it)
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.1, math.random() - 0.5).Unit
				local s = Instance.new("Part"); s.Name = "Sprinkle"; s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(0.1, 0.1, 0.1)
				s.Color = SPRINKLES[(k - 1) % #SPRINKLES + 1]; s.Material = Enum.Material.SmoothPlastic
				s.CanCollide = false; s.CanQuery = false; s.CanTouch = false; s.Massless = true; s.CFrame = p.CFrame * CFrame.new(dir * 0.28)
				local sw = Instance.new("Weld"); sw.Name = "SprinkleWeld"; sw.Part0 = p; sw.Part1 = s; sw.C0 = CFrame.new(dir * 0.28); sw.Parent = s
				s.Parent = p
			end
		end
		scoops[i] = {part = p, weld = w, licks = 0}
		if not table.find(names, f[1]) then names[#names + 1] = f[1] end
	end
	return tool, scoops, names, mystery
end

local holding = {}                                   -- player -> the tool they are holding
local function brainFreeze(player, char, names)
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local a = Instance.new("Attachment"); a.Parent = head
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255), Color3.fromRGB(150, 210, 255)); pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}); pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(3, 7); pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.Parent = a
	pe:Emit(40)
	Debris:AddItem(a, 2)
	local bb = Instance.new("BillboardGui"); bb.Name = "BrainFreeze"; bb.Size = UDim2.fromOffset(220, 54); bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true; bb.MaxDistance = 70; bb.Adornee = head
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.FredokaOne
	t.TextScaled = true; t.Text = "BRAIN FREEZE!"; t.TextColor3 = Color3.fromRGB(150, 215, 255); t.TextStrokeTransparency = 0
	t.TextStrokeColor3 = Color3.fromRGB(255, 255, 255); t.Parent = bb
	bb.Parent = head
	Debris:AddItem(bb, 2.2)
	sound("FreezeSound", head)
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "glace",{flavours=table.concat(names or {},", ")}) end
	ev:FireClient(player, "freeze")
end

local function give(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	if holding[player] and holding[player].Parent then holding[player]:Destroy() end
	local roll = math.random()
	local tool, scoops, names, mystery = makeCone(roll < 0.3 and 1 or (roll < 0.75 and 2 or 3))
	holding[player] = tool
	local busy = false
	-- one lick sound at a time: Shannon's lick runs 4.7 s and taps can come every 0.2 s, so each new lick stops the last,
	-- and the brain freeze stops the final one just after it starts
	local lickSnd
	local function hush() if lickSnd then lickSnd:Stop(); lickSnd:Destroy(); lickSnd = nil end end
	tool.Activated:Connect(function()
		if busy then return end
		busy = true
		-- the arm brings the cone up to the mouth on every screen (GlaceClient), and the lick lands when it gets there
		ev:FireAllClients("lick", player, tool)
		task.wait(0.3)
		local top = scoops[#scoops]
		if top then
			top.licks += 1
			local per = F:GetAttribute("Licks") or 2
			hush(); lickSnd = sound("LickSound", tool:FindFirstChild("Handle"))
			if top.licks >= per then
				top.part:Destroy(); scoops[#scoops] = nil
			else
				local s = 0.56 * (1 - top.licks / (per + 0.6))       -- a lick smaller, its bottom where it was: still on the one below
				top.part.Size = Vector3.new(s, s, s)
				top.weld.C0 = CFrame.new(0, 0.28 + (#scoops - 1) * 0.42 - (0.56 - s) / 2, 0)
				for _, sp in ipairs(top.part:GetChildren()) do          -- the sprinkles stay on the surface
					local sw = sp:FindFirstChild("SprinkleWeld")
					if sw then sw.C0 = CFrame.new(sw.C0.Position.Unit * (s / 2)) end
				end
			end
		end
		if #scoops == 0 then
			task.delay(0.6, hush)
			brainFreeze(player, char, names)
			-- then a bite of the cone: up to the mouth once more, the crunch, and it is gone (the tool goes once the arm is
			-- back down, so the arm is not left hanging in the air)
			task.delay(0.85, function() if tool.Parent then ev:FireAllClients("lick", player, tool, true) end end)
			task.delay(1.2, function()
				if not tool.Parent then return end
				sound("CrunchSound", char and char:FindFirstChild("Head"))
				for _, d in ipairs(tool:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = 1 end end
				task.delay(0.75, function() if tool.Parent then tool:Destroy() end end)
			end)
			return
		end
		task.wait(0.25)
		busy = false
	end)
	tool.Parent = char                                   -- straight into the hand
	sound("GetSound", char:FindFirstChild("Head"))
	ev:FireClient(player, "got", names)
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GlacePrompt" and prompt:IsDescendantOf(F) then give(player) end
end)
Players.PlayerRemoving:Connect(function(p) holding[p] = nil end)
print("Glaces: the cart is open")
]====],before=[====[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local F = script.Parent
local ev = F:WaitForChild("GlaceEvent")
local C = Color3.fromRGB
local FLAVOURS = {{"Lavande", C(186, 160, 222)}, {"Pistache", C(170, 210, 130)}, {"Fraise", C(245, 150, 170)},
	{"Chocolat", C(125, 78, 52)}, {"Citron", C(250, 232, 120)}, {"Vanille", C(252, 244, 220)}}
local WAFFLE, WAFFLE2 = C(214, 166, 96), C(190, 140, 78)
local UP = CFrame.Angles(0, 0, math.rad(90))
local MYSTERE = "Myst" .. utf8.char(232) .. "re"
local SPRINKLES = {C(255, 90, 110), C(255, 200, 60), C(90, 200, 120), C(90, 160, 255), C(200, 110, 230), C(255, 140, 60)}

local function sound(key, parent)
	local id = tonumber(F:GetAttribute(key)) or 0
	if id <= 0 or not parent then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = 0.7
	s.RollOffMinDistance = 8; s.RollOffMaxDistance = 60; s.Parent = parent; s:Play()
	Debris:AddItem(s, 7)
	return s
end

local function piece(name, size, colour, shape, handle, offset, tool)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = colour; p.Material = Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("Weld"); w.Part0 = handle; w.Part1 = p; w.C0 = offset; w.Parent = p
	p.Parent = tool
	return p, w
end

-- the cone: five waffle rings narrowing to a point, the Handle an invisible block at the rim; scoops of 0.56
-- stacked on top, each on its own weld so a lick can shrink it and settle it back down on the one below
local function makeCone(n)
	local tool = Instance.new("Tool"); tool.Name = "Ice Cream"; tool.CanBeDropped = false; tool.RequiresHandle = true
	tool.ToolTip = "Tap to lick!"
	local gx, gy, gz = F:GetAttribute("GripX") or 0, F:GetAttribute("GripY") or 0, F:GetAttribute("GripZ") or 0
	tool.Grip = CFrame.Angles(math.rad(gx), math.rad(gy), math.rad(gz))
	local h = Instance.new("Part"); h.Name = "Handle"; h.Size = Vector3.new(0.3, 0.3, 0.3); h.Transparency = 1
	h.CanCollide = false; h.CanQuery = false; h.CanTouch = false; h.Massless = true; h.CFrame = CFrame.new(0, 100, 0); h.Parent = tool
	for i, r in ipairs({0.07, 0.12, 0.17, 0.22, 0.27}) do
		piece("Cone", Vector3.new(0.14, r * 2, r * 2), (i % 2 == 0) and WAFFLE2 or WAFFLE, Enum.PartType.Cylinder, h,
			CFrame.new(0, -0.62 + i * 0.13, 0) * UP, tool)
	end
	local scoops, names, mystery = {}, {}, false
	for i = 1, n do
		-- the secret flavour: now and then one scoop is the Mystere - white, with rainbow sprinkles - just for the surprise
		local secret = not mystery and math.random() < (F:GetAttribute("MysteryChance") or 0.12)
		local f = secret and {MYSTERE, C(252, 244, 250)} or FLAVOURS[math.random(#FLAVOURS)]
		local p, w = piece("Scoop", Vector3.new(0.56, 0.56, 0.56), f[2], Enum.PartType.Ball, h, CFrame.new(0, 0.28 + (i - 1) * 0.42, 0), tool)
		if secret then
			mystery = true
			for k = 1, 9 do                                      -- sprinkles, riding on the scoop (and gone with it)
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.1, math.random() - 0.5).Unit
				local s = Instance.new("Part"); s.Name = "Sprinkle"; s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(0.1, 0.1, 0.1)
				s.Color = SPRINKLES[(k - 1) % #SPRINKLES + 1]; s.Material = Enum.Material.SmoothPlastic
				s.CanCollide = false; s.CanQuery = false; s.CanTouch = false; s.Massless = true; s.CFrame = p.CFrame * CFrame.new(dir * 0.28)
				local sw = Instance.new("Weld"); sw.Name = "SprinkleWeld"; sw.Part0 = p; sw.Part1 = s; sw.C0 = CFrame.new(dir * 0.28); sw.Parent = s
				s.Parent = p
			end
		end
		scoops[i] = {part = p, weld = w, licks = 0}
		if not table.find(names, f[1]) then names[#names + 1] = f[1] end
	end
	return tool, scoops, names, mystery
end

local holding = {}                                   -- player -> the tool they are holding
local function brainFreeze(player, char)
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local a = Instance.new("Attachment"); a.Parent = head
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255), Color3.fromRGB(150, 210, 255)); pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}); pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(3, 7); pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.Parent = a
	pe:Emit(40)
	Debris:AddItem(a, 2)
	local bb = Instance.new("BillboardGui"); bb.Name = "BrainFreeze"; bb.Size = UDim2.fromOffset(220, 54); bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true; bb.MaxDistance = 70; bb.Adornee = head
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.FredokaOne
	t.TextScaled = true; t.Text = "BRAIN FREEZE!"; t.TextColor3 = Color3.fromRGB(150, 215, 255); t.TextStrokeTransparency = 0
	t.TextStrokeColor3 = Color3.fromRGB(255, 255, 255); t.Parent = bb
	bb.Parent = head
	Debris:AddItem(bb, 2.2)
	sound("FreezeSound", head)
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "glace") end
	ev:FireClient(player, "freeze")
end

local function give(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	if holding[player] and holding[player].Parent then holding[player]:Destroy() end
	local roll = math.random()
	local tool, scoops, names, mystery = makeCone(roll < 0.3 and 1 or (roll < 0.75 and 2 or 3))
	holding[player] = tool
	local busy = false
	-- one lick sound at a time: Shannon's lick runs 4.7 s and taps can come every 0.2 s, so each new lick stops the last,
	-- and the brain freeze stops the final one just after it starts
	local lickSnd
	local function hush() if lickSnd then lickSnd:Stop(); lickSnd:Destroy(); lickSnd = nil end end
	tool.Activated:Connect(function()
		if busy then return end
		busy = true
		-- the arm brings the cone up to the mouth on every screen (GlaceClient), and the lick lands when it gets there
		ev:FireAllClients("lick", player, tool)
		task.wait(0.3)
		local top = scoops[#scoops]
		if top then
			top.licks += 1
			local per = F:GetAttribute("Licks") or 2
			hush(); lickSnd = sound("LickSound", tool:FindFirstChild("Handle"))
			if top.licks >= per then
				top.part:Destroy(); scoops[#scoops] = nil
			else
				local s = 0.56 * (1 - top.licks / (per + 0.6))       -- a lick smaller, its bottom where it was: still on the one below
				top.part.Size = Vector3.new(s, s, s)
				top.weld.C0 = CFrame.new(0, 0.28 + (#scoops - 1) * 0.42 - (0.56 - s) / 2, 0)
				for _, sp in ipairs(top.part:GetChildren()) do          -- the sprinkles stay on the surface
					local sw = sp:FindFirstChild("SprinkleWeld")
					if sw then sw.C0 = CFrame.new(sw.C0.Position.Unit * (s / 2)) end
				end
			end
		end
		if #scoops == 0 then
			task.delay(0.6, hush)
			brainFreeze(player, char)
			-- then a bite of the cone: up to the mouth once more, the crunch, and it is gone (the tool goes once the arm is
			-- back down, so the arm is not left hanging in the air)
			task.delay(0.85, function() if tool.Parent then ev:FireAllClients("lick", player, tool, true) end end)
			task.delay(1.2, function()
				if not tool.Parent then return end
				sound("CrunchSound", char and char:FindFirstChild("Head"))
				for _, d in ipairs(tool:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = 1 end end
				task.delay(0.75, function() if tool.Parent then tool:Destroy() end end)
			end)
			return
		end
		task.wait(0.25)
		busy = false
	end)
	tool.Parent = char                                   -- straight into the hand
	sound("GetSound", char:FindFirstChild("Head"))
	ev:FireClient(player, "got", names)
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GlacePrompt" and prompt:IsDescendantOf(F) then give(player) end
end)
Players.PlayerRemoving:Connect(function(p) holding[p] = nil end)
print("Glaces: the cart is open")
]====]})
table.insert(changes,{target=workspace.HatShop.HatServer,source=[====[-- HatServer: the doors, buying, wearing, and dressing everyone in the hat they chose
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local F = script.Parent
local action = RS:WaitForChild("HatShopAction")
local ev = RS:WaitForChild("HatShopEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local kit = RS:WaitForChild("HatKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end
local function owns(player, id) return (player:GetAttribute("Item_hat_" .. id) or 0) > 0 end
local function worn(player)                                -- the Item_hatwear_<id> that is 1
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 13) == "Item_hatwear_" and (tonumber(v) or 0) > 0 and Cat.byId[name:sub(14)] then return name:sub(14) end
	end
	return nil
end

-- ---- wearing: the chosen hat as an Accessory at the head's HatAttachment, sized to the head; the avatar's own hats
-- are hidden while it is on (and shown again when it comes off)
local function showOwnHats(char, show)
	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name ~= "WornHat" and acc.AccessoryType == Enum.AccessoryType.Hat then
			local h = acc:FindFirstChild("Handle")
			if h then
				if show then
					local was = h:GetAttribute("HatShopWas")
					if was ~= nil then h.Transparency = was; h:SetAttribute("HatShopWas", nil) end
				elseif h:GetAttribute("HatShopWas") == nil then
					h:SetAttribute("HatShopWas", h.Transparency); h.Transparency = 1
				end
			end
		end
	end
end
local function undress(char)
	local old = char and char:FindFirstChild("WornHat")
	if old then old:Destroy() end
	if char then showOwnHats(char, true) end
end
local function dress(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if not (hum and head) then return end
	local id = worn(player)
	local cur = char:FindFirstChild("WornHat")
	if cur and cur:GetAttribute("HatId") == id then showOwnHats(char, false) return end   -- (own hats that loaded late go aside too)
	undress(char)
	if not id or not owns(player, id) then return end
	local h = Cat.byId[id]
	local fitCF, s = Cat.fit(head, h.style.id)
	local pieces = Cat.pieces(kit, id, head.CFrame * fitCF, s)
	if not pieces or not pieces[1] then return end
	local acc = Instance.new("Accessory"); acc.Name = "WornHat"; acc.AccessoryType = Enum.AccessoryType.Hat
	acc:SetAttribute("HatId", id)
	local handle = pieces[1]; handle.Name = "Handle"; handle.Parent = acc
	for i = 2, #pieces do
		local p = pieces[i]; p.Parent = acc
		local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = p
	end
	-- the handle's HatAttachment is where the head's will be, so the Humanoid puts the hat exactly here
	local headAtt = head:FindFirstChild("HatAttachment")
	local a = Instance.new("Attachment"); a.Name = "HatAttachment"
	a.CFrame = handle.CFrame:ToObjectSpace(headAtt and headAtt.WorldCFrame or head.CFrame * CFrame.new(0, head.Size.Y / 2, 0))
	a.Parent = handle
	showOwnHats(char, false)
	if headAtt then
		hum:AddAccessory(acc)
	else                                                    -- a head with no HatAttachment: weld it where it is
		local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = handle; w.Parent = handle
		acc.Parent = char
	end
end
local pending = {}
local function redress(player)                             -- once, shortly: a swap changes two ledger lines
	if pending[player] then return end
	pending[player] = true
	task.delay(0.2, function() pending[player] = nil; dress(player) end)
end

-- ---- the doors: fade, move, unfade (the client draws the fade; the server moves you while it is dark); inside, the
-- camera is leashed so it cannot be scrolled out through the walls
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom, moving = {}, {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InHatShop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "MirrorPrompt" then ev:FireClient(player, "mirror") end
end)

-- ---- buying and wearing, asked by the client; decided here
local busy = {}
local function wear(player, id)
	local cur = worn(player)
	if cur == id then return end
	if cur then awardItems:Fire(player, "hatwear_" .. cur, -1) end
	if id then awardItems:Fire(player, "hatwear_" .. id, 1) end
end
action.OnServerInvoke = function(player, what, id)
	if what == "wear" then
		if id == "" or id == nil then wear(player, nil); return true end
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if not owns(player, id) then return false, "that one isn't yours yet" end
		wear(player, id)
		return true
	elseif what == "buy" then
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if owns(player, id) then return false, "it's already yours" end
		if busy[player] then return false, "one at a time" end
		busy[player] = true
		local ok, res, why = pcall(function()
			local price = F:GetAttribute("Price_" .. Cat.byId[id].style.id)
			if type(price) ~= "number" then return false, "no price set" end
			local have = player:GetAttribute("Acorns") or 0     -- the purse as the SERVER sees it
			if have < price then return false, "not enough acorns" end
			awardAcorns:Fire(player, -price)                   -- spending is a negative award, same ledger, same merge
			player:SetAttribute("Acorns", have - price)
			awardItems:Fire(player, "hat_" .. id, 1)
			wear(player, id)                                   -- a new hat goes straight on
			local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"hat",{hat=Cat.title(id),action="buy"}) end
			return true, price
		end)
		busy[player] = nil
		if not ok then warn("HatServer: buying " .. tostring(id) .. " failed - " .. tostring(res)); return false, "something went wrong" end
		if res then print(string.format("HatShop: %s bought the %s for %d acorns", player.Name, Cat.title(id), why)) end
		return res, why
	end
	return false, "?"
end

local function watch(player)
	player.CharacterAdded:Connect(function(char)
		leash(player, false)
		task.delay(1.2, function() if player.Character == char then dress(player) end end)
	end)
	player.CharacterAppearanceLoaded:Connect(function() redress(player) end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 13) == "Item_hatwear_" or name:sub(1, 9) == "Item_hat_" then redress(player) end
	end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() redress(player) end)
	if player.Character then dress(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil; busy[p] = nil; moving[p] = nil end)
-- Studio tests: give a hat and/or wear it without acorns (never in a live game)
local dbg = F:FindFirstChild("HatDebug")
if dbg and RunService:IsStudio() then
	dbg.OnInvoke = function(player, what, id)
		if what == "give" then awardItems:Fire(player, "hat_" .. id, 1) return true
		elseif what == "wear" then wear(player, id) return true
		elseif what == "in" then through(player, true) return true
		elseif what == "out" then through(player, false) return true end
	end
end
print("HatServer: ready")
]====],before=[====[-- HatServer: the doors, buying, wearing, and dressing everyone in the hat they chose
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local F = script.Parent
local action = RS:WaitForChild("HatShopAction")
local ev = RS:WaitForChild("HatShopEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local kit = RS:WaitForChild("HatKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end
local function owns(player, id) return (player:GetAttribute("Item_hat_" .. id) or 0) > 0 end
local function worn(player)                                -- the Item_hatwear_<id> that is 1
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 13) == "Item_hatwear_" and (tonumber(v) or 0) > 0 and Cat.byId[name:sub(14)] then return name:sub(14) end
	end
	return nil
end

-- ---- wearing: the chosen hat as an Accessory at the head's HatAttachment, sized to the head; the avatar's own hats
-- are hidden while it is on (and shown again when it comes off)
local function showOwnHats(char, show)
	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name ~= "WornHat" and acc.AccessoryType == Enum.AccessoryType.Hat then
			local h = acc:FindFirstChild("Handle")
			if h then
				if show then
					local was = h:GetAttribute("HatShopWas")
					if was ~= nil then h.Transparency = was; h:SetAttribute("HatShopWas", nil) end
				elseif h:GetAttribute("HatShopWas") == nil then
					h:SetAttribute("HatShopWas", h.Transparency); h.Transparency = 1
				end
			end
		end
	end
end
local function undress(char)
	local old = char and char:FindFirstChild("WornHat")
	if old then old:Destroy() end
	if char then showOwnHats(char, true) end
end
local function dress(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if not (hum and head) then return end
	local id = worn(player)
	local cur = char:FindFirstChild("WornHat")
	if cur and cur:GetAttribute("HatId") == id then showOwnHats(char, false) return end   -- (own hats that loaded late go aside too)
	undress(char)
	if not id or not owns(player, id) then return end
	local h = Cat.byId[id]
	local fitCF, s = Cat.fit(head, h.style.id)
	local pieces = Cat.pieces(kit, id, head.CFrame * fitCF, s)
	if not pieces or not pieces[1] then return end
	local acc = Instance.new("Accessory"); acc.Name = "WornHat"; acc.AccessoryType = Enum.AccessoryType.Hat
	acc:SetAttribute("HatId", id)
	local handle = pieces[1]; handle.Name = "Handle"; handle.Parent = acc
	for i = 2, #pieces do
		local p = pieces[i]; p.Parent = acc
		local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = p
	end
	-- the handle's HatAttachment is where the head's will be, so the Humanoid puts the hat exactly here
	local headAtt = head:FindFirstChild("HatAttachment")
	local a = Instance.new("Attachment"); a.Name = "HatAttachment"
	a.CFrame = handle.CFrame:ToObjectSpace(headAtt and headAtt.WorldCFrame or head.CFrame * CFrame.new(0, head.Size.Y / 2, 0))
	a.Parent = handle
	showOwnHats(char, false)
	if headAtt then
		hum:AddAccessory(acc)
	else                                                    -- a head with no HatAttachment: weld it where it is
		local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = handle; w.Parent = handle
		acc.Parent = char
	end
end
local pending = {}
local function redress(player)                             -- once, shortly: a swap changes two ledger lines
	if pending[player] then return end
	pending[player] = true
	task.delay(0.2, function() pending[player] = nil; dress(player) end)
end

-- ---- the doors: fade, move, unfade (the client draws the fade; the server moves you while it is dark); inside, the
-- camera is leashed so it cannot be scrolled out through the walls
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom, moving = {}, {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InHatShop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "MirrorPrompt" then ev:FireClient(player, "mirror") end
end)

-- ---- buying and wearing, asked by the client; decided here
local busy = {}
local function wear(player, id)
	local cur = worn(player)
	if cur == id then return end
	if cur then awardItems:Fire(player, "hatwear_" .. cur, -1) end
	if id then awardItems:Fire(player, "hatwear_" .. id, 1) end
end
action.OnServerInvoke = function(player, what, id)
	if what == "wear" then
		if id == "" or id == nil then wear(player, nil); return true end
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if not owns(player, id) then return false, "that one isn't yours yet" end
		wear(player, id)
		return true
	elseif what == "buy" then
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if owns(player, id) then return false, "it's already yours" end
		if busy[player] then return false, "one at a time" end
		busy[player] = true
		local ok, res, why = pcall(function()
			local price = F:GetAttribute("Price_" .. Cat.byId[id].style.id)
			if type(price) ~= "number" then return false, "no price set" end
			local have = player:GetAttribute("Acorns") or 0     -- the purse as the SERVER sees it
			if have < price then return false, "not enough acorns" end
			awardAcorns:Fire(player, -price)                   -- spending is a negative award, same ledger, same merge
			player:SetAttribute("Acorns", have - price)
			awardItems:Fire(player, "hat_" .. id, 1)
			wear(player, id)                                   -- a new hat goes straight on
			return true, price
		end)
		busy[player] = nil
		if not ok then warn("HatServer: buying " .. tostring(id) .. " failed - " .. tostring(res)); return false, "something went wrong" end
		if res then print(string.format("HatShop: %s bought the %s for %d acorns", player.Name, Cat.title(id), why)) end
		return res, why
	end
	return false, "?"
end

local function watch(player)
	player.CharacterAdded:Connect(function(char)
		leash(player, false)
		task.delay(1.2, function() if player.Character == char then dress(player) end end)
	end)
	player.CharacterAppearanceLoaded:Connect(function() redress(player) end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 13) == "Item_hatwear_" or name:sub(1, 9) == "Item_hat_" then redress(player) end
	end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() redress(player) end)
	if player.Character then dress(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil; busy[p] = nil; moving[p] = nil end)
-- Studio tests: give a hat and/or wear it without acorns (never in a live game)
local dbg = F:FindFirstChild("HatDebug")
if dbg and RunService:IsStudio() then
	dbg.OnInvoke = function(player, what, id)
		if what == "give" then awardItems:Fire(player, "hat_" .. id, 1) return true
		elseif what == "wear" then wear(player, id) return true
		elseif what == "in" then through(player, true) return true
		elseif what == "out" then through(player, false) return true end
	end
end
print("HatServer: ready")
]====]})
table.insert(changes,{target=workspace.Hoop.SlingServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local H = script.Parent
local shoot = RS:WaitForChild("SlingShot")
local award = RS:WaitForChild("AwardAcorns")
local items = RS:WaitForChild("AwardItems")
local picked = RS:WaitForChild("AcornPicked")
local template = SS:WaitForChild("AcornTemplate")
local toolTemplate = SS:WaitForChild("SlingshotTool")
local drawEvt = H:WaitForChild("DrawEvent")

-- ---- the draw flag: the drawing player says so; the character carries it for every other screen
drawEvt.OnServerEvent:Connect(function(pl, on)
	local ch = pl.Character
	if not ch then return end
	if on == true and ch:FindFirstChild("Slingshot") then ch:SetAttribute("SlingshotDraw", true) else ch:SetAttribute("SlingshotDraw", nil) end
end)

local function ring() return Vector3.new(H:GetAttribute("RingX"), H:GetAttribute("RingY"), H:GetAttribute("RingZ")) end
-- every hoop in the game (tagged AcornHoop by the builder); a shot is scored against the one nearest to where it left
local CollectionService = game:GetService("CollectionService")
local function ringOf(m) return Vector3.new(m:GetAttribute("RingX") or 0, m:GetAttribute("RingY") or 0, m:GetAttribute("RingZ") or 0) end
local function hoopFor(pos)
	local best, bestD = H, nil
	for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
		if m:IsA("Model") and m:GetAttribute("RingX") then
			local d = (ringOf(m) - pos).Magnitude
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	return best
end

-- ---- the tool follows ownership: whoever has Item_slingshot carries one, on every spawn and the moment it is bought
local function give(player)
	if (player:GetAttribute("Item_slingshot") or 0) <= 0 then return end
	local char = player.Character
	if not char then return end
	local pack = player:FindFirstChildOfClass("Backpack")
	if (pack and pack:FindFirstChild("Slingshot")) or char:FindFirstChild("Slingshot") then return end
	local t = toolTemplate:Clone()
	t.Name = "Slingshot"
	t.Parent = pack or player
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.6); give(player) end)
	player:GetAttributeChangedSignal("Item_slingshot"):Connect(function() give(player) end)
	if player.Character then task.defer(give, player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- the projectile: the same acorn that lies about the map, cut loose and welded into one piece
local function makeAcorn(from, velocity)
	local m = template:Clone()
	m.Name = "ShotAcorn"
	local nut = m.PrimaryPart or m:FindFirstChild("Nut")
	for _, d in ipairs(m:GetDescendants()) do
		if d.Name == "Hit" then d:Destroy() end
	end
	-- A SHOT YOU CAN SEE. The acorns on the ground are small on purpose; one of those doing a hundred studs a
	-- second twenty studs away is a speck ("the visual of the acorn flying is very difficult to see"). So the
	-- shot is bigger, throws off far more sparkle, and drags a golden ribbon that draws the whole arc.
	m:ScaleTo(H:GetAttribute("ShotScale") or 1)
	m:PivotTo(CFrame.new(from))
	local sp = nut:FindFirstChildOfClass("ParticleEmitter")
	if sp then
		sp.Rate = 40; sp.Speed = NumberRange.new(1, 3); sp.Lifetime = NumberRange.new(0.4, 0.9)
		sp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
		sp.Transparency = NumberSequence.new(0.1)
	end
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(-nut.Size.X * 0.4, 0, 0); a0.Parent = nut
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(nut.Size.X * 0.4, 0, 0); a1.Parent = nut
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 244, 210))
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15)})
	trail.Lifetime = 0.6; trail.MinLength = 0.05; trail.LightEmission = 1; trail.FaceCamera = true
	trail.Parent = nut
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanQuery = false
			if p == nut then
				p.CanCollide = true; p.CanTouch = true; p.Massless = false
			else
				p.CanCollide = false; p.CanTouch = false; p.Massless = true
				local w = Instance.new("WeldConstraint"); w.Part0 = nut; w.Part1 = p; w.Parent = p
			end
		end
	end
	-- the sound of the flight, on the acorn so it goes where the acorn goes; slowed with the acorn in the cinematic
	local flyId = tonumber(H:GetAttribute("FlySoundId")) or 0
	local fly
	if flyId > 0 then
		fly = Instance.new("Sound"); fly.Name = "Fly"; fly.SoundId = "rbxassetid://" .. flyId
		fly.Volume = H:GetAttribute("FlyVolume") or 0.8; fly.RollOffMaxDistance = 90; fly.Parent = nut
	end
	m.Parent = workspace
	if fly then fly:Play() end
	nut:SetNetworkOwner(nil)                                -- the server flies it, so the ring sees the truth
	nut.AssemblyLinearVelocity = velocity
	nut.AssemblyAngularVelocity = Vector3.new(6, 2, 4)
	Debris:AddItem(m, 14)
	return nut
end

local passportRounds,passportShots={},{}
local function recordShot(nut,scored,prize)
 local rec=passportShots[nut];if not rec then return end;passportShots[nut]=nil
 local r=rec.round;r.results[rec.index]={scored=scored,prize=prize or 0}
 local streak,best,baskets,won,resolved=0,0,0,0,0
 for i=1,r.n do
  local result=r.results[i];if not result then break end
  resolved+=1
  if result.scored then streak+=1;baskets+=1;won+=result.prize;best=math.max(best,streak) else streak=0 end
 end
 if resolved==0 or not r.player.Parent then return end
 local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(r.player,"hoop",{streak=math.min(3,best),baskets=baskets,prize=won,shots=resolved,ongoing=resolved<r.n}) end
end
local function trackShot(player,nut,near)
 if not near then return end
 local r=passportRounds[player]
 if not r or r.n>=3 or os.clock()-r.started>(H:GetAttribute("RestSeconds") or 60) then r={player=player,n=0,results={},started=os.clock()};passportRounds[player]=r end
 r.n+=1;passportShots[nut]={round=r,index=r.n}
end

-- ---- the basket
local function basket(player, nut, hoop)
	hoop = hoop or H
	local centre = hoop:FindFirstChild("RingCentre")
	local burst = centre and centre:FindFirstChildOfClass("ParticleEmitter")
	local prize = H:GetAttribute("Prize") or 3
 recordShot(nut,true,prize)
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + prize)
	award:Fire(player, prize)
	items:Fire(player, "baskets", 1)
	picked:FireClient(player, have + prize, ringOf(hoop))
	shoot:FireClient(player, "basket", prize)
	if burst then burst.Rate = 120; task.delay(0.6, function() burst.Rate = 0 end) end
	-- the whistle as it drops through, the cheer a beat later, both from the ring so the clearing hears them
	local function ringSound(attr, delay)
		local id = tonumber(H:GetAttribute(attr)) or 0
		if id <= 0 or not centre then return end
		task.delay(delay, function()
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = H:GetAttribute("BasketVolume") or 1.0
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 20; s.RollOffMaxDistance = 250
			s.Parent = centre; s:Play(); Debris:AddItem(s, 15)
		end)
	end
	ringSound("BasketWhistleId", 0)
	ringSound("BasketCheerId", 0.35)
	print(string.format("%s: BASKET by %s (+%d, now %d)", hoop.Name, player.Name, prize, have + prize))
end

-- ---- shots
local live = {}                                          -- nut -> {player, last, born}
local lastShot = {}
-- THREE SHOTS, THEN A REST, at the croc and the hoops alike (Shannon, Sep 26: "make a cooldown so players don't just stay
-- there for 5 minutes shooting to harvest acorns ... allow 3 shots and then a cooldown period" - "cool down for both").
-- Counted here, on the server. ShotsBeforeRest / RestSeconds on the Hoop.
local volleys = {}                                       -- player -> {n = shots so far, last = when, restUntil = when}
-- AT THE LAGOON a shot flies AT something (the client says what): "croc" is the top of his head where it will be when
-- the acorn gets there (CrocServer's CrocAim function answers with where his head is and how fast he's going), "point"
-- the spot under the cursor. The flight is an arc that comes down exactly there - the farther, the longer and higher.
-- The hoop's fixed high lob, timed by the draw, could not hit a swimming croc.
local function flightTime(d) return math.clamp(0.35 + d / 90, 0.45, 1.1) end
local function aimedTarget(kind, point, from)
	if kind == "croc" then
		local lag = workspace:FindFirstChild("Lagoon")
		local fn = lag and lag:FindFirstChild("CrocAim")
		if fn and fn:IsA("BindableFunction") then
			local ok, head, vel = pcall(function() return fn:Invoke() end)
			if ok and typeof(head) == "Vector3" then
				local target = head
				if typeof(vel) == "Vector3" then
					for _ = 1, 3 do target = head + vel * flightTime((target - from).Magnitude) end   -- where he'll be
				end
				return target
			end
		end
	end
	if typeof(point) == "Vector3" and point.X == point.X and point.Y == point.Y and point.Z == point.Z then return point end
	return nil
end
shoot.OnServerEvent:Connect(function(player, dir, power, kind, point)
	if typeof(dir) ~= "Vector3" or type(power) ~= "number" then return end
	if dir.Magnitude < 0.5 or dir.X ~= dir.X then return end
	power = math.clamp(power, 0, 1)
	local char = player.Character
	local tool = char and char:FindFirstChild("Slingshot")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tool and hum and hum.Health > 0) then return end
	local now = os.clock()
	if now - (lastShot[player] or 0) < 0.5 then return end
	lastShot[player] = now
	local volley = volleys[player] or {n = 0, last = 0, restUntil = 0}; volleys[player] = volley
	if now < volley.restUntil then shoot:FireClient(player, "rest", math.ceil(volley.restUntil - now)) return end
	if now - volley.last > (H:GetAttribute("RestSeconds") or 60) then volley.n = 0 end
	local cost = H:GetAttribute("ShotCost") or 1
	local have = player:GetAttribute("Acorns") or 0
	if have < cost then shoot:FireClient(player, "no", "You need an acorn to shoot. Find one first.") return end
	player:SetAttribute("Acorns", have - cost)
	award:Fire(player, -cost)
	if volley then
		volley.n += 1; volley.last = now
		if volley.n >= (H:GetAttribute("ShotsBeforeRest") or 3) then
			local rest = H:GetAttribute("RestSeconds") or 60
			volley.n = 0; volley.restUntil = now + rest
			shoot:FireClient(player, "rest", rest, true)
		end
	end
	local eyeP = char:FindFirstChild("Head")
	local eye = eyeP and eyeP.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))
	local target = (kind == "croc" or kind == "point") and aimedTarget(kind, point, eye)
	if target then
		local flat = (target - eye) * Vector3.new(1, 0, 1)
		local range = H:GetAttribute("AimRange") or 90
		if flat.Magnitude > range then target = Vector3.new(eye.X, target.Y, eye.Z) + flat.Unit * range; flat = flat.Unit * range end
		local from = eye + (flat.Magnitude > 0.1 and flat.Unit * 2.0 or Vector3.zero) + Vector3.new(0, 0.4, 0)
		local T = flightTime((target - from).Magnitude)
		local nut = makeAcorn(from, (target - from) / T + Vector3.new(0, 0.5 * workspace.Gravity * T, 0))
		nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
		shoot:FireClient(player, "shot", power)
		return
	end
	-- LAUNCH FROM THE HEAD, not from the tool's handle: the server's copy of the handle sits about a stud and
	-- a half from where the client sees it (the arm's tool-hold pose is not the same on both sides), and a
	-- launch point the two disagree on is an arc the player cannot learn. The head replicates exactly, and
	-- two studs along the aim from there is clear of the body.
	-- the aim gives the direction along the ground; the arc is fixed
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.05 then flat = char.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1) end
	local e = math.rad(H:GetAttribute("Elevation") or 66)
	dir = flat.Unit * math.cos(e) + Vector3.new(0, math.sin(e), 0)
	local head = char:FindFirstChild("Head")
	local from = (head and head.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))) + dir * 2.2
	local lo, hi = H:GetAttribute("MinSpeed") or 45, H:GetAttribute("MaxSpeed") or 115
	local nut = makeAcorn(from, dir * (lo + (hi - lo) * power))
	nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
	live[nut] = {player = player, last = nut.Position, born = now, start = nut.Position, hoop = hoopFor(from)}
 trackShot(player,nut,((from-ringOf(hoopFor(from)))*Vector3.new(1,0,1)).Magnitude<=(H:GetAttribute("MissRange") or 80))
	shoot:FireClient(player, "shot", power)
end)

-- Every frame, each acorn in the air is checked. Two things happen here:
--   * SCORING: crossing the plane of the ring on the way DOWN inside the opening. A trigger part would miss a
--     fast acorn between physics steps; a line between two positions cannot.
--   * THE CINEMATIC: once an acorn is descending, its landing point is known (no drag). If it will cross inside
--     the opening within SlowLead seconds, it is anchored and walked along that same parabola at SlowMo speed,
--     the shooter's camera is told to cut in, and the basket is paid at the moment it passes the ring. Then it
--     is handed back to physics to drop through the net.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local g = workspace.Gravity
	local nutR = ((template.PrimaryPart or template:FindFirstChild("Nut")).Size.X * (H:GetAttribute("ShotScale") or 1)) / 2
	local R = (H:GetAttribute("RingRadius") or 2.0) - nutR - 0.1        -- the whole acorn inside the opening
	local SLOW = H:GetAttribute("SlowMo") or 0.35
	local LEAD = H:GetAttribute("SlowLead") or 0.7
	for nut, rec in pairs(live) do
		local rc = ringOf(rec.hoop or H)
		if not nut.Parent or now - rec.born > 14 then
   recordShot(nut,false,0)
			live[nut] = nil
		elseif rec.cine then
			local c = rec.cine
			local tau = (now - c.t0) * SLOW                                   -- flight time, slowed
			local pos = c.p0 + c.v0 * tau + Vector3.new(0, -0.5 * g * tau * tau, 0)
			nut.CFrame = CFrame.new(pos) * CFrame.Angles(tau * 4, tau * 2.5, 0)
			if not c.scored and tau >= c.tCross then
				c.scored = true
				basket(rec.player, nut, rec.hoop)
			end
			if tau >= c.tCross + 0.22 then                                    -- through the net: physics again
				nut.Anchored = false
				nut.AssemblyLinearVelocity = c.v0 + Vector3.new(0, -g * tau, 0)
				live[nut] = nil
			end
		else
			local cur, vel = nut.Position, nut.AssemblyLinearVelocity
			if vel.Y < 0 then rec.peaked = true end
			-- A MISS: it has peaked and come back down past the ring's plane, or past where it started for a
			-- shot that never got that high, without scoring. The shooter hears the crowd's "ohhh"; nobody else.
			if rec.peaked and not rec.missed and (cur.Y < rc.Y - 1.5 or cur.Y < rec.start.Y - 0.5)
				and ((rec.start - rc) * Vector3.new(1, 0, 1)).Magnitude < (H:GetAttribute("MissRange") or 80) then   -- no crowd "ohhh" for shots nowhere near a hoop
				rec.missed = true
    recordShot(nut,false,0)
				live[nut] = nil
				shoot:FireClient(rec.player, "miss")
			elseif rec.last.Y > rc.Y and cur.Y <= rc.Y then
				local f = (rec.last.Y - rc.Y) / math.max(rec.last.Y - cur.Y, 1e-6)
				local x = rec.last:Lerp(cur, f)
				if ((x - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					live[nut] = nil
					basket(rec.player, nut, rec.hoop)
				end
			elseif now - rec.born > 0.05 then
				-- where will it come down through the ring plane, and when? (the larger root is the descending
				-- crossing, whether the acorn is still rising or already falling - so the slow motion can begin
				-- before the peak and the shooter sees it crest and drop)
				local h = cur.Y - rc.Y
				local disc = vel.Y * vel.Y + 2 * g * h
				local t = disc >= 0 and (vel.Y + math.sqrt(disc)) / g or -1
				local land = cur + Vector3.new(vel.X * t, 0, vel.Z * t)
				if t >= 0.1 and t <= LEAD and ((land - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					rec.cine = {t0 = now, p0 = cur, v0 = vel, tCross = t, scored = false}
					local fly = nut:FindFirstChild("Fly"); if fly then fly.PlaybackSpeed = SLOW end
					nut.Anchored = true
					nut.AssemblyLinearVelocity = Vector3.zero
					shoot:FireClient(rec.player, "cine", nut, rc, (t + 0.22) / SLOW)
				end
			end
			rec.last = cur
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) lastShot[p] = nil; volleys[p] = nil;passportRounds[p]=nil;for nut,r in pairs(passportShots) do if r.round.player==p then passportShots[nut]=nil end end end)
print("SlingServer: ready")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local H = script.Parent
local shoot = RS:WaitForChild("SlingShot")
local award = RS:WaitForChild("AwardAcorns")
local items = RS:WaitForChild("AwardItems")
local picked = RS:WaitForChild("AcornPicked")
local template = SS:WaitForChild("AcornTemplate")
local toolTemplate = SS:WaitForChild("SlingshotTool")
local drawEvt = H:WaitForChild("DrawEvent")

-- ---- the draw flag: the drawing player says so; the character carries it for every other screen
drawEvt.OnServerEvent:Connect(function(pl, on)
	local ch = pl.Character
	if not ch then return end
	if on == true and ch:FindFirstChild("Slingshot") then ch:SetAttribute("SlingshotDraw", true) else ch:SetAttribute("SlingshotDraw", nil) end
end)

local function ring() return Vector3.new(H:GetAttribute("RingX"), H:GetAttribute("RingY"), H:GetAttribute("RingZ")) end
-- every hoop in the game (tagged AcornHoop by the builder); a shot is scored against the one nearest to where it left
local CollectionService = game:GetService("CollectionService")
local function ringOf(m) return Vector3.new(m:GetAttribute("RingX") or 0, m:GetAttribute("RingY") or 0, m:GetAttribute("RingZ") or 0) end
local function hoopFor(pos)
	local best, bestD = H, nil
	for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
		if m:IsA("Model") and m:GetAttribute("RingX") then
			local d = (ringOf(m) - pos).Magnitude
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	return best
end

-- ---- the tool follows ownership: whoever has Item_slingshot carries one, on every spawn and the moment it is bought
local function give(player)
	if (player:GetAttribute("Item_slingshot") or 0) <= 0 then return end
	local char = player.Character
	if not char then return end
	local pack = player:FindFirstChildOfClass("Backpack")
	if (pack and pack:FindFirstChild("Slingshot")) or char:FindFirstChild("Slingshot") then return end
	local t = toolTemplate:Clone()
	t.Name = "Slingshot"
	t.Parent = pack or player
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.6); give(player) end)
	player:GetAttributeChangedSignal("Item_slingshot"):Connect(function() give(player) end)
	if player.Character then task.defer(give, player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- the projectile: the same acorn that lies about the map, cut loose and welded into one piece
local function makeAcorn(from, velocity)
	local m = template:Clone()
	m.Name = "ShotAcorn"
	local nut = m.PrimaryPart or m:FindFirstChild("Nut")
	for _, d in ipairs(m:GetDescendants()) do
		if d.Name == "Hit" then d:Destroy() end
	end
	-- A SHOT YOU CAN SEE. The acorns on the ground are small on purpose; one of those doing a hundred studs a
	-- second twenty studs away is a speck ("the visual of the acorn flying is very difficult to see"). So the
	-- shot is bigger, throws off far more sparkle, and drags a golden ribbon that draws the whole arc.
	m:ScaleTo(H:GetAttribute("ShotScale") or 1)
	m:PivotTo(CFrame.new(from))
	local sp = nut:FindFirstChildOfClass("ParticleEmitter")
	if sp then
		sp.Rate = 40; sp.Speed = NumberRange.new(1, 3); sp.Lifetime = NumberRange.new(0.4, 0.9)
		sp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
		sp.Transparency = NumberSequence.new(0.1)
	end
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(-nut.Size.X * 0.4, 0, 0); a0.Parent = nut
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(nut.Size.X * 0.4, 0, 0); a1.Parent = nut
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 244, 210))
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15)})
	trail.Lifetime = 0.6; trail.MinLength = 0.05; trail.LightEmission = 1; trail.FaceCamera = true
	trail.Parent = nut
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanQuery = false
			if p == nut then
				p.CanCollide = true; p.CanTouch = true; p.Massless = false
			else
				p.CanCollide = false; p.CanTouch = false; p.Massless = true
				local w = Instance.new("WeldConstraint"); w.Part0 = nut; w.Part1 = p; w.Parent = p
			end
		end
	end
	-- the sound of the flight, on the acorn so it goes where the acorn goes; slowed with the acorn in the cinematic
	local flyId = tonumber(H:GetAttribute("FlySoundId")) or 0
	local fly
	if flyId > 0 then
		fly = Instance.new("Sound"); fly.Name = "Fly"; fly.SoundId = "rbxassetid://" .. flyId
		fly.Volume = H:GetAttribute("FlyVolume") or 0.8; fly.RollOffMaxDistance = 90; fly.Parent = nut
	end
	m.Parent = workspace
	if fly then fly:Play() end
	nut:SetNetworkOwner(nil)                                -- the server flies it, so the ring sees the truth
	nut.AssemblyLinearVelocity = velocity
	nut.AssemblyAngularVelocity = Vector3.new(6, 2, 4)
	Debris:AddItem(m, 14)
	return nut
end

-- ---- the basket
local function basket(player, nut, hoop)
	hoop = hoop or H
	local centre = hoop:FindFirstChild("RingCentre")
	local burst = centre and centre:FindFirstChildOfClass("ParticleEmitter")
	local prize = H:GetAttribute("Prize") or 3
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + prize)
	award:Fire(player, prize)
	items:Fire(player, "baskets", 1)
	picked:FireClient(player, have + prize, ringOf(hoop))
	shoot:FireClient(player, "basket", prize)
	if burst then burst.Rate = 120; task.delay(0.6, function() burst.Rate = 0 end) end
	-- the whistle as it drops through, the cheer a beat later, both from the ring so the clearing hears them
	local function ringSound(attr, delay)
		local id = tonumber(H:GetAttribute(attr)) or 0
		if id <= 0 or not centre then return end
		task.delay(delay, function()
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = H:GetAttribute("BasketVolume") or 1.0
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 20; s.RollOffMaxDistance = 250
			s.Parent = centre; s:Play(); Debris:AddItem(s, 15)
		end)
	end
	ringSound("BasketWhistleId", 0)
	ringSound("BasketCheerId", 0.35)
	print(string.format("%s: BASKET by %s (+%d, now %d)", hoop.Name, player.Name, prize, have + prize))
end

-- ---- shots
local live = {}                                          -- nut -> {player, last, born}
local lastShot = {}
-- THREE SHOTS, THEN A REST, at the croc and the hoops alike (Shannon, Sep 26: "make a cooldown so players don't just stay
-- there for 5 minutes shooting to harvest acorns ... allow 3 shots and then a cooldown period" - "cool down for both").
-- Counted here, on the server. ShotsBeforeRest / RestSeconds on the Hoop.
local volleys = {}                                       -- player -> {n = shots so far, last = when, restUntil = when}
-- AT THE LAGOON a shot flies AT something (the client says what): "croc" is the top of his head where it will be when
-- the acorn gets there (CrocServer's CrocAim function answers with where his head is and how fast he's going), "point"
-- the spot under the cursor. The flight is an arc that comes down exactly there - the farther, the longer and higher.
-- The hoop's fixed high lob, timed by the draw, could not hit a swimming croc.
local function flightTime(d) return math.clamp(0.35 + d / 90, 0.45, 1.1) end
local function aimedTarget(kind, point, from)
	if kind == "croc" then
		local lag = workspace:FindFirstChild("Lagoon")
		local fn = lag and lag:FindFirstChild("CrocAim")
		if fn and fn:IsA("BindableFunction") then
			local ok, head, vel = pcall(function() return fn:Invoke() end)
			if ok and typeof(head) == "Vector3" then
				local target = head
				if typeof(vel) == "Vector3" then
					for _ = 1, 3 do target = head + vel * flightTime((target - from).Magnitude) end   -- where he'll be
				end
				return target
			end
		end
	end
	if typeof(point) == "Vector3" and point.X == point.X and point.Y == point.Y and point.Z == point.Z then return point end
	return nil
end
shoot.OnServerEvent:Connect(function(player, dir, power, kind, point)
	if typeof(dir) ~= "Vector3" or type(power) ~= "number" then return end
	if dir.Magnitude < 0.5 or dir.X ~= dir.X then return end
	power = math.clamp(power, 0, 1)
	local char = player.Character
	local tool = char and char:FindFirstChild("Slingshot")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tool and hum and hum.Health > 0) then return end
	local now = os.clock()
	if now - (lastShot[player] or 0) < 0.5 then return end
	lastShot[player] = now
	local volley = volleys[player] or {n = 0, last = 0, restUntil = 0}; volleys[player] = volley
	if now < volley.restUntil then shoot:FireClient(player, "rest", math.ceil(volley.restUntil - now)) return end
	if now - volley.last > (H:GetAttribute("RestSeconds") or 60) then volley.n = 0 end
	local cost = H:GetAttribute("ShotCost") or 1
	local have = player:GetAttribute("Acorns") or 0
	if have < cost then shoot:FireClient(player, "no", "You need an acorn to shoot. Find one first.") return end
	player:SetAttribute("Acorns", have - cost)
	award:Fire(player, -cost)
	if volley then
		volley.n += 1; volley.last = now
		if volley.n >= (H:GetAttribute("ShotsBeforeRest") or 3) then
			local rest = H:GetAttribute("RestSeconds") or 60
			volley.n = 0; volley.restUntil = now + rest
			shoot:FireClient(player, "rest", rest, true)
		end
	end
	local eyeP = char:FindFirstChild("Head")
	local eye = eyeP and eyeP.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))
	local target = (kind == "croc" or kind == "point") and aimedTarget(kind, point, eye)
	if target then
		local flat = (target - eye) * Vector3.new(1, 0, 1)
		local range = H:GetAttribute("AimRange") or 90
		if flat.Magnitude > range then target = Vector3.new(eye.X, target.Y, eye.Z) + flat.Unit * range; flat = flat.Unit * range end
		local from = eye + (flat.Magnitude > 0.1 and flat.Unit * 2.0 or Vector3.zero) + Vector3.new(0, 0.4, 0)
		local T = flightTime((target - from).Magnitude)
		local nut = makeAcorn(from, (target - from) / T + Vector3.new(0, 0.5 * workspace.Gravity * T, 0))
		nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
		shoot:FireClient(player, "shot", power)
		return
	end
	-- LAUNCH FROM THE HEAD, not from the tool's handle: the server's copy of the handle sits about a stud and
	-- a half from where the client sees it (the arm's tool-hold pose is not the same on both sides), and a
	-- launch point the two disagree on is an arc the player cannot learn. The head replicates exactly, and
	-- two studs along the aim from there is clear of the body.
	-- the aim gives the direction along the ground; the arc is fixed
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.05 then flat = char.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1) end
	local e = math.rad(H:GetAttribute("Elevation") or 66)
	dir = flat.Unit * math.cos(e) + Vector3.new(0, math.sin(e), 0)
	local head = char:FindFirstChild("Head")
	local from = (head and head.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))) + dir * 2.2
	local lo, hi = H:GetAttribute("MinSpeed") or 45, H:GetAttribute("MaxSpeed") or 115
	local nut = makeAcorn(from, dir * (lo + (hi - lo) * power))
	nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
	live[nut] = {player = player, last = nut.Position, born = now, start = nut.Position, hoop = hoopFor(from)}
	shoot:FireClient(player, "shot", power)
end)

-- Every frame, each acorn in the air is checked. Two things happen here:
--   * SCORING: crossing the plane of the ring on the way DOWN inside the opening. A trigger part would miss a
--     fast acorn between physics steps; a line between two positions cannot.
--   * THE CINEMATIC: once an acorn is descending, its landing point is known (no drag). If it will cross inside
--     the opening within SlowLead seconds, it is anchored and walked along that same parabola at SlowMo speed,
--     the shooter's camera is told to cut in, and the basket is paid at the moment it passes the ring. Then it
--     is handed back to physics to drop through the net.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local g = workspace.Gravity
	local nutR = ((template.PrimaryPart or template:FindFirstChild("Nut")).Size.X * (H:GetAttribute("ShotScale") or 1)) / 2
	local R = (H:GetAttribute("RingRadius") or 2.0) - nutR - 0.1        -- the whole acorn inside the opening
	local SLOW = H:GetAttribute("SlowMo") or 0.35
	local LEAD = H:GetAttribute("SlowLead") or 0.7
	for nut, rec in pairs(live) do
		local rc = ringOf(rec.hoop or H)
		if not nut.Parent or now - rec.born > 14 then
			live[nut] = nil
		elseif rec.cine then
			local c = rec.cine
			local tau = (now - c.t0) * SLOW                                   -- flight time, slowed
			local pos = c.p0 + c.v0 * tau + Vector3.new(0, -0.5 * g * tau * tau, 0)
			nut.CFrame = CFrame.new(pos) * CFrame.Angles(tau * 4, tau * 2.5, 0)
			if not c.scored and tau >= c.tCross then
				c.scored = true
				basket(rec.player, nut, rec.hoop)
			end
			if tau >= c.tCross + 0.22 then                                    -- through the net: physics again
				nut.Anchored = false
				nut.AssemblyLinearVelocity = c.v0 + Vector3.new(0, -g * tau, 0)
				live[nut] = nil
			end
		else
			local cur, vel = nut.Position, nut.AssemblyLinearVelocity
			if vel.Y < 0 then rec.peaked = true end
			-- A MISS: it has peaked and come back down past the ring's plane, or past where it started for a
			-- shot that never got that high, without scoring. The shooter hears the crowd's "ohhh"; nobody else.
			if rec.peaked and not rec.missed and (cur.Y < rc.Y - 1.5 or cur.Y < rec.start.Y - 0.5)
				and ((rec.start - rc) * Vector3.new(1, 0, 1)).Magnitude < (H:GetAttribute("MissRange") or 80) then   -- no crowd "ohhh" for shots nowhere near a hoop
				rec.missed = true
				live[nut] = nil
				shoot:FireClient(rec.player, "miss")
			elseif rec.last.Y > rc.Y and cur.Y <= rc.Y then
				local f = (rec.last.Y - rc.Y) / math.max(rec.last.Y - cur.Y, 1e-6)
				local x = rec.last:Lerp(cur, f)
				if ((x - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					live[nut] = nil
					basket(rec.player, nut, rec.hoop)
				end
			elseif now - rec.born > 0.05 then
				-- where will it come down through the ring plane, and when? (the larger root is the descending
				-- crossing, whether the acorn is still rising or already falling - so the slow motion can begin
				-- before the peak and the shooter sees it crest and drop)
				local h = cur.Y - rc.Y
				local disc = vel.Y * vel.Y + 2 * g * h
				local t = disc >= 0 and (vel.Y + math.sqrt(disc)) / g or -1
				local land = cur + Vector3.new(vel.X * t, 0, vel.Z * t)
				if t >= 0.1 and t <= LEAD and ((land - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					rec.cine = {t0 = now, p0 = cur, v0 = vel, tCross = t, scored = false}
					local fly = nut:FindFirstChild("Fly"); if fly then fly.PlaybackSpeed = SLOW end
					nut.Anchored = true
					nut.AssemblyLinearVelocity = Vector3.zero
					shoot:FireClient(rec.player, "cine", nut, rc, (t + 0.22) / SLOW)
				end
			end
			rec.last = cur
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) lastShot[p] = nil; volleys[p] = nil end)
print("SlingServer: ready")
]====]})
table.insert(changes,{target=workspace.HudBarUI.HudBarClient,source=[====[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local NEED = (workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need")) or 10
local UIS = game:GetService("UserInputService")
local isMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or script.Parent:GetAttribute("ForceMobile") == true
local PANEL_Y = isMobile and 114 or 64          -- phones keep room for the Hint button under the icons
local PANEL, CREAM, GOLD, DIM = C(38, 30, 52), C(255, 246, 220), C(255, 214, 90), C(120, 110, 140)

-- ---------------------------------------------------------------- the areas ----
-- world rectangles (the same ones the boundary walls use), the order you travel them, and what unlocks each
local AREAS = {
	{id = "forest",  x0 = -130, x1 = 142, z0 = -215, z1 = 25,  needs = nil},
	{id = "village", x0 = 150,  x1 = 352, z0 = -205, z1 = 5,   needs = "forest"},
	{id = "domaine", x0 = 352,  x1 = 700, z0 = -250, z1 = 30,  needs = "village"},
}
local NAME, TOTAL = {}, {}
for _, m in ipairs(Registry.maps) do NAME[m.id] = m.name end
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local function unlocked(a) return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED end
local function areaAt(pos)
	for _, a in ipairs(AREAS) do
		if pos.X >= a.x0 and pos.X <= a.x1 and pos.Z >= a.z0 and pos.Z <= a.z1 then return a end
	end
end

-- ---------------------------------------------------------------- the bar ----
pcall(function() pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor end)         -- phones stay in landscape, either way up
for _, g in ipairs(pg:GetChildren()) do if g.Name == "HudBar" then g:Destroy() end end        -- never two bars
local gui = Instance.new("ScreenGui"); gui.Name = "HudBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg
local bar = Instance.new("Frame"); bar.Name = "Bar"; bar.AnchorPoint = Vector2.new(1, 0); bar.Position = UDim2.new(1, -10, 0, 8)
bar.Size = UDim2.fromOffset(216, 48); bar.BackgroundTransparency = 1; bar.Parent = gui
local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = bar

local function iconButton(order, tip)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = PANEL; b.BackgroundTransparency = 0
	b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = order; b.Parent = bar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.35; s.Parent = b
	local label = Instance.new("TextLabel"); label.Name = "Tip"; label.AnchorPoint = Vector2.new(0.5, 1); label.Position = UDim2.new(0.5, 0, 0, -4)
	label.Size = UDim2.fromOffset(96, 20); label.BackgroundColor3 = PANEL; label.BackgroundTransparency = 0.15; label.TextColor3 = CREAM
	label.Font = Enum.Font.FredokaOne; label.TextSize = 13; label.Text = tip; label.Visible = false; label.Parent = b
	local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 8); lc.Parent = label
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.35}):Play() end)
	return b, s
end
local function acorn(parent, size, cx, cy)                      -- a little acorn drawn from frames
	local nut = Instance.new("Frame"); nut.Size = UDim2.fromOffset(size * 0.62, size * 0.62); nut.Position = UDim2.fromOffset(cx - size * 0.31, cy - size * 0.18)
	nut.BackgroundColor3 = C(206, 146, 82); nut.BorderSizePixel = 0; nut.Parent = parent
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0.45, 0); nc.Parent = nut
	local cap = Instance.new("Frame"); cap.Size = UDim2.fromOffset(size * 0.78, size * 0.34); cap.Position = UDim2.fromOffset(cx - size * 0.39, cy - size * 0.40)
	cap.BackgroundColor3 = C(110, 70, 40); cap.BorderSizePixel = 0; cap.Parent = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.4, 0); cc.Parent = cap
	local stem = Instance.new("Frame"); stem.Size = UDim2.fromOffset(size * 0.12, size * 0.2); stem.Position = UDim2.fromOffset(cx - size * 0.06, cy - size * 0.56)
	stem.BackgroundColor3 = C(86, 56, 34); stem.BorderSizePixel = 0; stem.Parent = parent
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0.4, 0); sc.Parent = stem
end

-- Clean static silhouette: smooth curves stay readable at phone sizes.
-- Avoids copying a furred game mesh or waiting for world models to load.
local function squirrelIcon(parent, size, cx, cy)
 local icon=Instance.new("ImageLabel")
 icon.Name="SquirrelIcon"
 icon.AnchorPoint=Vector2.new(0.5,0.5)
 icon.Position=UDim2.fromOffset(cx,cy)
 icon.Size=UDim2.fromOffset(size,size)
 icon.BackgroundTransparency=1
 icon.Image="rbxassetid://90886407221518"
 icon.ScaleType=Enum.ScaleType.Fit
 icon.Parent=parent
 local edge=Instance.new("UICorner");edge.CornerRadius=UDim.new(0,5);edge.Parent=icon
end

local squirrelBtn = iconButton(1, "Squirrels")
squirrelIcon(squirrelBtn, 30, 24, 16)                            -- a squirrel for the squirrels; the acorn
                                                                 -- belongs to the purse beside it
local countTag = Instance.new("TextLabel"); countTag.AnchorPoint = Vector2.new(0.5, 1); countTag.Position = UDim2.new(0.5, 0, 1, -2); countTag.Size = UDim2.fromOffset(44, 14)
countTag.BackgroundTransparency = 1; countTag.Font = Enum.Font.FredokaOne; countTag.TextSize = 13; countTag.TextColor3 = GOLD; countTag.Text = "0"; countTag.Parent = squirrelBtn
local mapBtn = iconButton(2, "Map")
do                                                               -- a folded map: three panels, a route and a pin
	for i, tint in ipairs({C(228, 216, 186), C(214, 200, 166), C(228, 216, 186)}) do
		local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(8, i == 2 and 25 or 21); p.Position = UDim2.fromOffset(11 + (i - 1) * 9, i == 2 and 4 or 6)
		p.BackgroundColor3 = tint; p.BorderSizePixel = 0; p.Parent = mapBtn
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 2); c.Parent = p
	end
	local pin = Instance.new("Frame"); pin.Size = UDim2.fromOffset(8, 8); pin.Position = UDim2.fromOffset(25, 9); pin.BackgroundColor3 = C(214, 60, 60); pin.BorderSizePixel = 0; pin.Parent = mapBtn
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pin
end

-- ---- the acorn purse: a square LEFT of the two icons, showing what you have collected ----
-- Now a button: it opens the store. LayoutOrder 0 puts it leftmost - the row is right-aligned and lays its
-- children out in order.
local purse = Instance.new("TextButton")
purse.Name = "Purse"; purse.Size = UDim2.fromOffset(48, 48); purse.BackgroundColor3 = PANEL
purse.BackgroundTransparency = 0; purse.BorderSizePixel = 0; purse.LayoutOrder = 0
purse.Text = ""; purse.AutoButtonColor = false; purse.Parent = bar
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = purse
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Transparency = 0.35; st.Parent = purse
end
acorn(purse, 21, 24, 14)                                         -- the same acorn as the collectible on the ground
local purseCount = Instance.new("TextLabel")
purseCount.Name = "Count"; purseCount.AnchorPoint = Vector2.new(0.5, 1); purseCount.Position = UDim2.new(0.5, 0, 1, -2)
purseCount.Size = UDim2.fromOffset(44, 14); purseCount.BackgroundTransparency = 1
purseCount.Font = Enum.Font.FredokaOne; purseCount.TextSize = 13; purseCount.TextColor3 = GOLD
purseCount.Text = "0"; purseCount.Parent = purse

-- ---------------------------------------------------------------- the squirrel panel (the existing HUD) ----
local hudGui, hudPanel
local function viewport()
	local c = workspace.CurrentCamera
	return c and c.ViewportSize or Vector2.new(1280, 720)
end
-- the squirrel panel and the squirrel card are built at a fixed pixel size; on a phone they run off the screen, so
-- each gets a UIScale that shrinks it to whatever room is left
local function fitPanel()
	if not hudPanel then return end
	local sc = hudPanel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", hudPanel)
	local vp = viewport()
	local w, h = hudPanel.Size.X.Offset, hudPanel.Size.Y.Offset
	if w <= 0 or h <= 0 then return end
	sc.Scale = math.clamp(math.min((vp.Y - PANEL_Y - 16) / h, (vp.X * 0.52) / w), 0.45, 1)
end
-- the squirrel card is built tall and narrow, which does not suit a phone held sideways. On a phone it is laid out
-- again in landscape: the portrait on the left, the name and story on the right. The card's own pop animation drives
-- its UIScale, so any size clamp has to be applied after that tween has finished.
local CARD_W, CARD_H = 646, 306
local function relayoutCard(prim)
	local big, ring, hint, title, bio
	for _, d in ipairs(prim:GetDescendants()) do
		if d:IsA("Frame") and d.Size.X.Offset == 326 then big = d
		elseif d:IsA("Frame") and d.Size.X.Offset == 288 then ring = d
		elseif d:IsA("TextLabel") then
			local y = d.Position.Y.Offset
			if y == 350 then hint = d elseif y == 368 then title = d elseif y == 414 then bio = d end
		end
	end
	prim.Size = UDim2.fromOffset(CARD_W, CARD_H)
	if big then
		big.AnchorPoint = Vector2.new(0, 0.5); big.Position = UDim2.new(0, 16, 0.5, 0); big.Size = UDim2.fromOffset(252, 252)
	end
	if ring then ring.Size = UDim2.fromOffset(228, 228); ring.Position = UDim2.new(0.5, 0, 0.5, 0) end
	if hint then hint.Position = UDim2.new(0, 16, 1, -24); hint.Size = UDim2.fromOffset(252, 16) end
	if title then title.Position = UDim2.new(0, 288, 0, 30); title.Size = UDim2.new(1, -312, 0, 42) end
	if bio then bio.Position = UDim2.new(0, 290, 0, 84); bio.Size = UDim2.new(1, -314, 1, -118) end
end
local function fitCard(card)
	for _, d in ipairs(card:GetChildren()) do
		if d:IsA("Frame") and d.AnchorPoint.X == 0.5 and d.Size.X.Offset > 200 then
			if isMobile then relayoutCard(d) end
			task.delay(0.45, function()                        -- after the card's pop-in tween has settled
				if not d.Parent then return end
				local sc = d:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", d)
				local vp = viewport()
				sc.Scale = math.clamp(math.min((vp.Y - 20) / d.Size.Y.Offset, (vp.X - 20) / d.Size.X.Offset), 0.4, 1)
			end)
		end
	end
end
-- takes charge of a squirrel HUD: its panel goes below the bar (and the Hint button on phones), closed, fitted to the screen
local function hookHud(g)
	hudGui = g
	local p = g:WaitForChild("Panel", 30)
	if not p or hudGui ~= g then return end
	hudPanel = p
	p.Position = UDim2.new(1, -10, 0, PANEL_Y)
	p.Visible = false
	p.AnchorPoint = Vector2.new(1, 0)
	fitPanel()
	p:GetPropertyChangedSignal("Size"):Connect(fitPanel)
	for _, c in ipairs(g:GetChildren()) do if c.Name == "Card" then fitCard(c) end end
	g.ChildAdded:Connect(function(c)                            -- the card is rebuilt every time one is opened
		if c.Name == "Card" then task.defer(fitCard, c) end
	end)
end
task.spawn(function()
	local g = pg:WaitForChild("SquirrelHUD", 60)
	if g then hookHud(g) end
end)
-- A RESET REBUILDS THE SQUIRREL HUD (Shannon, Sep 26, on her phone: "I reset my count for squirrels and the squirrel
-- inventory is open and it will not close ... the menu is also overlapping with the 3 pills at the upper right"): the
-- squirrels' own script destroys the HUD and makes a new one, open, in its old corner under these icons - and the icon was
-- still opening and closing the old one. Every new one is taken over the same way, so the icon keeps working.
pg.ChildAdded:Connect(function(c)
	if c.Name == "SquirrelHUD" and c ~= hudGui then task.defer(hookHud, c) end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel) end
local function squirrelOpen() return hudPanel and hudPanel.Visible end

-- ---------------------------------------------------------------- the map panel ----
-- a drawn parchment chart (marketing/make_map.py, uploaded as an image); the names, tallies, the "?" covers over
-- areas you have not reached and the "you are here" dot are drawn on top of it
local MAP_ID = 127000767898563
local IMG_W, IMG_H, IMG_M = 1024, 560, 26                     -- the image, and the margin its world area starts at
local DISP_W = 560                                            -- how wide the chart is drawn in the panel
local DISP_H = DISP_W * IMG_H / IMG_W
local F = DISP_W / IMG_W
local WX0, WX1, WZ0, WZ1 = -130, 700, -250, 30
local IS = math.min((IMG_W - 2 * IMG_M) / (WX1 - WX0), (IMG_H - 2 * IMG_M) / (WZ1 - WZ0))
local IOX = (IMG_W - (WX1 - WX0) * IS) / 2
local IOZ = (IMG_H - (WZ1 - WZ0) * IS) / 2
local function toMap(x, z)                                    -- world -> panel pixels
	return (IOX + (x - WX0) * IS) * F, (IOZ + (z - WZ0) * IS) * F
end

local map = Instance.new("Frame"); map.Name = "MapPanel"; map.AnchorPoint = Vector2.new(1, 0); map.Position = UDim2.new(1, -10, 0, PANEL_Y)
map.Size = UDim2.fromOffset(DISP_W + 16, DISP_H + 48); map.BackgroundColor3 = PANEL; map.BackgroundTransparency = 0.08
map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = map
local ms = Instance.new("UIStroke"); ms.Color = GOLD; ms.Thickness = 2; ms.Parent = map
local here = Instance.new("TextLabel"); here.Size = UDim2.new(1, -20, 0, 26); here.Position = UDim2.new(0, 10, 0, 6); here.BackgroundTransparency = 1
here.Font = Enum.Font.FredokaOne; here.TextSize = 17; here.TextColor3 = CREAM; here.TextXAlignment = Enum.TextXAlignment.Left
here.Text = "You are here"; here.Parent = map
local chart = Instance.new("ImageLabel"); chart.Name = "Chart"; chart.Position = UDim2.new(0, 8, 0, 36)
chart.Size = UDim2.fromOffset(DISP_W, DISP_H); chart.BackgroundTransparency = 1; chart.Image = "rbxassetid://" .. MAP_ID
chart.ScaleType = Enum.ScaleType.Stretch; chart.Parent = map
local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 8); cc2.Parent = chart

local cards = {}
for _, a in ipairs(AREAS) do
	local x0, z0 = toMap(a.x0, a.z0)
	local x1, z1 = toMap(a.x1, a.z1)
	local holder = Instance.new("Frame"); holder.Name = a.id; holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(x0, z0); holder.Size = UDim2.fromOffset(x1 - x0, z1 - z0); holder.Parent = chart
	-- the cover that hides an area you have not reached
	local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.Size = UDim2.fromScale(1, 1); cover.BackgroundColor3 = C(226, 208, 166)
	cover.BorderSizePixel = 0; cover.Parent = holder
	local cs = Instance.new("UIStroke"); cs.Color = C(150, 118, 74); cs.Thickness = 2; cs.Parent = cover
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Font = Enum.Font.Antique
	q.TextSize = 44; q.TextColor3 = C(126, 96, 58); q.Text = "?"; q.Parent = cover
	-- the name plate for an area you have reached
	local plate = Instance.new("Frame"); plate.Name = "Plate"; plate.AnchorPoint = Vector2.new(0.5, 0); plate.Position = UDim2.new(0.5, 0, 0, 4)
	plate.Size = UDim2.fromOffset(math.min(x1 - x0 - 8, 190), 34); plate.BackgroundColor3 = C(248, 240, 214); plate.BackgroundTransparency = 0.12
	plate.BorderSizePixel = 0; plate.Parent = holder
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = plate
	local pstroke = Instance.new("UIStroke"); pstroke.Color = C(150, 118, 74); pstroke.Thickness = 1; pstroke.Parent = plate
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, -6, 0, 17); title.Position = UDim2.new(0, 3, 0, 2)
	title.BackgroundTransparency = 1; title.Font = Enum.Font.Antique; title.TextSize = 15; title.TextColor3 = C(88, 58, 32)
	title.TextScaled = false; title.Parent = plate
	local tally = Instance.new("TextLabel"); tally.Name = "Tally"; tally.Size = UDim2.new(1, -6, 0, 13); tally.Position = UDim2.new(0, 3, 0, 18)
	tally.BackgroundTransparency = 1; tally.Font = Enum.Font.FredokaOne; tally.TextSize = 12; tally.TextColor3 = C(120, 84, 44); tally.Parent = plate
	cards[a.id] = {cover = cover, plate = plate, title = title, tally = tally}
end

local dot = Instance.new("Frame"); dot.Name = "You"; dot.Size = UDim2.fromOffset(13, 13); dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = C(210, 50, 50); dot.BorderSizePixel = 0; dot.ZIndex = 6; dot.Parent = chart
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
local ds = Instance.new("UIStroke"); ds.Color = C(252, 246, 230); ds.Thickness = 2; ds.Parent = dot
local ring = Instance.new("Frame"); ring.Size = UDim2.fromOffset(26, 26); ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.5)
ring.BackgroundTransparency = 1; ring.ZIndex = 5; ring.Parent = dot
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
local rs = Instance.new("UIStroke"); rs.Color = C(210, 70, 70); rs.Thickness = 2; rs.Transparency = 0.4; rs.Parent = ring

local function refreshMap()
	for _, a in ipairs(AREAS) do
		local card = cards[a.id]
		local open = unlocked(a)
		card.cover.Visible = not open
		card.plate.Visible = open
		if open then
			card.title.Text = NAME[a.id] or a.id
			local found = player:GetAttribute("Found_" .. a.id) or 0
			card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
		end
	end
end
local function refreshCount()
	local n = player:GetAttribute("SquirrelsFound") or 0
	local all = #Registry.squirrels
	countTag.Text = string.format("%d/%d", n, all)
end

-- ---------------------------------------------------------------- opening and closing ----
local function setSquirrels(open)
	if open then pg:SetAttribute("OpenPanel","collection") end
	if hudPanel then hudPanel.Visible = open end
	if open then map.Visible = false end
end
local function setMap(open)
	if open then pg:SetAttribute("OpenPanel","map") end
	map.Visible = open
	if open then refreshMap(); if hudPanel then hudPanel.Visible = false end end
end
squirrelBtn.Activated:Connect(function() setSquirrels(not squirrelOpen()) end)
mapBtn.Activated:Connect(function() setMap(not map.Visible) end)
for _, a in ipairs(AREAS) do
	if a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap)
end
player:GetAttributeChangedSignal("SquirrelsFound"):Connect(refreshCount)

-- the purse follows the Acorns attribute, which the server sets; a small pop so a pickup is felt as well as seen
local purseScale = Instance.new("UIScale"); purseScale.Parent = purse
local function refreshPurse()
	purseCount.Text = tostring(player:GetAttribute("Acorns") or 0)
end
player:GetAttributeChangedSignal("Acorns"):Connect(function()
	refreshPurse()
	purseScale.Scale = 1.22
	TweenService:Create(purseScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}):Play()
	-- a backstop: an interrupted tween once left a UIScale stuck large over the panel, and a counter frozen
	-- mid-bounce looks broken in a way that is hard to explain
	task.delay(0.6, function() if purseScale then purseScale.Scale = 1 end end)
end)
refreshPurse()
refreshCount(); refreshMap()

-- on a narrow screen (phones) the map shrinks to fit rather than covering everything
local mapScale = Instance.new("UIScale"); mapScale.Parent = map
local function fitMap()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	mapScale.Scale = math.clamp(math.min((vp.X - 30) / (DISP_W + 16), (vp.Y - PANEL_Y - 16) / (DISP_H + 48)), 0.5, 1)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMap) end
fitMap()

-- the "you are here" dot follows the player while the map is open
RunService.RenderStepped:Connect(function()
	if not map.Visible then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then dot.Visible = false; return end
	local p = root.Position
	local cx, cz = toMap(math.clamp(p.X, WX0, WX1), math.clamp(p.Z, WZ0, WZ1))
	dot.Visible = true
	dot.Position = UDim2.fromOffset(cx, cz)
	local a = areaAt(p)
	here.Text = a and ("You are here: " .. (NAME[a.id] or a.id)) or "You are here"
	rs.Transparency = 0.25 + 0.35 * math.abs(math.sin(os.clock() * 2))
end)

-- Passport entry uses the same top-right control row, without an extra floating widget.
local passportBtn = iconButton(-1,"Passport"); passportBtn.Name="Passport"
local art = require(game:GetService("ReplicatedStorage"):WaitForChild("SquirrelIllustrations"))
local illustration
local function passportCover()
 if illustration then illustration:Destroy() end
 illustration=art.draw(passportBtn,(player:GetAttribute("Item_passport_outings") or 0)>=5 and "goldpassport" or "passport",30);illustration.Position=UDim2.fromOffset(9,1)
end
local function hudCaption(parent,value)
 local l=Instance.new("TextLabel");l.Name="Caption";l.AnchorPoint=Vector2.new(.5,1);l.Position=UDim2.new(.5,0,1,-2);l.Size=UDim2.fromOffset(46,14)
 l.BackgroundTransparency=1;l.Font=Enum.Font.FredokaOne;l.TextSize=10;l.TextColor3=GOLD;l.Text=value;l.Parent=parent
end
hudCaption(passportBtn,"Passport");hudCaption(mapBtn,"Map")
passportCover();player:GetAttributeChangedSignal("Item_passport_outings"):Connect(passportCover)
passportBtn.Activated:Connect(function() game:GetService("ReplicatedStorage").PassportToggle:Fire() end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
 local active=pg:GetAttribute("OpenPanel")
 if active and active~="map" then map.Visible=false end
 if active and active~="collection" and hudPanel then hudPanel.Visible=false end
end)
]====],before=[====[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local NEED = (workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need")) or 10
local UIS = game:GetService("UserInputService")
local isMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or script.Parent:GetAttribute("ForceMobile") == true
local PANEL_Y = isMobile and 114 or 64          -- phones keep room for the Hint button under the icons
local PANEL, CREAM, GOLD, DIM = C(38, 30, 52), C(255, 246, 220), C(255, 214, 90), C(120, 110, 140)

-- ---------------------------------------------------------------- the areas ----
-- world rectangles (the same ones the boundary walls use), the order you travel them, and what unlocks each
local AREAS = {
	{id = "forest",  x0 = -130, x1 = 142, z0 = -215, z1 = 25,  needs = nil},
	{id = "village", x0 = 150,  x1 = 352, z0 = -205, z1 = 5,   needs = "forest"},
	{id = "domaine", x0 = 352,  x1 = 700, z0 = -250, z1 = 30,  needs = "village"},
}
local NAME, TOTAL = {}, {}
for _, m in ipairs(Registry.maps) do NAME[m.id] = m.name end
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local function unlocked(a) return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED end
local function areaAt(pos)
	for _, a in ipairs(AREAS) do
		if pos.X >= a.x0 and pos.X <= a.x1 and pos.Z >= a.z0 and pos.Z <= a.z1 then return a end
	end
end

-- ---------------------------------------------------------------- the bar ----
pcall(function() pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor end)         -- phones stay in landscape, either way up
for _, g in ipairs(pg:GetChildren()) do if g.Name == "HudBar" then g:Destroy() end end        -- never two bars
local gui = Instance.new("ScreenGui"); gui.Name = "HudBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg
local bar = Instance.new("Frame"); bar.Name = "Bar"; bar.AnchorPoint = Vector2.new(1, 0); bar.Position = UDim2.new(1, -10, 0, 8)
bar.Size = UDim2.fromOffset(216, 48); bar.BackgroundTransparency = 1; bar.Parent = gui
local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = bar

local function iconButton(order, tip)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = PANEL; b.BackgroundTransparency = 0.1
	b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = order; b.Parent = bar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.35; s.Parent = b
	local label = Instance.new("TextLabel"); label.Name = "Tip"; label.AnchorPoint = Vector2.new(0.5, 1); label.Position = UDim2.new(0.5, 0, 0, -4)
	label.Size = UDim2.fromOffset(96, 20); label.BackgroundColor3 = PANEL; label.BackgroundTransparency = 0.15; label.TextColor3 = CREAM
	label.Font = Enum.Font.FredokaOne; label.TextSize = 13; label.Text = tip; label.Visible = false; label.Parent = b
	local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 8); lc.Parent = label
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.35}):Play() end)
	return b, s
end
local function acorn(parent, size, cx, cy)                      -- a little acorn drawn from frames
	local nut = Instance.new("Frame"); nut.Size = UDim2.fromOffset(size * 0.62, size * 0.62); nut.Position = UDim2.fromOffset(cx - size * 0.31, cy - size * 0.18)
	nut.BackgroundColor3 = C(206, 146, 82); nut.BorderSizePixel = 0; nut.Parent = parent
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0.45, 0); nc.Parent = nut
	local cap = Instance.new("Frame"); cap.Size = UDim2.fromOffset(size * 0.78, size * 0.34); cap.Position = UDim2.fromOffset(cx - size * 0.39, cy - size * 0.40)
	cap.BackgroundColor3 = C(110, 70, 40); cap.BorderSizePixel = 0; cap.Parent = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.4, 0); cc.Parent = cap
	local stem = Instance.new("Frame"); stem.Size = UDim2.fromOffset(size * 0.12, size * 0.2); stem.Position = UDim2.fromOffset(cx - size * 0.06, cy - size * 0.56)
	stem.BackgroundColor3 = C(86, 56, 34); stem.BorderSizePixel = 0; stem.Parent = parent
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0.4, 0); sc.Parent = stem
end

-- A squirrel in profile, using the GAME'S OWN mesh rather than an approximation assembled from rounded frames.
-- The frames version came out looking like a fluffy caterpillar: at thirty pixels a tail drawn as a row of
-- circles merges with the body and the head disappears. This is the actual squirrel, lit from nowhere and
-- flattened to one colour, so it reads as a true silhouette of the thing the inventory holds.
-- The squirrels face local -Z, so a camera out along local X sees one side-on.
local function squirrelIcon(parent, size, cx, cy)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "SquirrelIcon"
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromOffset(cx, cy)
	-- square and no larger than asked: the button is 48 across and the found-count owns the bottom of it,
	-- so an icon that overruns its size sits on top of the numbers
	vp.Size = UDim2.fromOffset(size, size)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.new(1, 1, 1)                             -- no shading at all: a flat cut-out shape
	vp.LightColor = Color3.new(0, 0, 0)
	vp.Parent = parent

	task.spawn(function()
		local src
		for attempt = 1, 60 do
			for _, o in ipairs(workspace:GetDescendants()) do
				if o:IsA("Model") and o.Name:sub(-6) == "_color" then
					for _, q in ipairs(o:GetDescendants()) do
						-- skip the wide ones; those are the squirrels posed lying down
						if q:IsA("MeshPart") and q.Size.X < 2.4 then src = q break end
					end
				end
				if src then break end
			end
			if src then break end
			task.wait(0.5)                                       -- the squirrels may not have loaded in yet
		end
		if not src or not vp.Parent then return end
		local m = src:Clone()
		for _, c in ipairs(m:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
		m.TextureID = ""                                         -- no fur texture; the shape is the whole point
		m.Color = CREAM
		m.Material = Enum.Material.SmoothPlastic
		m.Transparency = 0
		m.CFrame = CFrame.new()
		m.Parent = vp
		local cam = Instance.new("Camera")
		cam.FieldOfView = 26
		cam.Parent = vp
		vp.CurrentCamera = cam
		-- close enough that the squirrel fills its corner of the bar; at thirty pixels every one counts
		cam.CFrame = CFrame.lookAt(Vector3.new(m.Size.Magnitude * 1.72, 0, 0), Vector3.new())
	end)
end

local squirrelBtn = iconButton(1, "Squirrels")
squirrelIcon(squirrelBtn, 32, 24, 17)                            -- a squirrel for the squirrels; the acorn
                                                                 -- belongs to the purse beside it
local countTag = Instance.new("TextLabel"); countTag.AnchorPoint = Vector2.new(0.5, 1); countTag.Position = UDim2.new(0.5, 0, 1, -2); countTag.Size = UDim2.fromOffset(44, 14)
countTag.BackgroundTransparency = 1; countTag.Font = Enum.Font.FredokaOne; countTag.TextSize = 13; countTag.TextColor3 = GOLD; countTag.Text = "0"; countTag.Parent = squirrelBtn
local mapBtn = iconButton(2, "Map")
do                                                               -- a folded map: three panels, a route and a pin
	for i, tint in ipairs({C(228, 216, 186), C(214, 200, 166), C(228, 216, 186)}) do
		local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(9, i == 2 and 26 or 22); p.Position = UDim2.fromOffset(10 + (i - 1) * 10, i == 2 and 10 or 13)
		p.BackgroundColor3 = tint; p.BorderSizePixel = 0; p.Parent = mapBtn
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 2); c.Parent = p
	end
	local pin = Instance.new("Frame"); pin.Size = UDim2.fromOffset(8, 8); pin.Position = UDim2.fromOffset(26, 16); pin.BackgroundColor3 = C(214, 60, 60); pin.BorderSizePixel = 0; pin.Parent = mapBtn
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pin
end

-- ---- the acorn purse: a square LEFT of the two icons, showing what you have collected ----
-- Now a button: it opens the store. LayoutOrder 0 puts it leftmost - the row is right-aligned and lays its
-- children out in order.
local purse = Instance.new("TextButton")
purse.Name = "Purse"; purse.Size = UDim2.fromOffset(48, 48); purse.BackgroundColor3 = PANEL
purse.BackgroundTransparency = 0.1; purse.BorderSizePixel = 0; purse.LayoutOrder = 0
purse.Text = ""; purse.AutoButtonColor = false; purse.Parent = bar
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = purse
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Transparency = 0.35; st.Parent = purse
end
acorn(purse, 21, 24, 14)                                         -- the same acorn as the collectible on the ground
local purseCount = Instance.new("TextLabel")
purseCount.Name = "Count"; purseCount.AnchorPoint = Vector2.new(0.5, 1); purseCount.Position = UDim2.new(0.5, 0, 1, -3)
purseCount.Size = UDim2.fromOffset(44, 17); purseCount.BackgroundTransparency = 1
purseCount.Font = Enum.Font.FredokaOne; purseCount.TextSize = 15; purseCount.TextColor3 = GOLD
purseCount.Text = "0"; purseCount.Parent = purse

-- ---------------------------------------------------------------- the squirrel panel (the existing HUD) ----
local hudGui, hudPanel
local function viewport()
	local c = workspace.CurrentCamera
	return c and c.ViewportSize or Vector2.new(1280, 720)
end
-- the squirrel panel and the squirrel card are built at a fixed pixel size; on a phone they run off the screen, so
-- each gets a UIScale that shrinks it to whatever room is left
local function fitPanel()
	if not hudPanel then return end
	local sc = hudPanel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", hudPanel)
	local vp = viewport()
	local w, h = hudPanel.Size.X.Offset, hudPanel.Size.Y.Offset
	if w <= 0 or h <= 0 then return end
	sc.Scale = math.clamp(math.min((vp.Y - PANEL_Y - 16) / h, (vp.X * 0.52) / w), 0.45, 1)
end
-- the squirrel card is built tall and narrow, which does not suit a phone held sideways. On a phone it is laid out
-- again in landscape: the portrait on the left, the name and story on the right. The card's own pop animation drives
-- its UIScale, so any size clamp has to be applied after that tween has finished.
local CARD_W, CARD_H = 646, 306
local function relayoutCard(prim)
	local big, ring, hint, title, bio
	for _, d in ipairs(prim:GetDescendants()) do
		if d:IsA("Frame") and d.Size.X.Offset == 326 then big = d
		elseif d:IsA("Frame") and d.Size.X.Offset == 288 then ring = d
		elseif d:IsA("TextLabel") then
			local y = d.Position.Y.Offset
			if y == 350 then hint = d elseif y == 368 then title = d elseif y == 414 then bio = d end
		end
	end
	prim.Size = UDim2.fromOffset(CARD_W, CARD_H)
	if big then
		big.AnchorPoint = Vector2.new(0, 0.5); big.Position = UDim2.new(0, 16, 0.5, 0); big.Size = UDim2.fromOffset(252, 252)
	end
	if ring then ring.Size = UDim2.fromOffset(228, 228); ring.Position = UDim2.new(0.5, 0, 0.5, 0) end
	if hint then hint.Position = UDim2.new(0, 16, 1, -24); hint.Size = UDim2.fromOffset(252, 16) end
	if title then title.Position = UDim2.new(0, 288, 0, 30); title.Size = UDim2.new(1, -312, 0, 42) end
	if bio then bio.Position = UDim2.new(0, 290, 0, 84); bio.Size = UDim2.new(1, -314, 1, -118) end
end
local function fitCard(card)
	for _, d in ipairs(card:GetChildren()) do
		if d:IsA("Frame") and d.AnchorPoint.X == 0.5 and d.Size.X.Offset > 200 then
			if isMobile then relayoutCard(d) end
			task.delay(0.45, function()                        -- after the card's pop-in tween has settled
				if not d.Parent then return end
				local sc = d:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", d)
				local vp = viewport()
				sc.Scale = math.clamp(math.min((vp.Y - 20) / d.Size.Y.Offset, (vp.X - 20) / d.Size.X.Offset), 0.4, 1)
			end)
		end
	end
end
-- takes charge of a squirrel HUD: its panel goes below the bar (and the Hint button on phones), closed, fitted to the screen
local function hookHud(g)
	hudGui = g
	local p = g:WaitForChild("Panel", 30)
	if not p or hudGui ~= g then return end
	hudPanel = p
	p.Position = UDim2.new(1, -10, 0, PANEL_Y)
	p.Visible = false
	p.AnchorPoint = Vector2.new(1, 0)
	fitPanel()
	p:GetPropertyChangedSignal("Size"):Connect(fitPanel)
	for _, c in ipairs(g:GetChildren()) do if c.Name == "Card" then fitCard(c) end end
	g.ChildAdded:Connect(function(c)                            -- the card is rebuilt every time one is opened
		if c.Name == "Card" then task.defer(fitCard, c) end
	end)
end
task.spawn(function()
	local g = pg:WaitForChild("SquirrelHUD", 60)
	if g then hookHud(g) end
end)
-- A RESET REBUILDS THE SQUIRREL HUD (Shannon, Sep 26, on her phone: "I reset my count for squirrels and the squirrel
-- inventory is open and it will not close ... the menu is also overlapping with the 3 pills at the upper right"): the
-- squirrels' own script destroys the HUD and makes a new one, open, in its old corner under these icons - and the icon was
-- still opening and closing the old one. Every new one is taken over the same way, so the icon keeps working.
pg.ChildAdded:Connect(function(c)
	if c.Name == "SquirrelHUD" and c ~= hudGui then task.defer(hookHud, c) end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel) end
local function squirrelOpen() return hudPanel and hudPanel.Visible end

-- ---------------------------------------------------------------- the map panel ----
-- a drawn parchment chart (marketing/make_map.py, uploaded as an image); the names, tallies, the "?" covers over
-- areas you have not reached and the "you are here" dot are drawn on top of it
local MAP_ID = 127000767898563
local IMG_W, IMG_H, IMG_M = 1024, 560, 26                     -- the image, and the margin its world area starts at
local DISP_W = 560                                            -- how wide the chart is drawn in the panel
local DISP_H = DISP_W * IMG_H / IMG_W
local F = DISP_W / IMG_W
local WX0, WX1, WZ0, WZ1 = -130, 700, -250, 30
local IS = math.min((IMG_W - 2 * IMG_M) / (WX1 - WX0), (IMG_H - 2 * IMG_M) / (WZ1 - WZ0))
local IOX = (IMG_W - (WX1 - WX0) * IS) / 2
local IOZ = (IMG_H - (WZ1 - WZ0) * IS) / 2
local function toMap(x, z)                                    -- world -> panel pixels
	return (IOX + (x - WX0) * IS) * F, (IOZ + (z - WZ0) * IS) * F
end

local map = Instance.new("Frame"); map.Name = "MapPanel"; map.AnchorPoint = Vector2.new(1, 0); map.Position = UDim2.new(1, -10, 0, PANEL_Y)
map.Size = UDim2.fromOffset(DISP_W + 16, DISP_H + 48); map.BackgroundColor3 = PANEL; map.BackgroundTransparency = 0.08
map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = map
local ms = Instance.new("UIStroke"); ms.Color = GOLD; ms.Thickness = 2; ms.Parent = map
local here = Instance.new("TextLabel"); here.Size = UDim2.new(1, -20, 0, 26); here.Position = UDim2.new(0, 10, 0, 6); here.BackgroundTransparency = 1
here.Font = Enum.Font.FredokaOne; here.TextSize = 17; here.TextColor3 = CREAM; here.TextXAlignment = Enum.TextXAlignment.Left
here.Text = "You are here"; here.Parent = map
local chart = Instance.new("ImageLabel"); chart.Name = "Chart"; chart.Position = UDim2.new(0, 8, 0, 36)
chart.Size = UDim2.fromOffset(DISP_W, DISP_H); chart.BackgroundTransparency = 1; chart.Image = "rbxassetid://" .. MAP_ID
chart.ScaleType = Enum.ScaleType.Stretch; chart.Parent = map
local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 8); cc2.Parent = chart

local cards = {}
for _, a in ipairs(AREAS) do
	local x0, z0 = toMap(a.x0, a.z0)
	local x1, z1 = toMap(a.x1, a.z1)
	local holder = Instance.new("Frame"); holder.Name = a.id; holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(x0, z0); holder.Size = UDim2.fromOffset(x1 - x0, z1 - z0); holder.Parent = chart
	-- the cover that hides an area you have not reached
	local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.Size = UDim2.fromScale(1, 1); cover.BackgroundColor3 = C(226, 208, 166)
	cover.BorderSizePixel = 0; cover.Parent = holder
	local cs = Instance.new("UIStroke"); cs.Color = C(150, 118, 74); cs.Thickness = 2; cs.Parent = cover
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Font = Enum.Font.Antique
	q.TextSize = 44; q.TextColor3 = C(126, 96, 58); q.Text = "?"; q.Parent = cover
	-- the name plate for an area you have reached
	local plate = Instance.new("Frame"); plate.Name = "Plate"; plate.AnchorPoint = Vector2.new(0.5, 0); plate.Position = UDim2.new(0.5, 0, 0, 4)
	plate.Size = UDim2.fromOffset(math.min(x1 - x0 - 8, 190), 34); plate.BackgroundColor3 = C(248, 240, 214); plate.BackgroundTransparency = 0.12
	plate.BorderSizePixel = 0; plate.Parent = holder
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = plate
	local pstroke = Instance.new("UIStroke"); pstroke.Color = C(150, 118, 74); pstroke.Thickness = 1; pstroke.Parent = plate
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, -6, 0, 17); title.Position = UDim2.new(0, 3, 0, 2)
	title.BackgroundTransparency = 1; title.Font = Enum.Font.Antique; title.TextSize = 15; title.TextColor3 = C(88, 58, 32)
	title.TextScaled = false; title.Parent = plate
	local tally = Instance.new("TextLabel"); tally.Name = "Tally"; tally.Size = UDim2.new(1, -6, 0, 13); tally.Position = UDim2.new(0, 3, 0, 18)
	tally.BackgroundTransparency = 1; tally.Font = Enum.Font.FredokaOne; tally.TextSize = 12; tally.TextColor3 = C(120, 84, 44); tally.Parent = plate
	cards[a.id] = {cover = cover, plate = plate, title = title, tally = tally}
end

local dot = Instance.new("Frame"); dot.Name = "You"; dot.Size = UDim2.fromOffset(13, 13); dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = C(210, 50, 50); dot.BorderSizePixel = 0; dot.ZIndex = 6; dot.Parent = chart
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
local ds = Instance.new("UIStroke"); ds.Color = C(252, 246, 230); ds.Thickness = 2; ds.Parent = dot
local ring = Instance.new("Frame"); ring.Size = UDim2.fromOffset(26, 26); ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.5)
ring.BackgroundTransparency = 1; ring.ZIndex = 5; ring.Parent = dot
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
local rs = Instance.new("UIStroke"); rs.Color = C(210, 70, 70); rs.Thickness = 2; rs.Transparency = 0.4; rs.Parent = ring

local function refreshMap()
	for _, a in ipairs(AREAS) do
		local card = cards[a.id]
		local open = unlocked(a)
		card.cover.Visible = not open
		card.plate.Visible = open
		if open then
			card.title.Text = NAME[a.id] or a.id
			local found = player:GetAttribute("Found_" .. a.id) or 0
			card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
		end
	end
end
local function refreshCount()
	local n = player:GetAttribute("SquirrelsFound") or 0
	local all = #Registry.squirrels
	countTag.Text = string.format("%d/%d", n, all)
end

-- ---------------------------------------------------------------- opening and closing ----
local function setSquirrels(open)
	if open then pg:SetAttribute("OpenPanel","collection") end
	if hudPanel then hudPanel.Visible = open end
	if open then map.Visible = false end
end
local function setMap(open)
	if open then pg:SetAttribute("OpenPanel","map") end
	map.Visible = open
	if open then refreshMap(); if hudPanel then hudPanel.Visible = false end end
end
squirrelBtn.Activated:Connect(function() setSquirrels(not squirrelOpen()) end)
mapBtn.Activated:Connect(function() setMap(not map.Visible) end)
for _, a in ipairs(AREAS) do
	if a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap)
end
player:GetAttributeChangedSignal("SquirrelsFound"):Connect(refreshCount)

-- the purse follows the Acorns attribute, which the server sets; a small pop so a pickup is felt as well as seen
local purseScale = Instance.new("UIScale"); purseScale.Parent = purse
local function refreshPurse()
	purseCount.Text = tostring(player:GetAttribute("Acorns") or 0)
end
player:GetAttributeChangedSignal("Acorns"):Connect(function()
	refreshPurse()
	purseScale.Scale = 1.22
	TweenService:Create(purseScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}):Play()
	-- a backstop: an interrupted tween once left a UIScale stuck large over the panel, and a counter frozen
	-- mid-bounce looks broken in a way that is hard to explain
	task.delay(0.6, function() if purseScale then purseScale.Scale = 1 end end)
end)
refreshPurse()
refreshCount(); refreshMap()

-- on a narrow screen (phones) the map shrinks to fit rather than covering everything
local mapScale = Instance.new("UIScale"); mapScale.Parent = map
local function fitMap()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	mapScale.Scale = math.clamp(math.min((vp.X - 30) / (DISP_W + 16), (vp.Y - PANEL_Y - 16) / (DISP_H + 48)), 0.5, 1)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMap) end
fitMap()

-- the "you are here" dot follows the player while the map is open
RunService.RenderStepped:Connect(function()
	if not map.Visible then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then dot.Visible = false; return end
	local p = root.Position
	local cx, cz = toMap(math.clamp(p.X, WX0, WX1), math.clamp(p.Z, WZ0, WZ1))
	dot.Visible = true
	dot.Position = UDim2.fromOffset(cx, cz)
	local a = areaAt(p)
	here.Text = a and ("You are here: " .. (NAME[a.id] or a.id)) or "You are here"
	rs.Transparency = 0.25 + 0.35 * math.abs(math.sin(os.clock() * 2))
end)

-- Passport entry uses the same top-right control row, without an extra floating widget.
local passportBtn = iconButton(-1,"Passport"); passportBtn.Name="Passport"
local art = require(game:GetService("ReplicatedStorage"):WaitForChild("SquirrelIllustrations"))
local illustration
local function passportCover()
 if illustration then illustration:Destroy() end
 illustration=art.draw(passportBtn,(player:GetAttribute("Item_passport_outings") or 0)>=5 and "goldpassport" or "passport",42);illustration.Position=UDim2.fromOffset(3,3)
end
passportCover();player:GetAttributeChangedSignal("Item_passport_outings"):Connect(passportCover)
passportBtn.Activated:Connect(function() game:GetService("ReplicatedStorage").PassportToggle:Fire() end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
 local active=pg:GetAttribute("OpenPanel")
 if active and active~="map" then map.Visible=false end
 if active and active~="collection" and hudPanel then hudPanel.Visible=false end
end)
]====]})
table.insert(changes,{target=workspace.Lagoon.CrocServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local L = script.Parent
local croc = L:WaitForChild("Croc")
local evt = L:WaitForChild("CrocEvent")
local cages = L:WaitForChild("Cages")
local award = RS:WaitForChild("AwardAcorns", 30)
local items = RS:WaitForChild("AwardItems", 30)
local picked = RS:FindFirstChild("AcornPicked")
local function A(n, d) local v = L:GetAttribute(n); if v == nil then return d end return v end
local function now() return workspace:GetServerTimeNow() end
local rng = Random.new()

-- the lagoon
local WATER_Y = A("WaterY", -1)
local LOBES = {}
for x, z, r in string.gmatch(A("Lobes", ""), "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do table.insert(LOBES, {tonumber(x), tonumber(z), tonumber(r)}) end
local IX, IZ, IR = A("IslandX", 118), A("IslandZ", -181), A("IslandR", 6.5)
local function sdfWater(x, z) local b = -math.huge for _, l in ipairs(LOBES) do b = math.max(b, l[3] - math.sqrt((x - l[1]) ^ 2 + (z - l[2]) ^ 2)) end return b end
local function sdfIsland(x, z) return IR - math.sqrt((x - IX) ^ 2 + (z - IZ) ^ 2) end
-- where he naps (the lobe nearest the path's west) and sulks (the lobe farthest from the path)
local function lobeFarthestFrom(px, pz, nearest)
	local best, bd = LOBES[1], nil
	for i, l in ipairs(LOBES) do
		if i > 1 then
			local d = (l[1] - px) ^ 2 + (l[2] - pz) ^ 2
			if not bd or (nearest and d < bd) or (not nearest and d > bd) then best, bd = l, d end
		end
	end
	return best
end
local SIGN_X, SIGN_Z = A("SignX", 104), A("SignZ", -147)
local napLobe = lobeFarthestFrom(SIGN_X - 20, SIGN_Z - 53, true)   -- the north-west arm, away from the path in and the log
local napX, napZ = napLobe[1], napLobe[2]
local sulkLobe = lobeFarthestFrom(SIGN_X, SIGN_Z, false)
local SPITS = {}
for x, z in string.gmatch(A("SpitSpots", ""), "([%-%d%.]+),([%-%d%.]+)") do table.insert(SPITS, Vector3.new(tonumber(x), 0.2, tonumber(z))) end
if #SPITS == 0 then SPITS = {Vector3.new(112, 0.2, -142)} end

-- the croc's measurements (studs, his own frame: bottom centre, facing -Z)
local SINK = croc:GetAttribute("SwimSink") or 2.3
local SNOUT = croc:GetAttribute("SnoutOffset") or Vector3.new(0, 2.8, -6.3)
local TAILB = croc:GetAttribute("TailBaseOffset") or Vector3.new(0, 1.6, 3.4)
local TAILT = croc:GetAttribute("TailTipOffset") or Vector3.new(-0.7, 3.4, 5.8)
local BODY_R = croc:GetAttribute("BodyRadius") or 1.8
-- the snout tip and both sides of his head: none of them may reach the island (Shannon: "his snout actually goes into
-- the hill")
local HEAD_PTS = {SNOUT, SNOUT + Vector3.new(1.1, 0, 2.2), SNOUT + Vector3.new(-1.1, 0, 2.2), SNOUT + Vector3.new(1.4, 0, 4.2), SNOUT + Vector3.new(-1.4, 0, 4.2)}
-- THE LOG IS SOLID (Shannon: "the croc still goes through the log with his tail and his snout"): its footprint on the
-- water (written by the lagoon builder) may not hold any part of him - snout, head, body, tail - so he swims round it,
-- and a turn that would swing his snout or tail into it doesn't happen
local LOG = nil
do
	local c, ax, ha, hb = L:GetAttribute("LogCenter"), L:GetAttribute("LogAxis"), L:GetAttribute("LogHalfA"), L:GetAttribute("LogHalfB")
	if typeof(c) == "Vector3" and typeof(ax) == "Vector3" and ha and hb then
		local a = Vector3.new(ax.X, 0, ax.Z).Unit
		LOG = {c = c, a = a, b = Vector3.new(-a.Z, 0, a.X), ha = ha, hb = hb}
	end
end
local BODY_PTS = {{SNOUT, 0.6}, {SNOUT + Vector3.new(0, 0, 2.4), 1.2}, {Vector3.new(0, 0, SNOUT.Z * 0.45), 1.8},
	{Vector3.new(0, 0, 0), 2.0}, {Vector3.new(0, 0, -SNOUT.Z * 0.3), 1.9}, {TAILB, 1.3}, {(TAILB + TAILT) / 2, 1.0}, {TAILT, 0.8}}
local function hitsLog(f)
	if not LOG then return false end
	for _, bp in ipairs(BODY_PTS) do
		local w = f * bp[1]
		local d = Vector3.new(w.X - LOG.c.X, 0, w.Z - LOG.c.Z)
		if math.abs(d:Dot(LOG.a)) < LOG.ha + bp[2] and math.abs(d:Dot(LOG.b)) < LOG.hb + bp[2] then return true end
	end
	return false
end
-- (with the log in the nap arm, he naps in the part of it farthest from the log)
if LOG then
	local bestD = -1
	for gx = -4, 4 do
		for gz = -4, 4 do
			local px, pz = napLobe[1] + gx, napLobe[2] + gz
			if sdfWater(px, pz) >= 3.5 and sdfIsland(px, pz) < -6 then
				local dd = Vector3.new(px - LOG.c.X, 0, pz - LOG.c.Z).Magnitude
				if dd > bestD then bestD, napX, napZ = dd, px, pz end
			end
		end
	end
end

local x, z, yaw = croc:GetAttribute("HomeX"), croc:GetAttribute("HomeZ"), croc:GetAttribute("HomeYaw") or 0
local function frameAt(px, pz, pyaw) return CFrame.new(px, WATER_Y - SINK, pz) * CFrame.Angles(0, pyaw, 0) end
local function snoutAt(px, pz, pyaw) return frameAt(px, pz, pyaw) * SNOUT end
-- WHERE TO AIM (SlingServer asks when someone near him shoots): the top of his head between the eyes, and how fast he's
-- going, so the acorn can be sent to where he'll be when it lands
local AIM_OFF = SNOUT + Vector3.new(0, 0.6, 3.0)
local velX, velZ, lastVX, lastVZ, lastVT = 0, 0, nil, nil, nil
local aimFn = L:FindFirstChild("CrocAim")
if not aimFn then aimFn = Instance.new("BindableFunction"); aimFn.Name = "CrocAim"; aimFn.Parent = L end
aimFn.OnInvoke = function() return frameAt(x, z, yaw) * AIM_OFF, Vector3.new(velX, 0, velZ) end

local state, stateAt, target = "patrol", now(), nil
local lastMoved = 0
local function setState(s, who)
	if s == "chase" and state ~= "lunge" then lastMoved = now() end   -- (snaps at the air don't reset his patience)
	state = s; stateAt = now(); target = who
	croc:SetAttribute("State", s); croc:SetAttribute("StateAt", stateAt % 4096)
	croc:SetAttribute("Target", who and who.UserId or 0)
end
setState("patrol")

-- ---- who's in his lagoon
local immune, held, ignoreUntil = {}, {}, {}
local function hrpOf(p) local c = p.Character; local h = c and c:FindFirstChild("HumanoidRootPart"); local hum = c and c:FindFirstChildOfClass("Humanoid"); if h and hum and hum.Health > 0 then return h end end
local function inLagoon(pos)
	if pos.Y > WATER_Y + 7 or pos.Y < WATER_Y - 12 then return false end
	if sdfIsland(pos.X, pos.Z) > -0.8 then return true end
	return sdfWater(pos.X, pos.Z) > -1.0
end
local function intruder(maxDist)
	local s = snoutAt(x, z, yaw)
	local best, bd = nil, maxDist or math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and not held[p] and (immune[p] or 0) < now() and (ignoreUntil[p] or 0) < now() and inLagoon(h.Position) then
			local d = (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(s.X, 0, s.Z)).Magnitude
			if d < bd then best, bd = p, d end
		end
	end
	return best, bd
end

-- ---- moving: he goes where he faces, turns at TurnRate, keeps off the island and in the water
-- THE GROUND UNDER HIS HEAD (Shannon, twice: "his nose is in the hill again"). The water's outline is only an outline:
-- the bank's grass slopes up out of the water inside it, and the first rule let the snout 2.5 studs past it - onto the
-- grass. Now the real terrain height is looked up (a raycast per stud of ground, remembered) and his snout and the
-- sides of his head must stay over water, the bed below them under the surface.
local bedRp = RaycastParams.new(); bedRp.FilterType = Enum.RaycastFilterType.Include; bedRp.IgnoreWater = true
bedRp.FilterDescendantsInstances = {workspace.Terrain, workspace:FindFirstChild("Baseplate")}
local bedCache = {}
local function bedCell(cx, cz)
	local col = bedCache[cx]; if not col then col = {}; bedCache[cx] = col end
	local v = col[cz]
	if v == nil then
		local r = workspace:Raycast(Vector3.new(cx, WATER_Y + 14, cz), Vector3.new(0, -40, 0), bedRp)
		v = r and r.Position.Y or (WATER_Y - 20)
		col[cz] = v
	end
	return v
end
local function bedH(px, pz)
	local cx, cz = math.floor(px), math.floor(pz)
	local fx, fz = px - cx, pz - cz
	local a, b, c, d = bedCell(cx, cz), bedCell(cx + 1, cz), bedCell(cx, cz + 1), bedCell(cx + 1, cz + 1)
	return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz
end
local function headClear(f)
	local sn = f * SNOUT
	if bedH(sn.X, sn.Z) > WATER_Y - A("SnoutDepth", 0.45) then return false end
	for i = 2, #HEAD_PTS do
		local q = f * HEAD_PTS[i]
		if bedH(q.X, q.Z) > WATER_Y - A("HeadDepth", 0.25) then return false end
	end
	return true
end
local function okAt(px, pz, pyaw, margin)
	if sdfWater(px, pz) < margin then return false end
	if sdfIsland(px, pz) > -2.6 then return false end
	local f = frameAt(px, pz, pyaw)
	if hitsLog(f) then return false end
	for i, o in ipairs(HEAD_PTS) do
		local q = f * o
		-- his head stays clear of the island: the terrain's slope reaches further out than the waterline (a stud off
		-- still touched the grass), so the snout keeps 2.6 studs off, the sides of his head 2
		if sdfIsland(q.X, q.Z) > (i == 1 and -2.6 or -2.0) then return false end
	end
	return headClear(f)                                              -- and over water, not on the bank
end
local function turnToward(want, dt)
	local d = (want - yaw + math.pi) % (2 * math.pi) - math.pi
	local m = math.rad(A("TurnRate", 150)) * dt
	local ny = yaw + math.clamp(d, -m, m)
	if LOG and hitsLog(frameAt(x, z, ny)) and not hitsLog(frameAt(x, z, yaw)) then return math.abs(d) end   -- not into the log
	-- nor his nose into the bank: he backs off a touch instead, and the turn comes when there's room
	if not headClear(frameAt(x, z, ny)) and headClear(frameAt(x, z, yaw)) then
		local bx, bz = x + math.sin(yaw) * 0.12, z + math.cos(yaw) * 0.12
		if okAt(bx, bz, yaw, 0.3) then x, z = bx, bz end
		return math.abs(d)
	end
	yaw = ny
	return math.abs(d)
end
local detourSide = nil
local waypoint = nil                                              -- {x, z, until}: a stop on the way, when he was stuck
local tried = false                                               -- he wanted to move this tick
local function aimAround(tx, tz)                                   -- round the island rather than through it
	if waypoint then
		if Vector3.new(waypoint[1] - x, 0, waypoint[2] - z).Magnitude < 1.5 or now() > waypoint[3] then waypoint = nil
		else return waypoint[1], waypoint[2] end
	end
	local Rr = IR + 4.2
	local px, pz, qx, qz = x - IX, z - IZ, tx - IX, tz - IZ
	local dx, dz = qx - px, qz - pz
	local len2 = dx * dx + dz * dz
	if len2 < 1e-4 then detourSide = nil return tx, tz end
	local t = math.clamp(-(px * dx + pz * dz) / len2, 0, 1)
	-- nearest approach where he already is (heading away) or at the target itself (a player on the island): straight on
	if t <= 0.03 or t >= 0.97 then detourSide = nil return tx, tz end
	local cx, cz = px + dx * t, pz + dz * t
	if cx * cx + cz * cz >= Rr * Rr then detourSide = nil return tx, tz end
	-- the side is chosen once and kept until the way is clear (a target straight across made him dither)
	if not detourSide then detourSide = (px * qz - pz * qx) >= 0 and 1 or -1 end
	local a = math.atan2(pz, px) + detourSide * math.rad(50)
	local r = math.clamp(math.sqrt(px * px + pz * pz), Rr + 0.5, math.max(A("PatrolRadius", 12), Rr + 0.5))
	return IX + math.cos(a) * r, IZ + math.sin(a) * r
end
local function moveToward(tx, tz, speed, dt, margin)
	local ax, az = aimAround(tx, tz)
	local dx, dz = ax - x, az - z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.25 then return dist end
	tried = true
	local offBy = turnToward(math.atan2(-dx, -dz), dt)
	local step = math.min(dist, speed * dt * math.clamp(1.2 - offBy / math.rad(80), 0.12, 1))
	for _, a in ipairs({0, 0.45, -0.45, 0.9, -0.9}) do
		local fx, fz = -math.sin(yaw + a), -math.cos(yaw + a)
		local nx, nz = x + fx * step * (a == 0 and 1 or 0.7), z + fz * step * (a == 0 and 1 or 0.7)
		if okAt(nx, nz, yaw, margin) then x, z = nx, nz break end
	end
	return dist
end

-- ---- acorns
local hourly = {}
local function pay(player, n, from)
	if n <= 0 then return end
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + n)
	if award then award:Fire(player, n) end
	if picked and from then picked:FireClient(player, have + n, from, n) end      -- n acorns fly to the purse
end

-- ---- slingshot bonks: every shot acorn is followed; a line from frame to frame that crosses his body is a hit
local shots, bonks = {}, {}
local fleeHourly = {}
local flinchUntil = -1                                            -- a bonk stops him dead for a moment
local function segDist(p1, q1, p2, q2)                           -- closest distance between two segments
	local d1, d2, r = q1 - p1, q2 - p2, p1 - p2
	local a, e, f = d1:Dot(d1), d2:Dot(d2), d2:Dot(r)
	local sN, tN
	if a <= 1e-6 and e <= 1e-6 then return r.Magnitude end
	if a <= 1e-6 then sN = 0; tN = math.clamp(f / e, 0, 1)
	else
		local c = d1:Dot(r)
		if e <= 1e-6 then tN = 0; sN = math.clamp(-c / a, 0, 1)
		else
			local b = d1:Dot(d2); local den = a * e - b * b
			sN = den ~= 0 and math.clamp((b * f - c * e) / den, 0, 1) or 0
			tN = (b * sN + f) / e
			if tN < 0 then tN = 0; sN = math.clamp(-c / a, 0, 1) elseif tN > 1 then tN = 1; sN = math.clamp((b - c) / a, 0, 1) end
		end
	end
	return ((p1 + d1 * sN) - (p2 + d2 * tN)).Magnitude
end
local function hitsCroc(a, b)
	local f = frameAt(x, z, yaw)
	local sn, tb, tt = f * SNOUT, f * TAILB, f * TAILT
	return segDist(a, b, sn, tb) < BODY_R + 0.7 or segDist(a, b, tb, tt) < BODY_R * 0.55 + 0.6
end
workspace.ChildAdded:Connect(function(c)
	if c.Name ~= "ShotAcorn" then return end
	task.defer(function()
		local nut = c.PrimaryPart or c:FindFirstChild("Nut") or c:FindFirstChildWhichIsA("BasePart")
		if not nut then return end
		local id = nut:GetAttribute("ShooterId") or c:GetAttribute("ShooterId")
		local shooter = id and Players:GetPlayerByUserId(id)
		if not shooter then
			local bd = 7
			for _, p in ipairs(Players:GetPlayers()) do
				local h = p.Character and p.Character:FindFirstChild("Head")
				if h and (h.Position - nut.Position).Magnitude < bd then shooter, bd = p, (h.Position - nut.Position).Magnitude end
			end
		end
		shots[nut] = {model = c, last = nut.Position, shooter = shooter, born = os.clock()}
	end)
end)
local function bonk(shooter, at)
	local t = now()
	if shooter then pay(shooter, A("BonkPrize", 1), at) end
	local counts = not (state == "dizzy" or state == "sulk" or state == "hold" or state == "spit")
	if counts then
		for i = #bonks, 1, -1 do if t - bonks[i] > A("BonkWindow", 25) then table.remove(bonks, i) end end
		table.insert(bonks, t)
	end
	local n, need = counts and #bonks or 0, A("BonksToFlee", 3)
	-- EVERY BONK SHOWS (Shannon: "he does not react when you bonk him"): he flinches on every screen (CrocClient), and
	-- stops dead for a moment - a bonk buys a chased player a second; the shooter sees how many more it takes
	evt:FireAllClients("bonk", at, shooter and shooter.UserId or 0, n, need)
	print(string.format("CrocServer: bonk by %s - %d of %d (%s)", shooter and shooter.Name or "?", n, need, state))
	if not counts then return end
	flinchUntil = t + 0.7
	if n >= need then
		bonks = {}
		if shooter then
			-- capped per hour like the rescues: a slingshot that flies at his head must not be an acorn farm
			local list = fleeHourly[shooter] or {}; fleeHourly[shooter] = list
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			if #list < A("FleeCap", 3) then table.insert(list, t); pay(shooter, A("FleePrize", 3), at) end
			evt:FireClient(shooter, "fled")
		end
		setState("dizzy")
	elseif state == "nap" or state == "tonap" then
		setState("patrol")
	end
end

-- ---- the chomp
local function chomp(victim)
	held[victim] = true
	setState("hold", victim)
	evt:FireClient(victim, "chomp", A("HoldTime", 1.7))
	evt:FireAllClients("chompfx", victim.UserId)
end
local function spit(victim)
	held[victim] = nil
	local best, bd = SPITS[1], math.huge
	local s = snoutAt(x, z, yaw)
	for _, p in ipairs(SPITS) do
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(s.X, 0, s.Z)).Magnitude + rng:NextNumber(0, 6)
		if d < bd then best, bd = p, d end
	end
	local flight = math.clamp(bd / 26, 0.8, 1.6)
	immune[victim] = now() + flight + A("Immune", 6)
	if victim.Parent then evt:FireClient(victim, "spit", best, flight) end
	evt:FireAllClients("spitfx", victim.UserId, flight)
	setState("smug")
end

-- ---- rescues
local rescues = {}
local roundRescuers = {}                                          -- names of whoever freed squirrels since the last full set
-- PRAISE (Shannon): after a rescue, the next squirrel you walk by says "Thank you for saving Madame Margaux's petits
-- enfants!" and the one after that "<name> is a hero! Yay for <name>!". The rescuer's screen picks the squirrel; the
-- server checks it (a tagged squirrel, near them, a different one, not too soon) and everyone nearby sees the bubble.
local CS = game:GetService("CollectionService")
local heroes = {}
evt.OnServerEvent:Connect(function(player, kind, model)
	if kind ~= "praise" then return end
	local h = heroes[player]
	if not h or typeof(model) ~= "Instance" or not model:IsA("Model") or not CS:HasTag(model, "Squirrel") or model == h.last then return end
	local t = now()
	if t - h.at < 3 then return end
	local hr = hrpOf(player)
	local ok, pos = pcall(function() return model:GetPivot().Position end)
	if not hr or not ok or (pos - hr.Position).Magnitude > 26 then return end
	local name = player.DisplayName
	local text = h.stage == 1 and "Thank you for saving Madame Margaux's petits enfants!" or string.format("%s is a hero! Yay for %s!", name, name)
	evt:FireAllClients("praise", model, text)
	evt:FireClient(player, "praiseok", h.stage)                   -- the rescuer's screen moves on only when this comes
	h.stage += 1; h.at = t; h.last = model
	if h.stage > 2 then heroes[player] = nil end
end)
local function openCount(cage) return cage:GetAttribute("Occupied") end
for _, cage in ipairs(cages:GetChildren()) do
	local pp = cage:FindFirstChild("RescuePrompt", true)
	if pp then
		pp.Enabled = cage:GetAttribute("Occupied") == true and cage:GetAttribute("HasCaptive") == true
		pp.Triggered:Connect(function(player)
			if not cage:GetAttribute("Occupied") then return end
			local h = hrpOf(player)
			local spot = pp.Parent
			if not h or (h.Position - spot.Position).Magnitude > 10 then return end
			local t = now()
			local list = rescues[player] or {}
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			rescues[player] = list
			cage:SetAttribute("Occupied", false); pp.Enabled = false
			evt:FireAllClients("rescued", cage.Name, player.UserId)
			local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"rescue",{}) end
			-- ALL THREE FREE (Shannon: "there should be some kind of toast after all 3 squirrels are free"): everyone in
			-- the game gets the toast, naming whoever freed them this time round
			local nm = player.DisplayName
			local seen = false
			for _, n in ipairs(roundRescuers) do if n == nm then seen = true end end
			if not seen then table.insert(roundRescuers, nm) end
			local allFree = true
			for _, c in ipairs(cages:GetChildren()) do if c:GetAttribute("Occupied") then allFree = false end end
			if allFree then
				local names = roundRescuers
				roundRescuers = {}
				task.delay(1.3, function() evt:FireAllClients("allfree", names) end)     -- after the last one's hop out
			end
			if #list < A("RescueCap", 20) then
				table.insert(list, t)
				pay(player, A("RescuePrize", 5), spot.Position)
				if items then items:Fire(player, "croc_rescues", 1) end
				if not heroes[player] then heroes[player] = {stage = 1, at = now(), last = nil} end
			else
				evt:FireClient(player, "capped")
			end
			-- he's not having it
			if state == "patrol" or state == "nap" or state == "tonap" or state == "smug" or state == "guard" then setState("chase", player) end
			task.delay(A("RespawnSeconds", 90), function()
				while true do
					local busy = false
					for _, p in ipairs(Players:GetPlayers()) do
						local hh = hrpOf(p)
						if hh and (Vector3.new(hh.Position.X, 0, hh.Position.Z) - Vector3.new(IX, 0, IZ)).Magnitude < 16 then busy = true end
					end
					if not busy then break end
					task.wait(3)
				end
				cage:SetAttribute("Occupied", true)
				pp.Enabled = cage:GetAttribute("HasCaptive") == true
			end)
		end)
	end
end

-- ---- the brain: 20 times a second; the pose goes out 10 times a second
local ringDir, ringAng = 1, math.atan2(z - IZ, x - IX)
local nextStop, nextNap = now() + rng:NextNumber(12, 22), now() + A("NapEvery", 70) * rng:NextNumber(0.6, 1.1)
local seenSince, lostSince, lungeReady = nil, nil, 0
local stuckT, stuckAt
local lungeFrom
local acc, pubAcc = 0, 0
RunService.Heartbeat:Connect(function(dtFrame)
	-- shots first (every frame: a fast acorn crosses him between ticks)
	for nut, sh in pairs(shots) do
		if not nut.Parent or os.clock() - sh.born > 10 then shots[nut] = nil
		else
			local cur = nut.Position
			if hitsCroc(sh.last, cur) then
				shots[nut] = nil
				local at = cur
				sh.model:Destroy()
				bonk(sh.shooter, at)
			else sh.last = cur end
		end
	end
	acc += dtFrame
	if acc < 0.05 then return end
	local dt = math.min(acc, 0.2); acc = 0
	local t = now()
	local since = t - stateAt
	local R = A("PatrolRadius", 12)
	local slow = math.clamp((t - flinchUntil) / 0.5, 0, 1)         -- 0 while he's flinching from a bonk, back to 1 in half a second

	if state == "patrol" or state == "guard" then
		local who = intruder(60)
		if who then
			seenSince = seenSince or t
			if t - seenSince > A("NoticeDelay", 0.6) then seenSince = nil; setState("chase", who) end
		else seenSince = nil end
		if state == "patrol" then
			local lead = math.rad(30)
			ringAng = math.atan2(z - IZ, x - IX) + ringDir * lead
			local r2 = R / math.cos(lead)                           -- chasing a point this far out settles him on the ring
			moveToward(IX + math.cos(ringAng) * r2, IZ + math.sin(ringAng) * r2, A("SwimSpeed", 4.5) * slow, dt, 2.2)
			if t > nextStop then setState("guard"); nextStop = t + rng:NextNumber(14, 26) end
			if t > nextNap then setState("tonap") end
		elseif state == "guard" then
			-- a look-out: turn to face out over the lagoon, then carry on (sometimes the other way round)
			local out = math.atan2(-(x - IX), -(z - IZ))            -- the island at his back, looking out at the shore
			turnToward(out, dt * 0.5)
			if since > 4.5 then
				if rng:NextNumber() < 0.35 then ringDir = -ringDir end
				setState("patrol")
			end
		end
	elseif state == "tonap" then
		local d = moveToward(napX, napZ, A("SwimSpeed", 4.5) * slow, dt, 1.6)
		if d < 1.2 or since > 25 then setState("nap") end
	elseif state == "nap" then
		local who, dist = intruder(A("WakeRadius", 4.5) + 3)
		if who then setState("chase", who)
		elseif since > A("NapSeconds", 22) then nextNap = t + A("NapEvery", 70) * rng:NextNumber(0.8, 1.3); setState("patrol") end
	elseif state == "chase" then
		local h = target and hrpOf(target)
		if not h or held[target] or (immune[target] or 0) > t then setState("patrol")
		else
			if not inLagoon(h.Position) then
				lostSince = lostSince or t
				if t - lostSince > 1.5 then lostSince = nil; setState("guard") end
			else lostSince = nil end
			if state == "chase" then
				local bx, bz = x, z
				moveToward(h.Position.X, h.Position.Z, A("ChaseSpeed", 9.5) * slow, dt, 1.0)
				if t < flinchUntil then lastMoved = t end                -- (stopped by a bonk, not by the bank)
				if Vector3.new(x - bx, 0, z - bz).Magnitude > 0.05 then lastMoved = t end
				local s = snoutAt(x, z, yaw)
				local flat = Vector3.new(h.Position.X - s.X, 0, h.Position.Z - s.Z).Magnitude
				local blocked = t - lastMoved > 0.8                    -- at the island's edge (or the bank) and can't get nearer
				if flat < A("Reach", 3.4) and math.abs(h.Position.Y - s.Y) < 5 and t > lungeReady and t > flinchUntil then
					lungeFrom = Vector3.new(x, 0, z); setState("lunge", target)
				elseif blocked and flat < A("Reach", 3.4) + 3.5 and t > lungeReady + 2.2 then
					-- just out of reach: a snap at the air anyway (a miss, a splash)
					lungeFrom = Vector3.new(x, 0, z); setState("lunge", target)
				elseif blocked and t - lastMoved > 7 then
					-- they're safe where they are: he gives up for now and looks out over the water - their moment to run
					ignoreUntil[target] = t + 6
					setState("guard")
				end
			end
		end
	elseif state == "lunge" then
		-- a quick surge at the snout's target; the jaws shut at 0.3 s: caught, or a miss and a short breather
		local h = target and hrpOf(target)
		if since < 0.3 then
			local fx, fz = -math.sin(yaw), -math.cos(yaw)
			local nx, nz = x + fx * 7 * dt, z + fz * 7 * dt
			if okAt(nx, nz, yaw, 0.6) then x, z = nx, nz end
			if h then turnToward(math.atan2(-(h.Position.X - x), -(h.Position.Z - z)), dt) end
		else
			local s = snoutAt(x, z, yaw)
			if h and not held[target] and (immune[target] or 0) < t
				and Vector3.new(h.Position.X - s.X, 0, h.Position.Z - s.Z).Magnitude < A("Reach", 3.4) + 1.4 and math.abs(h.Position.Y - s.Y) < 6 then
				chomp(target)
			else
				lungeReady = t + 1.2
				evt:FireAllClients("miss")
				setState(target and "chase" or "patrol", target)
			end
		end
	elseif state == "hold" then
		local who = target
		if not who or not who.Parent then setState("patrol")
		elseif since > A("HoldTime", 1.7) then spit(who) end
	elseif state == "smug" then
		if since > 1.6 then setState("patrol") end
	elseif state == "dizzy" then
		if since > A("DizzySeconds", 3) then setState("sulk") end
	elseif state == "sulk" then
		local d = moveToward(sulkLobe[1], sulkLobe[2], A("SwimSpeed", 4.5) * 1.3, dt, 1.4)
		if d < 1.5 then turnToward(math.atan2(-(sulkLobe[1] - IX), -(sulkLobe[2] - IZ)), dt * 0.4) end
		if since > A("SulkSeconds", 20) + 4 then setState("patrol") end
	end
	-- stuck? (trying to go somewhere, getting nowhere): a stop on his patrol ring first, then on his way
	if tried and state ~= "chase" and state ~= "lunge" then
		stuckT = stuckT or t; stuckAt = stuckAt or Vector3.new(x, 0, z)
		if (Vector3.new(x, 0, z) - stuckAt).Magnitude > 0.6 then stuckT, stuckAt = t, Vector3.new(x, 0, z)
		elseif t - stuckT > 2.5 then
			stuckT, stuckAt = t, Vector3.new(x, 0, z)
			detourSide = nil
			local Rring = A("PatrolRadius", 12)
			local a = math.atan2(z - IZ, x - IX)
			local rNow = math.sqrt((x - IX) ^ 2 + (z - IZ) ^ 2)
			if math.abs(rNow - Rring) < 2 then a = a + ringDir * math.rad(60) end
			waypoint = {IX + math.cos(a) * Rring, IZ + math.sin(a) * Rring, t + 5}
		end
	else stuckT, stuckAt = nil, nil end
	tried = false
	-- anyone let go without a spit (left, died) is freed
	for p in pairs(held) do if not p.Parent or state ~= "hold" then held[p] = nil end end

	-- (his speed, for the slingshot's aim)
	local cv = os.clock()
	if lastVT and cv - lastVT > 0.02 then
		velX = velX + ((x - lastVX) / (cv - lastVT) - velX) * 0.6
		velZ = velZ + ((z - lastVZ) / (cv - lastVT) - velZ) * 0.6
	end
	lastVX, lastVZ, lastVT = x, z, cv
	pubAcc += dt
	if pubAcc >= 0.1 then
		pubAcc = 0
		croc:SetAttribute("Pose", CFrame.new(x, t % 4096, z) * CFrame.Angles(0, yaw, 0))
	end
end)
Players.PlayerRemoving:Connect(function(p) immune[p] = nil; held[p] = nil; rescues[p] = nil; ignoreUntil[p] = nil; heroes[p] = nil; fleeHourly[p] = nil end)
-- STUDIO TEST KIT (Shannon: "set me up with a slingshot so I can test the acorn to the head of the croc"): in Studio
-- only, and only while Studio cannot reach the saved data (API access off - a test can save nothing), everyone who joins
-- gets a slingshot and 100 acorns to shoot with. If the probe read works, the kit is not given (it could be saved).
-- Switch it off with the Lagoon attribute StudioKit = false.
if RunService:IsStudio() and L:GetAttribute("StudioKit") ~= false then
	task.spawn(function()
		local ok = pcall(function() return game:GetService("DataStoreService"):GetDataStore("SquirrelFinds_v1"):GetAsync("studio_kit_probe") end)
		if ok then warn("CrocServer: Studio test kit NOT given - Studio can reach the saved data (API access is on)") return end
		local function kit(p)
			local t0 = os.clock()
			while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 20 do task.wait(0.25) end   -- after the (failed) load
			if not p.Parent then return end
			p:SetAttribute("Item_slingshot", 1)
			p:SetAttribute("Acorns", math.max(p:GetAttribute("Acorns") or 0, 100))
			print("CrocServer: Studio test kit - a slingshot and 100 acorns for " .. p.Name .. " (not saved: Studio has no data access)")
		end
		Players.PlayerAdded:Connect(kit)
		for _, p in ipairs(Players:GetPlayers()) do task.spawn(kit, p) end
	end)
end
print("CrocServer: ready")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local L = script.Parent
local croc = L:WaitForChild("Croc")
local evt = L:WaitForChild("CrocEvent")
local cages = L:WaitForChild("Cages")
local award = RS:WaitForChild("AwardAcorns", 30)
local items = RS:WaitForChild("AwardItems", 30)
local picked = RS:FindFirstChild("AcornPicked")
local function A(n, d) local v = L:GetAttribute(n); if v == nil then return d end return v end
local function now() return workspace:GetServerTimeNow() end
local rng = Random.new()

-- the lagoon
local WATER_Y = A("WaterY", -1)
local LOBES = {}
for x, z, r in string.gmatch(A("Lobes", ""), "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do table.insert(LOBES, {tonumber(x), tonumber(z), tonumber(r)}) end
local IX, IZ, IR = A("IslandX", 118), A("IslandZ", -181), A("IslandR", 6.5)
local function sdfWater(x, z) local b = -math.huge for _, l in ipairs(LOBES) do b = math.max(b, l[3] - math.sqrt((x - l[1]) ^ 2 + (z - l[2]) ^ 2)) end return b end
local function sdfIsland(x, z) return IR - math.sqrt((x - IX) ^ 2 + (z - IZ) ^ 2) end
-- where he naps (the lobe nearest the path's west) and sulks (the lobe farthest from the path)
local function lobeFarthestFrom(px, pz, nearest)
	local best, bd = LOBES[1], nil
	for i, l in ipairs(LOBES) do
		if i > 1 then
			local d = (l[1] - px) ^ 2 + (l[2] - pz) ^ 2
			if not bd or (nearest and d < bd) or (not nearest and d > bd) then best, bd = l, d end
		end
	end
	return best
end
local SIGN_X, SIGN_Z = A("SignX", 104), A("SignZ", -147)
local napLobe = lobeFarthestFrom(SIGN_X - 20, SIGN_Z - 53, true)   -- the north-west arm, away from the path in and the log
local napX, napZ = napLobe[1], napLobe[2]
local sulkLobe = lobeFarthestFrom(SIGN_X, SIGN_Z, false)
local SPITS = {}
for x, z in string.gmatch(A("SpitSpots", ""), "([%-%d%.]+),([%-%d%.]+)") do table.insert(SPITS, Vector3.new(tonumber(x), 0.2, tonumber(z))) end
if #SPITS == 0 then SPITS = {Vector3.new(112, 0.2, -142)} end

-- the croc's measurements (studs, his own frame: bottom centre, facing -Z)
local SINK = croc:GetAttribute("SwimSink") or 2.3
local SNOUT = croc:GetAttribute("SnoutOffset") or Vector3.new(0, 2.8, -6.3)
local TAILB = croc:GetAttribute("TailBaseOffset") or Vector3.new(0, 1.6, 3.4)
local TAILT = croc:GetAttribute("TailTipOffset") or Vector3.new(-0.7, 3.4, 5.8)
local BODY_R = croc:GetAttribute("BodyRadius") or 1.8
-- the snout tip and both sides of his head: none of them may reach the island (Shannon: "his snout actually goes into
-- the hill")
local HEAD_PTS = {SNOUT, SNOUT + Vector3.new(1.1, 0, 2.2), SNOUT + Vector3.new(-1.1, 0, 2.2), SNOUT + Vector3.new(1.4, 0, 4.2), SNOUT + Vector3.new(-1.4, 0, 4.2)}
-- THE LOG IS SOLID (Shannon: "the croc still goes through the log with his tail and his snout"): its footprint on the
-- water (written by the lagoon builder) may not hold any part of him - snout, head, body, tail - so he swims round it,
-- and a turn that would swing his snout or tail into it doesn't happen
local LOG = nil
do
	local c, ax, ha, hb = L:GetAttribute("LogCenter"), L:GetAttribute("LogAxis"), L:GetAttribute("LogHalfA"), L:GetAttribute("LogHalfB")
	if typeof(c) == "Vector3" and typeof(ax) == "Vector3" and ha and hb then
		local a = Vector3.new(ax.X, 0, ax.Z).Unit
		LOG = {c = c, a = a, b = Vector3.new(-a.Z, 0, a.X), ha = ha, hb = hb}
	end
end
local BODY_PTS = {{SNOUT, 0.6}, {SNOUT + Vector3.new(0, 0, 2.4), 1.2}, {Vector3.new(0, 0, SNOUT.Z * 0.45), 1.8},
	{Vector3.new(0, 0, 0), 2.0}, {Vector3.new(0, 0, -SNOUT.Z * 0.3), 1.9}, {TAILB, 1.3}, {(TAILB + TAILT) / 2, 1.0}, {TAILT, 0.8}}
local function hitsLog(f)
	if not LOG then return false end
	for _, bp in ipairs(BODY_PTS) do
		local w = f * bp[1]
		local d = Vector3.new(w.X - LOG.c.X, 0, w.Z - LOG.c.Z)
		if math.abs(d:Dot(LOG.a)) < LOG.ha + bp[2] and math.abs(d:Dot(LOG.b)) < LOG.hb + bp[2] then return true end
	end
	return false
end
-- (with the log in the nap arm, he naps in the part of it farthest from the log)
if LOG then
	local bestD = -1
	for gx = -4, 4 do
		for gz = -4, 4 do
			local px, pz = napLobe[1] + gx, napLobe[2] + gz
			if sdfWater(px, pz) >= 3.5 and sdfIsland(px, pz) < -6 then
				local dd = Vector3.new(px - LOG.c.X, 0, pz - LOG.c.Z).Magnitude
				if dd > bestD then bestD, napX, napZ = dd, px, pz end
			end
		end
	end
end

local x, z, yaw = croc:GetAttribute("HomeX"), croc:GetAttribute("HomeZ"), croc:GetAttribute("HomeYaw") or 0
local function frameAt(px, pz, pyaw) return CFrame.new(px, WATER_Y - SINK, pz) * CFrame.Angles(0, pyaw, 0) end
local function snoutAt(px, pz, pyaw) return frameAt(px, pz, pyaw) * SNOUT end
-- WHERE TO AIM (SlingServer asks when someone near him shoots): the top of his head between the eyes, and how fast he's
-- going, so the acorn can be sent to where he'll be when it lands
local AIM_OFF = SNOUT + Vector3.new(0, 0.6, 3.0)
local velX, velZ, lastVX, lastVZ, lastVT = 0, 0, nil, nil, nil
local aimFn = L:FindFirstChild("CrocAim")
if not aimFn then aimFn = Instance.new("BindableFunction"); aimFn.Name = "CrocAim"; aimFn.Parent = L end
aimFn.OnInvoke = function() return frameAt(x, z, yaw) * AIM_OFF, Vector3.new(velX, 0, velZ) end

local state, stateAt, target = "patrol", now(), nil
local lastMoved = 0
local function setState(s, who)
	if s == "chase" and state ~= "lunge" then lastMoved = now() end   -- (snaps at the air don't reset his patience)
	state = s; stateAt = now(); target = who
	croc:SetAttribute("State", s); croc:SetAttribute("StateAt", stateAt % 4096)
	croc:SetAttribute("Target", who and who.UserId or 0)
end
setState("patrol")

-- ---- who's in his lagoon
local immune, held, ignoreUntil = {}, {}, {}
local function hrpOf(p) local c = p.Character; local h = c and c:FindFirstChild("HumanoidRootPart"); local hum = c and c:FindFirstChildOfClass("Humanoid"); if h and hum and hum.Health > 0 then return h end end
local function inLagoon(pos)
	if pos.Y > WATER_Y + 7 or pos.Y < WATER_Y - 12 then return false end
	if sdfIsland(pos.X, pos.Z) > -0.8 then return true end
	return sdfWater(pos.X, pos.Z) > -1.0
end
local function intruder(maxDist)
	local s = snoutAt(x, z, yaw)
	local best, bd = nil, maxDist or math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and not held[p] and (immune[p] or 0) < now() and (ignoreUntil[p] or 0) < now() and inLagoon(h.Position) then
			local d = (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(s.X, 0, s.Z)).Magnitude
			if d < bd then best, bd = p, d end
		end
	end
	return best, bd
end

-- ---- moving: he goes where he faces, turns at TurnRate, keeps off the island and in the water
-- THE GROUND UNDER HIS HEAD (Shannon, twice: "his nose is in the hill again"). The water's outline is only an outline:
-- the bank's grass slopes up out of the water inside it, and the first rule let the snout 2.5 studs past it - onto the
-- grass. Now the real terrain height is looked up (a raycast per stud of ground, remembered) and his snout and the
-- sides of his head must stay over water, the bed below them under the surface.
local bedRp = RaycastParams.new(); bedRp.FilterType = Enum.RaycastFilterType.Include; bedRp.IgnoreWater = true
bedRp.FilterDescendantsInstances = {workspace.Terrain, workspace:FindFirstChild("Baseplate")}
local bedCache = {}
local function bedCell(cx, cz)
	local col = bedCache[cx]; if not col then col = {}; bedCache[cx] = col end
	local v = col[cz]
	if v == nil then
		local r = workspace:Raycast(Vector3.new(cx, WATER_Y + 14, cz), Vector3.new(0, -40, 0), bedRp)
		v = r and r.Position.Y or (WATER_Y - 20)
		col[cz] = v
	end
	return v
end
local function bedH(px, pz)
	local cx, cz = math.floor(px), math.floor(pz)
	local fx, fz = px - cx, pz - cz
	local a, b, c, d = bedCell(cx, cz), bedCell(cx + 1, cz), bedCell(cx, cz + 1), bedCell(cx + 1, cz + 1)
	return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz
end
local function headClear(f)
	local sn = f * SNOUT
	if bedH(sn.X, sn.Z) > WATER_Y - A("SnoutDepth", 0.45) then return false end
	for i = 2, #HEAD_PTS do
		local q = f * HEAD_PTS[i]
		if bedH(q.X, q.Z) > WATER_Y - A("HeadDepth", 0.25) then return false end
	end
	return true
end
local function okAt(px, pz, pyaw, margin)
	if sdfWater(px, pz) < margin then return false end
	if sdfIsland(px, pz) > -2.6 then return false end
	local f = frameAt(px, pz, pyaw)
	if hitsLog(f) then return false end
	for i, o in ipairs(HEAD_PTS) do
		local q = f * o
		-- his head stays clear of the island: the terrain's slope reaches further out than the waterline (a stud off
		-- still touched the grass), so the snout keeps 2.6 studs off, the sides of his head 2
		if sdfIsland(q.X, q.Z) > (i == 1 and -2.6 or -2.0) then return false end
	end
	return headClear(f)                                              -- and over water, not on the bank
end
local function turnToward(want, dt)
	local d = (want - yaw + math.pi) % (2 * math.pi) - math.pi
	local m = math.rad(A("TurnRate", 150)) * dt
	local ny = yaw + math.clamp(d, -m, m)
	if LOG and hitsLog(frameAt(x, z, ny)) and not hitsLog(frameAt(x, z, yaw)) then return math.abs(d) end   -- not into the log
	-- nor his nose into the bank: he backs off a touch instead, and the turn comes when there's room
	if not headClear(frameAt(x, z, ny)) and headClear(frameAt(x, z, yaw)) then
		local bx, bz = x + math.sin(yaw) * 0.12, z + math.cos(yaw) * 0.12
		if okAt(bx, bz, yaw, 0.3) then x, z = bx, bz end
		return math.abs(d)
	end
	yaw = ny
	return math.abs(d)
end
local detourSide = nil
local waypoint = nil                                              -- {x, z, until}: a stop on the way, when he was stuck
local tried = false                                               -- he wanted to move this tick
local function aimAround(tx, tz)                                   -- round the island rather than through it
	if waypoint then
		if Vector3.new(waypoint[1] - x, 0, waypoint[2] - z).Magnitude < 1.5 or now() > waypoint[3] then waypoint = nil
		else return waypoint[1], waypoint[2] end
	end
	local Rr = IR + 4.2
	local px, pz, qx, qz = x - IX, z - IZ, tx - IX, tz - IZ
	local dx, dz = qx - px, qz - pz
	local len2 = dx * dx + dz * dz
	if len2 < 1e-4 then detourSide = nil return tx, tz end
	local t = math.clamp(-(px * dx + pz * dz) / len2, 0, 1)
	-- nearest approach where he already is (heading away) or at the target itself (a player on the island): straight on
	if t <= 0.03 or t >= 0.97 then detourSide = nil return tx, tz end
	local cx, cz = px + dx * t, pz + dz * t
	if cx * cx + cz * cz >= Rr * Rr then detourSide = nil return tx, tz end
	-- the side is chosen once and kept until the way is clear (a target straight across made him dither)
	if not detourSide then detourSide = (px * qz - pz * qx) >= 0 and 1 or -1 end
	local a = math.atan2(pz, px) + detourSide * math.rad(50)
	local r = math.clamp(math.sqrt(px * px + pz * pz), Rr + 0.5, math.max(A("PatrolRadius", 12), Rr + 0.5))
	return IX + math.cos(a) * r, IZ + math.sin(a) * r
end
local function moveToward(tx, tz, speed, dt, margin)
	local ax, az = aimAround(tx, tz)
	local dx, dz = ax - x, az - z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.25 then return dist end
	tried = true
	local offBy = turnToward(math.atan2(-dx, -dz), dt)
	local step = math.min(dist, speed * dt * math.clamp(1.2 - offBy / math.rad(80), 0.12, 1))
	for _, a in ipairs({0, 0.45, -0.45, 0.9, -0.9}) do
		local fx, fz = -math.sin(yaw + a), -math.cos(yaw + a)
		local nx, nz = x + fx * step * (a == 0 and 1 or 0.7), z + fz * step * (a == 0 and 1 or 0.7)
		if okAt(nx, nz, yaw, margin) then x, z = nx, nz break end
	end
	return dist
end

-- ---- acorns
local hourly = {}
local function pay(player, n, from)
	if n <= 0 then return end
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + n)
	if award then award:Fire(player, n) end
	if picked and from then picked:FireClient(player, have + n, from, n) end      -- n acorns fly to the purse
end

-- ---- slingshot bonks: every shot acorn is followed; a line from frame to frame that crosses his body is a hit
local shots, bonks = {}, {}
local fleeHourly = {}
local flinchUntil = -1                                            -- a bonk stops him dead for a moment
local function segDist(p1, q1, p2, q2)                           -- closest distance between two segments
	local d1, d2, r = q1 - p1, q2 - p2, p1 - p2
	local a, e, f = d1:Dot(d1), d2:Dot(d2), d2:Dot(r)
	local sN, tN
	if a <= 1e-6 and e <= 1e-6 then return r.Magnitude end
	if a <= 1e-6 then sN = 0; tN = math.clamp(f / e, 0, 1)
	else
		local c = d1:Dot(r)
		if e <= 1e-6 then tN = 0; sN = math.clamp(-c / a, 0, 1)
		else
			local b = d1:Dot(d2); local den = a * e - b * b
			sN = den ~= 0 and math.clamp((b * f - c * e) / den, 0, 1) or 0
			tN = (b * sN + f) / e
			if tN < 0 then tN = 0; sN = math.clamp(-c / a, 0, 1) elseif tN > 1 then tN = 1; sN = math.clamp((b - c) / a, 0, 1) end
		end
	end
	return ((p1 + d1 * sN) - (p2 + d2 * tN)).Magnitude
end
local function hitsCroc(a, b)
	local f = frameAt(x, z, yaw)
	local sn, tb, tt = f * SNOUT, f * TAILB, f * TAILT
	return segDist(a, b, sn, tb) < BODY_R + 0.7 or segDist(a, b, tb, tt) < BODY_R * 0.55 + 0.6
end
workspace.ChildAdded:Connect(function(c)
	if c.Name ~= "ShotAcorn" then return end
	task.defer(function()
		local nut = c.PrimaryPart or c:FindFirstChild("Nut") or c:FindFirstChildWhichIsA("BasePart")
		if not nut then return end
		local id = nut:GetAttribute("ShooterId") or c:GetAttribute("ShooterId")
		local shooter = id and Players:GetPlayerByUserId(id)
		if not shooter then
			local bd = 7
			for _, p in ipairs(Players:GetPlayers()) do
				local h = p.Character and p.Character:FindFirstChild("Head")
				if h and (h.Position - nut.Position).Magnitude < bd then shooter, bd = p, (h.Position - nut.Position).Magnitude end
			end
		end
		shots[nut] = {model = c, last = nut.Position, shooter = shooter, born = os.clock()}
	end)
end)
local function bonk(shooter, at)
	local t = now()
	if shooter then pay(shooter, A("BonkPrize", 1), at) end
	local counts = not (state == "dizzy" or state == "sulk" or state == "hold" or state == "spit")
	if counts then
		for i = #bonks, 1, -1 do if t - bonks[i] > A("BonkWindow", 25) then table.remove(bonks, i) end end
		table.insert(bonks, t)
	end
	local n, need = counts and #bonks or 0, A("BonksToFlee", 3)
	-- EVERY BONK SHOWS (Shannon: "he does not react when you bonk him"): he flinches on every screen (CrocClient), and
	-- stops dead for a moment - a bonk buys a chased player a second; the shooter sees how many more it takes
	evt:FireAllClients("bonk", at, shooter and shooter.UserId or 0, n, need)
	print(string.format("CrocServer: bonk by %s - %d of %d (%s)", shooter and shooter.Name or "?", n, need, state))
	if not counts then return end
	flinchUntil = t + 0.7
	if n >= need then
		bonks = {}
		if shooter then
			-- capped per hour like the rescues: a slingshot that flies at his head must not be an acorn farm
			local list = fleeHourly[shooter] or {}; fleeHourly[shooter] = list
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			if #list < A("FleeCap", 3) then table.insert(list, t); pay(shooter, A("FleePrize", 3), at) end
			evt:FireClient(shooter, "fled")
		end
		setState("dizzy")
	elseif state == "nap" or state == "tonap" then
		setState("patrol")
	end
end

-- ---- the chomp
local function chomp(victim)
	held[victim] = true
	setState("hold", victim)
	evt:FireClient(victim, "chomp", A("HoldTime", 1.7))
	evt:FireAllClients("chompfx", victim.UserId)
end
local function spit(victim)
	held[victim] = nil
	local best, bd = SPITS[1], math.huge
	local s = snoutAt(x, z, yaw)
	for _, p in ipairs(SPITS) do
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(s.X, 0, s.Z)).Magnitude + rng:NextNumber(0, 6)
		if d < bd then best, bd = p, d end
	end
	local flight = math.clamp(bd / 26, 0.8, 1.6)
	immune[victim] = now() + flight + A("Immune", 6)
	if victim.Parent then evt:FireClient(victim, "spit", best, flight) end
	evt:FireAllClients("spitfx", victim.UserId, flight)
	setState("smug")
end

-- ---- rescues
local rescues = {}
local roundRescuers = {}                                          -- names of whoever freed squirrels since the last full set
-- PRAISE (Shannon): after a rescue, the next squirrel you walk by says "Thank you for saving Madame Margaux's petits
-- enfants!" and the one after that "<name> is a hero! Yay for <name>!". The rescuer's screen picks the squirrel; the
-- server checks it (a tagged squirrel, near them, a different one, not too soon) and everyone nearby sees the bubble.
local CS = game:GetService("CollectionService")
local heroes = {}
evt.OnServerEvent:Connect(function(player, kind, model)
	if kind ~= "praise" then return end
	local h = heroes[player]
	if not h or typeof(model) ~= "Instance" or not model:IsA("Model") or not CS:HasTag(model, "Squirrel") or model == h.last then return end
	local t = now()
	if t - h.at < 3 then return end
	local hr = hrpOf(player)
	local ok, pos = pcall(function() return model:GetPivot().Position end)
	if not hr or not ok or (pos - hr.Position).Magnitude > 26 then return end
	local name = player.DisplayName
	local text = h.stage == 1 and "Thank you for saving Madame Margaux's petits enfants!" or string.format("%s is a hero! Yay for %s!", name, name)
	evt:FireAllClients("praise", model, text)
	evt:FireClient(player, "praiseok", h.stage)                   -- the rescuer's screen moves on only when this comes
	h.stage += 1; h.at = t; h.last = model
	if h.stage > 2 then heroes[player] = nil end
end)
local function openCount(cage) return cage:GetAttribute("Occupied") end
for _, cage in ipairs(cages:GetChildren()) do
	local pp = cage:FindFirstChild("RescuePrompt", true)
	if pp then
		pp.Enabled = cage:GetAttribute("Occupied") == true and cage:GetAttribute("HasCaptive") == true
		pp.Triggered:Connect(function(player)
			if not cage:GetAttribute("Occupied") then return end
			local h = hrpOf(player)
			local spot = pp.Parent
			if not h or (h.Position - spot.Position).Magnitude > 10 then return end
			local t = now()
			local list = rescues[player] or {}
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			rescues[player] = list
			cage:SetAttribute("Occupied", false); pp.Enabled = false
			evt:FireAllClients("rescued", cage.Name, player.UserId)
			-- ALL THREE FREE (Shannon: "there should be some kind of toast after all 3 squirrels are free"): everyone in
			-- the game gets the toast, naming whoever freed them this time round
			local nm = player.DisplayName
			local seen = false
			for _, n in ipairs(roundRescuers) do if n == nm then seen = true end end
			if not seen then table.insert(roundRescuers, nm) end
			local allFree = true
			for _, c in ipairs(cages:GetChildren()) do if c:GetAttribute("Occupied") then allFree = false end end
			if allFree then
				local names = roundRescuers
				roundRescuers = {}
				task.delay(1.3, function() evt:FireAllClients("allfree", names) end)     -- after the last one's hop out
			end
			if #list < A("RescueCap", 20) then
				table.insert(list, t)
				pay(player, A("RescuePrize", 5), spot.Position)
				if items then items:Fire(player, "croc_rescues", 1) end
				if not heroes[player] then heroes[player] = {stage = 1, at = now(), last = nil} end
			else
				evt:FireClient(player, "capped")
			end
			-- he's not having it
			if state == "patrol" or state == "nap" or state == "tonap" or state == "smug" or state == "guard" then setState("chase", player) end
			task.delay(A("RespawnSeconds", 90), function()
				while true do
					local busy = false
					for _, p in ipairs(Players:GetPlayers()) do
						local hh = hrpOf(p)
						if hh and (Vector3.new(hh.Position.X, 0, hh.Position.Z) - Vector3.new(IX, 0, IZ)).Magnitude < 16 then busy = true end
					end
					if not busy then break end
					task.wait(3)
				end
				cage:SetAttribute("Occupied", true)
				pp.Enabled = cage:GetAttribute("HasCaptive") == true
			end)
		end)
	end
end

-- ---- the brain: 20 times a second; the pose goes out 10 times a second
local ringDir, ringAng = 1, math.atan2(z - IZ, x - IX)
local nextStop, nextNap = now() + rng:NextNumber(12, 22), now() + A("NapEvery", 70) * rng:NextNumber(0.6, 1.1)
local seenSince, lostSince, lungeReady = nil, nil, 0
local stuckT, stuckAt
local lungeFrom
local acc, pubAcc = 0, 0
RunService.Heartbeat:Connect(function(dtFrame)
	-- shots first (every frame: a fast acorn crosses him between ticks)
	for nut, sh in pairs(shots) do
		if not nut.Parent or os.clock() - sh.born > 10 then shots[nut] = nil
		else
			local cur = nut.Position
			if hitsCroc(sh.last, cur) then
				shots[nut] = nil
				local at = cur
				sh.model:Destroy()
				bonk(sh.shooter, at)
			else sh.last = cur end
		end
	end
	acc += dtFrame
	if acc < 0.05 then return end
	local dt = math.min(acc, 0.2); acc = 0
	local t = now()
	local since = t - stateAt
	local R = A("PatrolRadius", 12)
	local slow = math.clamp((t - flinchUntil) / 0.5, 0, 1)         -- 0 while he's flinching from a bonk, back to 1 in half a second

	if state == "patrol" or state == "guard" then
		local who = intruder(60)
		if who then
			seenSince = seenSince or t
			if t - seenSince > A("NoticeDelay", 0.6) then seenSince = nil; setState("chase", who) end
		else seenSince = nil end
		if state == "patrol" then
			local lead = math.rad(30)
			ringAng = math.atan2(z - IZ, x - IX) + ringDir * lead
			local r2 = R / math.cos(lead)                           -- chasing a point this far out settles him on the ring
			moveToward(IX + math.cos(ringAng) * r2, IZ + math.sin(ringAng) * r2, A("SwimSpeed", 4.5) * slow, dt, 2.2)
			if t > nextStop then setState("guard"); nextStop = t + rng:NextNumber(14, 26) end
			if t > nextNap then setState("tonap") end
		elseif state == "guard" then
			-- a look-out: turn to face out over the lagoon, then carry on (sometimes the other way round)
			local out = math.atan2(-(x - IX), -(z - IZ))            -- the island at his back, looking out at the shore
			turnToward(out, dt * 0.5)
			if since > 4.5 then
				if rng:NextNumber() < 0.35 then ringDir = -ringDir end
				setState("patrol")
			end
		end
	elseif state == "tonap" then
		local d = moveToward(napX, napZ, A("SwimSpeed", 4.5) * slow, dt, 1.6)
		if d < 1.2 or since > 25 then setState("nap") end
	elseif state == "nap" then
		local who, dist = intruder(A("WakeRadius", 4.5) + 3)
		if who then setState("chase", who)
		elseif since > A("NapSeconds", 22) then nextNap = t + A("NapEvery", 70) * rng:NextNumber(0.8, 1.3); setState("patrol") end
	elseif state == "chase" then
		local h = target and hrpOf(target)
		if not h or held[target] or (immune[target] or 0) > t then setState("patrol")
		else
			if not inLagoon(h.Position) then
				lostSince = lostSince or t
				if t - lostSince > 1.5 then lostSince = nil; setState("guard") end
			else lostSince = nil end
			if state == "chase" then
				local bx, bz = x, z
				moveToward(h.Position.X, h.Position.Z, A("ChaseSpeed", 9.5) * slow, dt, 1.0)
				if t < flinchUntil then lastMoved = t end                -- (stopped by a bonk, not by the bank)
				if Vector3.new(x - bx, 0, z - bz).Magnitude > 0.05 then lastMoved = t end
				local s = snoutAt(x, z, yaw)
				local flat = Vector3.new(h.Position.X - s.X, 0, h.Position.Z - s.Z).Magnitude
				local blocked = t - lastMoved > 0.8                    -- at the island's edge (or the bank) and can't get nearer
				if flat < A("Reach", 3.4) and math.abs(h.Position.Y - s.Y) < 5 and t > lungeReady and t > flinchUntil then
					lungeFrom = Vector3.new(x, 0, z); setState("lunge", target)
				elseif blocked and flat < A("Reach", 3.4) + 3.5 and t > lungeReady + 2.2 then
					-- just out of reach: a snap at the air anyway (a miss, a splash)
					lungeFrom = Vector3.new(x, 0, z); setState("lunge", target)
				elseif blocked and t - lastMoved > 7 then
					-- they're safe where they are: he gives up for now and looks out over the water - their moment to run
					ignoreUntil[target] = t + 6
					setState("guard")
				end
			end
		end
	elseif state == "lunge" then
		-- a quick surge at the snout's target; the jaws shut at 0.3 s: caught, or a miss and a short breather
		local h = target and hrpOf(target)
		if since < 0.3 then
			local fx, fz = -math.sin(yaw), -math.cos(yaw)
			local nx, nz = x + fx * 7 * dt, z + fz * 7 * dt
			if okAt(nx, nz, yaw, 0.6) then x, z = nx, nz end
			if h then turnToward(math.atan2(-(h.Position.X - x), -(h.Position.Z - z)), dt) end
		else
			local s = snoutAt(x, z, yaw)
			if h and not held[target] and (immune[target] or 0) < t
				and Vector3.new(h.Position.X - s.X, 0, h.Position.Z - s.Z).Magnitude < A("Reach", 3.4) + 1.4 and math.abs(h.Position.Y - s.Y) < 6 then
				chomp(target)
			else
				lungeReady = t + 1.2
				evt:FireAllClients("miss")
				setState(target and "chase" or "patrol", target)
			end
		end
	elseif state == "hold" then
		local who = target
		if not who or not who.Parent then setState("patrol")
		elseif since > A("HoldTime", 1.7) then spit(who) end
	elseif state == "smug" then
		if since > 1.6 then setState("patrol") end
	elseif state == "dizzy" then
		if since > A("DizzySeconds", 3) then setState("sulk") end
	elseif state == "sulk" then
		local d = moveToward(sulkLobe[1], sulkLobe[2], A("SwimSpeed", 4.5) * 1.3, dt, 1.4)
		if d < 1.5 then turnToward(math.atan2(-(sulkLobe[1] - IX), -(sulkLobe[2] - IZ)), dt * 0.4) end
		if since > A("SulkSeconds", 20) + 4 then setState("patrol") end
	end
	-- stuck? (trying to go somewhere, getting nowhere): a stop on his patrol ring first, then on his way
	if tried and state ~= "chase" and state ~= "lunge" then
		stuckT = stuckT or t; stuckAt = stuckAt or Vector3.new(x, 0, z)
		if (Vector3.new(x, 0, z) - stuckAt).Magnitude > 0.6 then stuckT, stuckAt = t, Vector3.new(x, 0, z)
		elseif t - stuckT > 2.5 then
			stuckT, stuckAt = t, Vector3.new(x, 0, z)
			detourSide = nil
			local Rring = A("PatrolRadius", 12)
			local a = math.atan2(z - IZ, x - IX)
			local rNow = math.sqrt((x - IX) ^ 2 + (z - IZ) ^ 2)
			if math.abs(rNow - Rring) < 2 then a = a + ringDir * math.rad(60) end
			waypoint = {IX + math.cos(a) * Rring, IZ + math.sin(a) * Rring, t + 5}
		end
	else stuckT, stuckAt = nil, nil end
	tried = false
	-- anyone let go without a spit (left, died) is freed
	for p in pairs(held) do if not p.Parent or state ~= "hold" then held[p] = nil end end

	-- (his speed, for the slingshot's aim)
	local cv = os.clock()
	if lastVT and cv - lastVT > 0.02 then
		velX = velX + ((x - lastVX) / (cv - lastVT) - velX) * 0.6
		velZ = velZ + ((z - lastVZ) / (cv - lastVT) - velZ) * 0.6
	end
	lastVX, lastVZ, lastVT = x, z, cv
	pubAcc += dt
	if pubAcc >= 0.1 then
		pubAcc = 0
		croc:SetAttribute("Pose", CFrame.new(x, t % 4096, z) * CFrame.Angles(0, yaw, 0))
	end
end)
Players.PlayerRemoving:Connect(function(p) immune[p] = nil; held[p] = nil; rescues[p] = nil; ignoreUntil[p] = nil; heroes[p] = nil; fleeHourly[p] = nil end)
-- STUDIO TEST KIT (Shannon: "set me up with a slingshot so I can test the acorn to the head of the croc"): in Studio
-- only, and only while Studio cannot reach the saved data (API access off - a test can save nothing), everyone who joins
-- gets a slingshot and 100 acorns to shoot with. If the probe read works, the kit is not given (it could be saved).
-- Switch it off with the Lagoon attribute StudioKit = false.
if RunService:IsStudio() and L:GetAttribute("StudioKit") ~= false then
	task.spawn(function()
		local ok = pcall(function() return game:GetService("DataStoreService"):GetDataStore("SquirrelFinds_v1"):GetAsync("studio_kit_probe") end)
		if ok then warn("CrocServer: Studio test kit NOT given - Studio can reach the saved data (API access is on)") return end
		local function kit(p)
			local t0 = os.clock()
			while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 20 do task.wait(0.25) end   -- after the (failed) load
			if not p.Parent then return end
			p:SetAttribute("Item_slingshot", 1)
			p:SetAttribute("Acorns", math.max(p:GetAttribute("Acorns") or 0, 100))
			print("CrocServer: Studio test kit - a slingshot and 100 acorns for " .. p.Name .. " (not saved: Studio has no data access)")
		end
		Players.PlayerAdded:Connect(kit)
		for _, p in ipairs(Players:GetPlayers()) do task.spawn(kit, p) end
	end)
end
print("CrocServer: ready")
]====]})
table.insert(changes,{target=workspace.MillRide.MillServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("MillRide")
local sails
repeat local mill = workspace:WaitForChild("Domaine"):WaitForChild("Props"):FindFirstChild("windmill"); sails = mill and mill:FindFirstChild("Sails", true); if not sails then task.wait(1) end until sails
local HUB = Vector3.new(F:GetAttribute("HubX"), F:GetAttribute("HubY"), F:GetAttribute("HubZ"))
local N = Vector3.new(F:GetAttribute("LookX"), F:GetAttribute("LookY"), F:GetAttribute("LookZ"))
local E1 = Vector3.new(0, 1, 0)
local E2 = N:Cross(E1).Unit
local SPEED = F:GetAttribute("Speed") or 0.35
local function angleOf(att)                               -- 0 = straight up, pi = the bottom of the sweep
	local r = att.WorldPosition - HUB
	return math.atan2(r:Dot(E2), r:Dot(E1))
end
local turn = 1                                            -- which way round the sails go, measured once
task.spawn(function()
	local a1 = angleOf(sails.Tip1); task.wait(0.4); local a2 = angleOf(sails.Tip1)
	local d = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
	turn = d >= 0 and 1 or -1
	F:SetAttribute("Turn", turn)
end)

local arms = {}                                           -- arm index -> player
local riding = {}                                         -- player -> {arm, char, c0, att, stage, since}

-- THE POSE, the zipline's: arms straight up and a touch forward, legs hanging - on the server so everyone sees it
local ARM_UP, ARM_OUT, HIP, KNEE = math.rad(175), math.rad(6), math.rad(24), math.rad(-42)
local function armTurn(out) return CFrame.Angles(0, 0, ARM_OUT * out) * CFrame.Angles(ARM_UP, 0, 0) end
local POSE = {
	{part = "LeftUpperArm",  joint = "LeftShoulder",  turn = armTurn(1)},
	{part = "RightUpperArm", joint = "RightShoulder", turn = armTurn(-1)},
	{part = "LeftUpperLeg",  joint = "LeftHip",       turn = CFrame.Angles(HIP, 0, 0)},
	{part = "RightUpperLeg", joint = "RightHip",      turn = CFrame.Angles(HIP, 0, 0)},
	{part = "LeftLowerLeg",  joint = "LeftKnee",      turn = CFrame.Angles(KNEE, 0, 0)},
	{part = "RightLowerLeg", joint = "RightKnee",     turn = CFrame.Angles(KNEE, 0, 0)},
}
local function pose(char, r)
	for _, p in ipairs(POSE) do
		local part = char:FindFirstChild(p.part)
		local joint = part and part:FindFirstChild(p.joint)
		if joint then
			if joint:IsA("Motor6D") then r.c0[joint] = joint.C0; joint.C0 = joint.C0 * p.turn
			elseif joint:IsA("AnimationConstraint") and joint.Attachment0 then
				local att = joint.Attachment0
				r.att[att] = r.att[att] or att.CFrame
				att.CFrame = att.CFrame * p.turn
			end
		end
	end
end
local function finish(player)
	local r = riding[player]; if not r then return end
	riding[player] = nil
	if r.arm then arms[r.arm] = nil end
	local char = r.char
	if char and char.Parent then
		for joint, c0 in pairs(r.c0) do if joint.Parent then joint.C0 = c0 end end
		for att, cf in pairs(r.att) do if att.Parent then att.CFrame = cf end end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		char:SetAttribute("MillRiding", nil)
	end
end
-- the free arm that reaches the bottom of the sweep soonest, going the way the sails go
local function nextArm()
	local best, bestT
	for i = 1, 4 do
		local att = sails:FindFirstChild("Tip" .. i)
		if att and not arms[i] then
			local ahead = ((math.pi - angleOf(att)) * turn) % (2 * math.pi)
			if not bestT or ahead < bestT then best, bestT = i, ahead end
		end
	end
	return best, bestT and bestT / SPEED or nil
end
local function start(player)
	if riding[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then return end
	local pad = Vector3.new(F:GetAttribute("PadX"), F:GetAttribute("PadY"), F:GetAttribute("PadZ"))
	if (hrp.Position - pad).Magnitude > (F:GetAttribute("Reach") or 11) then ev:FireClient(player, "no", "Stand on the stone pad under the sails.") return end
	local arm, secs = nextArm()
	if not arm then ev:FireClient(player, "no", "Every sail has a rider - wait for one to come round.") return end
	riding[player] = {arm = arm, char = char, c0 = {}, att = {}, stage = "wait", since = os.clock()}
	arms[arm] = player
	char:SetAttribute("MillRiding", true)                              -- not "Riding": MapMusic mutes that one (the zipline wants quiet; Shannon wants the music on here)
	ev:FireClient(player, "wait", arm, secs)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GrabPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	local r = riding[player]
	if not r then return end
	if what == "grab" and r.stage == "wait" then
		local hum = r.char and r.char:FindFirstChildOfClass("Humanoid")
		if not hum then finish(player) return end
		r.stage = "ride"; r.since = os.clock()
		hum.PlatformStand = true
		pose(r.char, r)
		local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"windmill",{}) end
		ev:FireClient(player, "ride")
		print(string.format("MillRide: %s grabbed sail %d", player.Name, r.arm))
	elseif what == "done" then
		print(string.format("MillRide: %s let go of sail %d after %.0fs", player.Name, r.arm, os.clock() - r.since))
		finish(player)
	end
end)
-- nobody stays stuck: a wait longer than a turn and a half, or a ride longer than a turn and some, is over
task.spawn(function()
	while true do
		task.wait(1)
		local lap = 2 * math.pi / SPEED
		for player, r in pairs(riding) do
			local limit = (r.stage == "wait") and lap * 1.5 or lap * (F:GetAttribute("Turns") or 1) + 6
			if os.clock() - r.since > limit or not (r.char and r.char.Parent) then
				ev:FireClient(player, "off")
				finish(player)
			end
		end
	end
end)
Players.PlayerRemoving:Connect(finish)
Players.PlayerAdded:Connect(function(p) p.CharacterRemoving:Connect(function() finish(p) end) end)
for _, p in ipairs(Players:GetPlayers()) do p.CharacterRemoving:Connect(function() finish(p) end) end
print("MillServer: ready - four sails, one rider each")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("MillRide")
local sails
repeat local mill = workspace:WaitForChild("Domaine"):WaitForChild("Props"):FindFirstChild("windmill"); sails = mill and mill:FindFirstChild("Sails", true); if not sails then task.wait(1) end until sails
local HUB = Vector3.new(F:GetAttribute("HubX"), F:GetAttribute("HubY"), F:GetAttribute("HubZ"))
local N = Vector3.new(F:GetAttribute("LookX"), F:GetAttribute("LookY"), F:GetAttribute("LookZ"))
local E1 = Vector3.new(0, 1, 0)
local E2 = N:Cross(E1).Unit
local SPEED = F:GetAttribute("Speed") or 0.35
local function angleOf(att)                               -- 0 = straight up, pi = the bottom of the sweep
	local r = att.WorldPosition - HUB
	return math.atan2(r:Dot(E2), r:Dot(E1))
end
local turn = 1                                            -- which way round the sails go, measured once
task.spawn(function()
	local a1 = angleOf(sails.Tip1); task.wait(0.4); local a2 = angleOf(sails.Tip1)
	local d = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
	turn = d >= 0 and 1 or -1
	F:SetAttribute("Turn", turn)
end)

local arms = {}                                           -- arm index -> player
local riding = {}                                         -- player -> {arm, char, c0, att, stage, since}

-- THE POSE, the zipline's: arms straight up and a touch forward, legs hanging - on the server so everyone sees it
local ARM_UP, ARM_OUT, HIP, KNEE = math.rad(175), math.rad(6), math.rad(24), math.rad(-42)
local function armTurn(out) return CFrame.Angles(0, 0, ARM_OUT * out) * CFrame.Angles(ARM_UP, 0, 0) end
local POSE = {
	{part = "LeftUpperArm",  joint = "LeftShoulder",  turn = armTurn(1)},
	{part = "RightUpperArm", joint = "RightShoulder", turn = armTurn(-1)},
	{part = "LeftUpperLeg",  joint = "LeftHip",       turn = CFrame.Angles(HIP, 0, 0)},
	{part = "RightUpperLeg", joint = "RightHip",      turn = CFrame.Angles(HIP, 0, 0)},
	{part = "LeftLowerLeg",  joint = "LeftKnee",      turn = CFrame.Angles(KNEE, 0, 0)},
	{part = "RightLowerLeg", joint = "RightKnee",     turn = CFrame.Angles(KNEE, 0, 0)},
}
local function pose(char, r)
	for _, p in ipairs(POSE) do
		local part = char:FindFirstChild(p.part)
		local joint = part and part:FindFirstChild(p.joint)
		if joint then
			if joint:IsA("Motor6D") then r.c0[joint] = joint.C0; joint.C0 = joint.C0 * p.turn
			elseif joint:IsA("AnimationConstraint") and joint.Attachment0 then
				local att = joint.Attachment0
				r.att[att] = r.att[att] or att.CFrame
				att.CFrame = att.CFrame * p.turn
			end
		end
	end
end
local function finish(player)
	local r = riding[player]; if not r then return end
	riding[player] = nil
	if r.arm then arms[r.arm] = nil end
	local char = r.char
	if char and char.Parent then
		for joint, c0 in pairs(r.c0) do if joint.Parent then joint.C0 = c0 end end
		for att, cf in pairs(r.att) do if att.Parent then att.CFrame = cf end end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		char:SetAttribute("MillRiding", nil)
	end
end
-- the free arm that reaches the bottom of the sweep soonest, going the way the sails go
local function nextArm()
	local best, bestT
	for i = 1, 4 do
		local att = sails:FindFirstChild("Tip" .. i)
		if att and not arms[i] then
			local ahead = ((math.pi - angleOf(att)) * turn) % (2 * math.pi)
			if not bestT or ahead < bestT then best, bestT = i, ahead end
		end
	end
	return best, bestT and bestT / SPEED or nil
end
local function start(player)
	if riding[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then return end
	local pad = Vector3.new(F:GetAttribute("PadX"), F:GetAttribute("PadY"), F:GetAttribute("PadZ"))
	if (hrp.Position - pad).Magnitude > (F:GetAttribute("Reach") or 11) then ev:FireClient(player, "no", "Stand on the stone pad under the sails.") return end
	local arm, secs = nextArm()
	if not arm then ev:FireClient(player, "no", "Every sail has a rider - wait for one to come round.") return end
	riding[player] = {arm = arm, char = char, c0 = {}, att = {}, stage = "wait", since = os.clock()}
	arms[arm] = player
	char:SetAttribute("MillRiding", true)                              -- not "Riding": MapMusic mutes that one (the zipline wants quiet; Shannon wants the music on here)
	ev:FireClient(player, "wait", arm, secs)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GrabPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	local r = riding[player]
	if not r then return end
	if what == "grab" and r.stage == "wait" then
		local hum = r.char and r.char:FindFirstChildOfClass("Humanoid")
		if not hum then finish(player) return end
		r.stage = "ride"; r.since = os.clock()
		hum.PlatformStand = true
		pose(r.char, r)
		ev:FireClient(player, "ride")
		print(string.format("MillRide: %s grabbed sail %d", player.Name, r.arm))
	elseif what == "done" then
		print(string.format("MillRide: %s let go of sail %d after %.0fs", player.Name, r.arm, os.clock() - r.since))
		finish(player)
	end
end)
-- nobody stays stuck: a wait longer than a turn and a half, or a ride longer than a turn and some, is over
task.spawn(function()
	while true do
		task.wait(1)
		local lap = 2 * math.pi / SPEED
		for player, r in pairs(riding) do
			local limit = (r.stage == "wait") and lap * 1.5 or lap * (F:GetAttribute("Turns") or 1) + 6
			if os.clock() - r.since > limit or not (r.char and r.char.Parent) then
				ev:FireClient(player, "off")
				finish(player)
			end
		end
	end
end)
Players.PlayerRemoving:Connect(finish)
Players.PlayerAdded:Connect(function(p) p.CharacterRemoving:Connect(function() finish(p) end) end)
for _, p in ipairs(Players:GetPlayers()) do p.CharacterRemoving:Connect(function() finish(p) end) end
print("MillServer: ready - four sails, one rider each")
]====]})
table.insert(changes,{target=workspace.PortraitGallery.PortraitServer,source=[====[-- PortraitServer: the sitters' list (newest first, at most Slots), its save, and the easels' pictures
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local G = script.Parent
local slots = G:WaitForChild("Slots")
local done = G:WaitForChild("PortraitDone")
local MAX = G:GetAttribute("Slots") or 12
local store
pcall(function() store = DSS:GetDataStore("PortraitWall") end)
local list = {}                                              -- {id=, name=, t=}, newest first

local function show()
	for i = 1, MAX do
		local slot = slots:FindFirstChild("Slot" .. i)
		local canvas = slot and slot:FindFirstChild("Canvas", true)
		local gui = canvas and canvas:FindFirstChild("Picture")
		local plaque = slot and slot:FindFirstChild("Plaque")
		local e = list[i]
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
			-- the dressing, from the user id: one of five painted scenes always, a companion four times in five (Shannon: "I
			-- like the different backgrounds and companions")
			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
			-- the sitter's place: centred, or to one side when the scene asks (SitX / SitScale attributes on the scene frame);
			-- a corner companion then shows on the far side - its mirrored copy when it was drawn on the sitter's side
			local sf = e and G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)   -- the template to clone
			local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
			img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(e.id) .. "&w=420&h=420"
				img.Visible = true; wash.Visible = true
			else
				img.Image = ""; img.Visible = false; wash.Visible = false
			end
		end
		if plaque then
			local sg = plaque:FindFirstChildWhichIsA("SurfaceGui")
			local t = sg and sg:FindFirstChild("Name")
			if t then t.Text = e and tostring(e.name) or "" end
		end
	end
end

local function merge(saved, entry)
	local out = {}
	if entry then out[1] = entry end
	for _, e in ipairs(saved or {}) do
		if type(e) == "table" and e.id and (not entry or e.id ~= entry.id) and #out < MAX then out[#out + 1] = e end
	end
	return out
end

local listLoaded = false
local function load()
	if not store then listLoaded = true return end
	local ok, saved = pcall(function() return store:GetAsync("latest") end)
	if ok and type(saved) == "table" then list = merge(saved, nil); show() end
	listLoaded = true
end

local function hang(player, late)
	local entry = {id = player.UserId, name = player.DisplayName, t = os.time()}
	list = merge(list, entry)
	show()
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync("latest", function(saved) return merge(saved, entry) end)
		end)
		if not ok then warn("PortraitServer: could not save the gallery - " .. tostring(err)) end
	end
	-- the flourish: sparkle at the newest easel, and a word to the sitter
	local canvas = slots:FindFirstChild("Slot1") and slots.Slot1:FindFirstChild("Canvas", true)
	local em = canvas and canvas:FindFirstChild("Sparkle") and canvas.Sparkle:FindFirstChildOfClass("ParticleEmitter")
	if em then em:Emit(70) end
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"portrait",{}) end
	done:FireClient(player, "hung", late == true)
end

-- A PURCHASE IS THE SHOP'S AWARD: the shop pays for a portrait with AwardItems(player, "portrait", 1), and that event
-- is the signal. (It used to be a RISING Item_portrait, which missed every FIRST purchase: a player who had never
-- bought one has no count in their save, so the count went from nothing to 1 - which looked like the save loading.
-- Shannon's alt paid 120 acorns and got no painting.)
local function paintedKey(uid) return "painted_u" .. tostring(uid) end
local function remember(player)                          -- how many of their portraits have been painted, kept per player
	if not store then return end
	local n = tonumber(player:GetAttribute("Item_portrait")) or 0
	local ok, err = pcall(function() store:SetAsync(paintedKey(player.UserId), n) end)
	if not ok then warn("PortraitServer: could not note " .. player.Name .. "'s painted count - " .. tostring(err)) end
end
local itemEv = game:GetService("ReplicatedStorage"):WaitForChild("AwardItems", 30)
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if id ~= "portrait" or (tonumber(n) or 0) <= 0 then return end
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		task.defer(function()
			hang(player)
			remember(player)
			print("PortraitServer: painted " .. player.Name .. " (bought " .. tostring(player:GetAttribute("Item_portrait")) .. ")")
		end)
	end)
else
	warn("PortraitServer: no AwardItems event - portraits cannot be bought")
end
-- MAKING GOOD: anyone who has paid for a portrait but was never painted - those missed first purchases above all - gets
-- it painted when they next come in, with an apology in the note. The count painted is kept per player, so a sitter
-- moved off the easels by newer ones is not hung again on every visit.
local function owed(player)
	if not store then return end
	local t0 = os.clock()
	while player.Parent and not (player:GetAttribute("SaveLoaded") and listLoaded) and os.clock() - t0 < 40 do task.wait(0.5) end
	if not player.Parent or not listLoaded then return end
	local bought = tonumber(player:GetAttribute("Item_portrait")) or 0
	if bought <= 0 then return end
	local ok, painted = pcall(function() return store:GetAsync(paintedKey(player.UserId)) end)
	if not ok then return end
	painted = tonumber(painted)
	local onWall = false
	for _, e in ipairs(list) do if tonumber(e.id) == player.UserId then onWall = true end end
	if (painted == nil and not onWall) or (painted ~= nil and bought > painted) then
		task.wait(5)                                        -- their screen is up by now, so they see the note
		if not player.Parent then return end
		hang(player, true)
		print("PortraitServer: made good " .. player.Name .. "'s unpainted portrait (bought " .. bought .. ", painted " .. tostring(painted) .. ")")
	end
	if painted == nil or bought > painted then remember(player) end
end
Players.PlayerAdded:Connect(function(p) task.spawn(owed, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(owed, p) end
show()
task.spawn(load)
print("PortraitServer: ready - " .. (store and "gallery saved in DataStore PortraitWall" or "no DataStore, gallery kept in memory"))
]====],before=[====[-- PortraitServer: the sitters' list (newest first, at most Slots), its save, and the easels' pictures
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local G = script.Parent
local slots = G:WaitForChild("Slots")
local done = G:WaitForChild("PortraitDone")
local MAX = G:GetAttribute("Slots") or 12
local store
pcall(function() store = DSS:GetDataStore("PortraitWall") end)
local list = {}                                              -- {id=, name=, t=}, newest first

local function show()
	for i = 1, MAX do
		local slot = slots:FindFirstChild("Slot" .. i)
		local canvas = slot and slot:FindFirstChild("Canvas", true)
		local gui = canvas and canvas:FindFirstChild("Picture")
		local plaque = slot and slot:FindFirstChild("Plaque")
		local e = list[i]
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
			-- the dressing, from the user id: one of five painted scenes always, a companion four times in five (Shannon: "I
			-- like the different backgrounds and companions")
			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
			-- the sitter's place: centred, or to one side when the scene asks (SitX / SitScale attributes on the scene frame);
			-- a corner companion then shows on the far side - its mirrored copy when it was drawn on the sitter's side
			local sf = e and G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)   -- the template to clone
			local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
			img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(e.id) .. "&w=420&h=420"
				img.Visible = true; wash.Visible = true
			else
				img.Image = ""; img.Visible = false; wash.Visible = false
			end
		end
		if plaque then
			local sg = plaque:FindFirstChildWhichIsA("SurfaceGui")
			local t = sg and sg:FindFirstChild("Name")
			if t then t.Text = e and tostring(e.name) or "" end
		end
	end
end

local function merge(saved, entry)
	local out = {}
	if entry then out[1] = entry end
	for _, e in ipairs(saved or {}) do
		if type(e) == "table" and e.id and (not entry or e.id ~= entry.id) and #out < MAX then out[#out + 1] = e end
	end
	return out
end

local listLoaded = false
local function load()
	if not store then listLoaded = true return end
	local ok, saved = pcall(function() return store:GetAsync("latest") end)
	if ok and type(saved) == "table" then list = merge(saved, nil); show() end
	listLoaded = true
end

local function hang(player, late)
	local entry = {id = player.UserId, name = player.DisplayName, t = os.time()}
	list = merge(list, entry)
	show()
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync("latest", function(saved) return merge(saved, entry) end)
		end)
		if not ok then warn("PortraitServer: could not save the gallery - " .. tostring(err)) end
	end
	-- the flourish: sparkle at the newest easel, and a word to the sitter
	local canvas = slots:FindFirstChild("Slot1") and slots.Slot1:FindFirstChild("Canvas", true)
	local em = canvas and canvas:FindFirstChild("Sparkle") and canvas.Sparkle:FindFirstChildOfClass("ParticleEmitter")
	if em then em:Emit(70) end
	done:FireClient(player, "hung", late == true)
end

-- A PURCHASE IS THE SHOP'S AWARD: the shop pays for a portrait with AwardItems(player, "portrait", 1), and that event
-- is the signal. (It used to be a RISING Item_portrait, which missed every FIRST purchase: a player who had never
-- bought one has no count in their save, so the count went from nothing to 1 - which looked like the save loading.
-- Shannon's alt paid 120 acorns and got no painting.)
local function paintedKey(uid) return "painted_u" .. tostring(uid) end
local function remember(player)                          -- how many of their portraits have been painted, kept per player
	if not store then return end
	local n = tonumber(player:GetAttribute("Item_portrait")) or 0
	local ok, err = pcall(function() store:SetAsync(paintedKey(player.UserId), n) end)
	if not ok then warn("PortraitServer: could not note " .. player.Name .. "'s painted count - " .. tostring(err)) end
end
local itemEv = game:GetService("ReplicatedStorage"):WaitForChild("AwardItems", 30)
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if id ~= "portrait" or (tonumber(n) or 0) <= 0 then return end
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		task.defer(function()
			hang(player)
			remember(player)
			print("PortraitServer: painted " .. player.Name .. " (bought " .. tostring(player:GetAttribute("Item_portrait")) .. ")")
		end)
	end)
else
	warn("PortraitServer: no AwardItems event - portraits cannot be bought")
end
-- MAKING GOOD: anyone who has paid for a portrait but was never painted - those missed first purchases above all - gets
-- it painted when they next come in, with an apology in the note. The count painted is kept per player, so a sitter
-- moved off the easels by newer ones is not hung again on every visit.
local function owed(player)
	if not store then return end
	local t0 = os.clock()
	while player.Parent and not (player:GetAttribute("SaveLoaded") and listLoaded) and os.clock() - t0 < 40 do task.wait(0.5) end
	if not player.Parent or not listLoaded then return end
	local bought = tonumber(player:GetAttribute("Item_portrait")) or 0
	if bought <= 0 then return end
	local ok, painted = pcall(function() return store:GetAsync(paintedKey(player.UserId)) end)
	if not ok then return end
	painted = tonumber(painted)
	local onWall = false
	for _, e in ipairs(list) do if tonumber(e.id) == player.UserId then onWall = true end end
	if (painted == nil and not onWall) or (painted ~= nil and bought > painted) then
		task.wait(5)                                        -- their screen is up by now, so they see the note
		if not player.Parent then return end
		hang(player, true)
		print("PortraitServer: made good " .. player.Name .. "'s unpainted portrait (bought " .. bought .. ", painted " .. tostring(painted) .. ")")
	end
	if painted == nil or bought > painted then remember(player) end
end
Players.PlayerAdded:Connect(function(p) task.spawn(owed, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(owed, p) end
show()
task.spawn(load)
print("PortraitServer: ready - " .. (store and "gallery saved in DataStore PortraitWall" or "no DataStore, gallery kept in memory"))
]====]})
table.insert(changes,{target=workspace.SandstoneClimb.ClimbServer,source=[====[-- ClimbServer: the Sandstone Climb's clock (server-side), the bell, the board and the personal-best acorns
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("ClimbEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local zone = F:WaitForChild("Summit"):WaitForChild("BellZone")
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- the bell: whoever reaches it rings it for everyone, one ring at a time ----
local lastRing = 0
local function ring(player)
	if os.clock() - lastRing < 6 then return end
	lastRing = os.clock()
	ev:FireAllClients("ring", player and player.DisplayName or "")
end

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "CliffClimb_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("ClimbBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a climber"
			end
		end
	end
 local ranks={};for i,e in ipairs(list) do if i<=10 then ranks[e.uid]=i end end
 for _,p in ipairs(Players:GetPlayers()) do
  local scope=ok and "global" or (RunService:IsStudio() and "server" or "unavailable")
  p:SetAttribute("PassportBoard_climb",game:GetService("HttpService"):JSONEncode({rank=scope~="unavailable" and (ranks[p.UserId] or 0) or 0,scope=scope,checked=workspace:GetServerTimeNow()}))
 end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end
				return cs
			end)
		end)
		if not ok then warn("SandstoneClimb: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a climb ----
local climbs = {}                                            -- player -> {phase, t0}
local function stop(player, why)
	local c = climbs[player]
	if not c then return end
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	ev:FireClient(player, "stop", why)
end
local function start(player)
	if climbs[player] then stop(player, "restart") end
	if player:GetAttribute("Racing") then ev:FireClient(player, "busy"); return end
	if not player:GetAttribute("SaveLoaded") then return end
	local c = {phase = "count"}
	climbs[player] = c
	player:SetAttribute("Climbing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, item(player, "climb_best"))
	task.delay(cd, function()
		if climbs[player] ~= c then return end
		c.phase = "run"; c.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 10) * 60, function() if climbs[player] == c then stop(player, "time") end end)
	end)
end
local function finish(player)
	local c = climbs[player]
	if not c or c.phase ~= "run" then return end
	local secs = os.clock() - c.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	local best = item(player, "climb_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "climb_best", cs) end
	local minS = F:GetAttribute("MinSeconds") or 10
	local prize = 0
	if isBest and secs >= minS then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player,"climb",{cs=cs,previousBest=best,improvement=best>cs and best-cs or 0,prize=prize,boardReady=false}) end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("SandstoneClimb: %s climbed to the bell in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= minS then
		task.spawn(submit, player, isBest and cs or best)
	else
		player:SetAttribute("PassportBoard_climb",game:GetService("HttpService"):JSONEncode({rank=0,scope="unavailable",time=workspace:GetServerTimeNow()}))
		warn(string.format("SandstoneClimb: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
zone.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	ring(player)
	if climbs[player] then finish(player) end
end)
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
local function startSpot()
	local st = F:FindFirstChild("StartStone", true)
	local y = F:GetAttribute("StartY") or ((st and st.Position.Y or 5) + 3)
	return Vector3.new(st and st.Position.X or 498, y, st and st.Position.Z or -243)
end
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not climbs[player] then
		local char = player.Character
		local p = startSpot()
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1))) end
		task.wait(0.3)
		start(player)
	end
end)
local function watch(player)
	player.CharacterAdded:Connect(function() if climbs[player] then stop(player, "fell") end end)
end
Players.PlayerAdded:Connect(watch)
for _, pl in ipairs(Players:GetPlayers()) do watch(pl) end
Players.PlayerRemoving:Connect(function(pl) climbs[pl] = nil end)
if RunService:IsStudio() then                               -- Studio only: start a climb without the prompt (for tests)
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ClimbDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) start(player); return "started" end
end
print("SandstoneClimb: ready")
]====],before=[====[-- ClimbServer: the Sandstone Climb's clock (server-side), the bell, the board and the personal-best acorns
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("ClimbEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local zone = F:WaitForChild("Summit"):WaitForChild("BellZone")
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- the bell: whoever reaches it rings it for everyone, one ring at a time ----
local lastRing = 0
local function ring(player)
	if os.clock() - lastRing < 6 then return end
	lastRing = os.clock()
	ev:FireAllClients("ring", player and player.DisplayName or "")
end

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "CliffClimb_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("ClimbBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a climber"
			end
		end
	end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end
				return cs
			end)
		end)
		if not ok then warn("SandstoneClimb: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a climb ----
local climbs = {}                                            -- player -> {phase, t0}
local function stop(player, why)
	local c = climbs[player]
	if not c then return end
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	ev:FireClient(player, "stop", why)
end
local function start(player)
	if climbs[player] then stop(player, "restart") end
	if player:GetAttribute("Racing") then ev:FireClient(player, "busy"); return end
	if not player:GetAttribute("SaveLoaded") then return end
	local c = {phase = "count"}
	climbs[player] = c
	player:SetAttribute("Climbing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, item(player, "climb_best"))
	task.delay(cd, function()
		if climbs[player] ~= c then return end
		c.phase = "run"; c.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 10) * 60, function() if climbs[player] == c then stop(player, "time") end end)
	end)
end
local function finish(player)
	local c = climbs[player]
	if not c or c.phase ~= "run" then return end
	local secs = os.clock() - c.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	local best = item(player, "climb_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "climb_best", cs) end
	local minS = F:GetAttribute("MinSeconds") or 10
	local prize = 0
	if isBest and secs >= minS then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "climb") end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("SandstoneClimb: %s climbed to the bell in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= minS then
		if isBest then task.spawn(submit, player, cs) end
	else
		warn(string.format("SandstoneClimb: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
zone.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	ring(player)
	if climbs[player] then finish(player) end
end)
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
local function startSpot()
	local st = F:FindFirstChild("StartStone", true)
	local y = F:GetAttribute("StartY") or ((st and st.Position.Y or 5) + 3)
	return Vector3.new(st and st.Position.X or 498, y, st and st.Position.Z or -243)
end
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not climbs[player] then
		local char = player.Character
		local p = startSpot()
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1))) end
		task.wait(0.3)
		start(player)
	end
end)
local function watch(player)
	player.CharacterAdded:Connect(function() if climbs[player] then stop(player, "fell") end end)
end
Players.PlayerAdded:Connect(watch)
for _, pl in ipairs(Players:GetPlayers()) do watch(pl) end
Players.PlayerRemoving:Connect(function(pl) climbs[pl] = nil end)
if RunService:IsStudio() then                               -- Studio only: start a climb without the prompt (for tests)
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ClimbDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) start(player); return "started" end
end
print("SandstoneClimb: ready")
]====]})
table.insert(changes,{target=workspace.Shop.ShopServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local buy = RS:WaitForChild("ShopBuy")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local said = RS:WaitForChild("ShopSaid")

local ITEMS = {
	seed       = {repeatable = true},
	-- the ride crosses both boundaries, so it is a reward for having earned your way there rather than a
	-- paid shortcut past the gates: the farm has to be open to you before a handle can be sold. Bought once
	-- and kept; the ride itself checks Item_ziphandle at the top of the tower.
	ziphandle  = {once = true, needsArea = "village"},
	bubbles    = {repeatable = true, palette = 6},        -- pick one of six colours; the colour is kept as Item_fountaincolour
	binoculars = {once = true, robux = true},               -- owned through the Game Pass, never bought here
	portrait   = {repeatable = true},
	slingshot  = {once = true},
	cheese     = {repeatable = true},
	backpack   = {once = true},	-- the hang glider takes off from the Sandstone Climb's summit in the Chateau, so it is sold once the Chateau is open
	-- to you (like the zipline handle); bought once and kept - the ramp checks Item_glider (workspace.HangGlider)
	glider     = {once = true, needsArea = "village"},
	zoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it
}

local busy = {}                                        -- one purchase at a time per player

local function purchase(player, id, variant)
	if typeof(id) ~= "string" then return false, "no such thing" end
	local item = ITEMS[id]
	if not item then return false, "no such thing" end

	-- Robux items are never sold for acorns, whatever a client asks for
	if item.robux then return false, "Robux only" end

	-- a colour has to be one of the palette (whether the fountain is free is checked again just before paying)
	if item.palette then
		variant = tonumber(variant)
		if not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end
	end
	-- THE FOUNTAIN IS THE WHOLE SERVER'S (Shannon, Sep 26: "when somebody turns the fountain color with bubbles, I want
	-- everybody to be able to see it ... It can only be chosen if it's not currently colored"): one colour at a time
	local function fountainTaken()
		local FC = workspace:FindFirstChild("FountainColour")
		local untilT = FC and FC:GetAttribute("ActiveUntil") or 0
		local left = untilT - workspace:GetServerTimeNow()
		if FC and (FC:GetAttribute("ActiveColour") or 0) > 0 and left > 0 then
			left = math.ceil(left)
			return string.format("the fountain is taken - free in %d:%02d", math.floor(left / 60), left % 60)
		end
		return nil
	end
	if item.palette and fountainTaken() then return false, fountainTaken() end

	-- Enforced HERE, not merely greyed out in the panel: a button that only looks disabled is one a
	-- modified client clicks anyway, and it would take the acorns.
	if F:GetAttribute("Selling") ~= true and F:GetAttribute("Sell_" .. id) ~= true then
		return false, "not on sale yet"
	end

	-- Two clicks arriving together must not spend the money twice. The flag goes up before anything is read,
	-- because the whole check-then-deduct sequence has to be indivisible.
	if busy[player] then return false, "one at a time" end
	busy[player] = true
	local ok, res, why = pcall(function()
		-- Every item has one price now. The mime used to take whatever you offered, which meant a text box, a
		-- keyboard on a phone and a way to mistype a fortune into a hat; three acorns is simply what it costs.
		local price = F:GetAttribute("Price_" .. id)
		if type(price) ~= "number" then return false, "no price set" end

		if item.once and (player:GetAttribute("Item_" .. id) or 0) > 0 then
			return false, "you already have one"
		end

		if item.needsArea then
			local B
			for _, b in ipairs(workspace:GetChildren()) do
				if b.Name == "Boundary" and b:FindFirstChild("Walls") then B = b end
			end
			local need = (B and B:GetAttribute("Need")) or 10
			if (player:GetAttribute("Found_" .. item.needsArea) or 0) < need then
				return false, string.format("find %d in the Rue first", need)
			end
		end

		-- the purse as the SERVER sees it. A client cannot change an attribute the server set, so this is the
		-- real balance rather than whatever the shop panel happens to be showing.
		local have = player:GetAttribute("Acorns") or 0
		if have < price then return false, "not enough acorns" end
		if item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)

		awardAcorns:Fire(player, -price)               -- spending is a negative award, same ledger, same merge
		player:SetAttribute("Acorns", have - price)
		awardItems:Fire(player, id, 1)
		if item.clock then
			-- a timed thing: its clock is an item whose COUNT is the moment it runs out (server time, whole seconds),
			-- moved by a delta like everything else. Buying again while it runs adds to what is left.
			local home = workspace:FindFirstChild(item.home or "")
			local minutes = (home and home:GetAttribute(item.minutes or "")) or 10
			local cur = player:GetAttribute("Item_" .. item.clock) or 0
			local from = math.max(cur, math.floor(workspace:GetServerTimeNow()))
			awardItems:Fire(player, item.clock, from + minutes * 60 - cur)
		end
		if item.palette then
			-- the whole server's fountain runs this colour for Minutes (on workspace.FountainColour) from now: ActiveColour,
			-- ActiveUntil (server time) and ActiveBy there, which every player's FountainClient draws and the shop panel
			-- counts down; it belongs to this server (the buyer leaving doesn't stop it). Shannon: "10 minutes ... just set it".
			local FC = workspace:FindFirstChild("FountainColour")
			local minutes = (FC and FC:GetAttribute("Minutes")) or 10
			if FC then
				FC:SetAttribute("ActiveBy", player.DisplayName)
				FC:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60))
				FC:SetAttribute("ActiveColour", variant)
				local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"bubbles",{colour=({"pink","orange","gold","green","blue","violet"})[variant]}) end
			end
		end
		return true, price
	end)
	busy[player] = nil
	if not ok then
		warn("ShopServer: purchase of " .. tostring(id) .. " failed - " .. tostring(res))
		return false, "something went wrong"
	end
	return res, why
end

buy.OnServerInvoke = function(player, id, variant) return purchase(player, id, variant) end

-- Some things are bought where they are, from a prompt in the world, rather than from the panel. Same
-- purchase, same checks, same ledger - only the way you ask for it differs.
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, player)
	local id = prompt:GetAttribute("ShopItem")
	if type(id) == "string" and id ~= "" then
		local ok, why = purchase(player, id)
		said:FireClient(player, id, ok, why)                -- a prompt has no panel to write on; the client toasts it
	end
end)

Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("ShopServer: ready")
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local buy = RS:WaitForChild("ShopBuy")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local said = RS:WaitForChild("ShopSaid")

local ITEMS = {
	seed       = {repeatable = true},
	-- the ride crosses both boundaries, so it is a reward for having earned your way there rather than a
	-- paid shortcut past the gates: the farm has to be open to you before a handle can be sold. Bought once
	-- and kept; the ride itself checks Item_ziphandle at the top of the tower.
	ziphandle  = {once = true, needsArea = "village"},
	bubbles    = {repeatable = true, palette = 6},        -- pick one of six colours; the colour is kept as Item_fountaincolour
	binoculars = {once = true, robux = true},               -- owned through the Game Pass, never bought here
	portrait   = {repeatable = true},
	slingshot  = {once = true},
	cheese     = {repeatable = true},
	backpack   = {once = true},	-- the hang glider takes off from the Sandstone Climb's summit in the Chateau, so it is sold once the Chateau is open
	-- to you (like the zipline handle); bought once and kept - the ramp checks Item_glider (workspace.HangGlider)
	glider     = {once = true, needsArea = "village"},
	zoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it
}

local busy = {}                                        -- one purchase at a time per player

local function purchase(player, id, variant)
	if typeof(id) ~= "string" then return false, "no such thing" end
	local item = ITEMS[id]
	if not item then return false, "no such thing" end

	-- Robux items are never sold for acorns, whatever a client asks for
	if item.robux then return false, "Robux only" end

	-- a colour has to be one of the palette (whether the fountain is free is checked again just before paying)
	if item.palette then
		variant = tonumber(variant)
		if not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end
	end
	-- THE FOUNTAIN IS THE WHOLE SERVER'S (Shannon, Sep 26: "when somebody turns the fountain color with bubbles, I want
	-- everybody to be able to see it ... It can only be chosen if it's not currently colored"): one colour at a time
	local function fountainTaken()
		local FC = workspace:FindFirstChild("FountainColour")
		local untilT = FC and FC:GetAttribute("ActiveUntil") or 0
		local left = untilT - workspace:GetServerTimeNow()
		if FC and (FC:GetAttribute("ActiveColour") or 0) > 0 and left > 0 then
			left = math.ceil(left)
			return string.format("the fountain is taken - free in %d:%02d", math.floor(left / 60), left % 60)
		end
		return nil
	end
	if item.palette and fountainTaken() then return false, fountainTaken() end

	-- Enforced HERE, not merely greyed out in the panel: a button that only looks disabled is one a
	-- modified client clicks anyway, and it would take the acorns.
	if F:GetAttribute("Selling") ~= true and F:GetAttribute("Sell_" .. id) ~= true then
		return false, "not on sale yet"
	end

	-- Two clicks arriving together must not spend the money twice. The flag goes up before anything is read,
	-- because the whole check-then-deduct sequence has to be indivisible.
	if busy[player] then return false, "one at a time" end
	busy[player] = true
	local ok, res, why = pcall(function()
		-- Every item has one price now. The mime used to take whatever you offered, which meant a text box, a
		-- keyboard on a phone and a way to mistype a fortune into a hat; three acorns is simply what it costs.
		local price = F:GetAttribute("Price_" .. id)
		if type(price) ~= "number" then return false, "no price set" end

		if item.once and (player:GetAttribute("Item_" .. id) or 0) > 0 then
			return false, "you already have one"
		end

		if item.needsArea then
			local B
			for _, b in ipairs(workspace:GetChildren()) do
				if b.Name == "Boundary" and b:FindFirstChild("Walls") then B = b end
			end
			local need = (B and B:GetAttribute("Need")) or 10
			if (player:GetAttribute("Found_" .. item.needsArea) or 0) < need then
				return false, string.format("find %d in the Rue first", need)
			end
		end

		-- the purse as the SERVER sees it. A client cannot change an attribute the server set, so this is the
		-- real balance rather than whatever the shop panel happens to be showing.
		local have = player:GetAttribute("Acorns") or 0
		if have < price then return false, "not enough acorns" end
		if item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)

		awardAcorns:Fire(player, -price)               -- spending is a negative award, same ledger, same merge
		player:SetAttribute("Acorns", have - price)
		awardItems:Fire(player, id, 1)
		if item.clock then
			-- a timed thing: its clock is an item whose COUNT is the moment it runs out (server time, whole seconds),
			-- moved by a delta like everything else. Buying again while it runs adds to what is left.
			local home = workspace:FindFirstChild(item.home or "")
			local minutes = (home and home:GetAttribute(item.minutes or "")) or 10
			local cur = player:GetAttribute("Item_" .. item.clock) or 0
			local from = math.max(cur, math.floor(workspace:GetServerTimeNow()))
			awardItems:Fire(player, item.clock, from + minutes * 60 - cur)
		end
		if item.palette then
			-- the whole server's fountain runs this colour for Minutes (on workspace.FountainColour) from now: ActiveColour,
			-- ActiveUntil (server time) and ActiveBy there, which every player's FountainClient draws and the shop panel
			-- counts down; it belongs to this server (the buyer leaving doesn't stop it). Shannon: "10 minutes ... just set it".
			local FC = workspace:FindFirstChild("FountainColour")
			local minutes = (FC and FC:GetAttribute("Minutes")) or 10
			if FC then
				FC:SetAttribute("ActiveBy", player.DisplayName)
				FC:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60))
				FC:SetAttribute("ActiveColour", variant)
			end
		end
		return true, price
	end)
	busy[player] = nil
	if not ok then
		warn("ShopServer: purchase of " .. tostring(id) .. " failed - " .. tostring(res))
		return false, "something went wrong"
	end
	return res, why
end

buy.OnServerInvoke = function(player, id, variant) return purchase(player, id, variant) end

-- Some things are bought where they are, from a prompt in the world, rather than from the panel. Same
-- purchase, same checks, same ledger - only the way you ask for it differs.
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, player)
	local id = prompt:GetAttribute("ShopItem")
	if type(id) == "string" and id ~= "" then
		local ok, why = purchase(player, id)
		said:FireClient(player, id, ok, why)                -- a prompt has no panel to write on; the client toasts it
	end
end)

Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("ShopServer: ready")
]====]})
table.insert(changes,{target=workspace.Speed.SpeedServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("SpeedEvent")
local function now() return workspace:GetServerTimeNow() end

-- coffee: only for someone sitting at that very table
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CoffeePrompt" or not prompt:IsDescendantOf(F) then return end
	local cup = prompt:FindFirstAncestorOfClass("Model")
	local link = cup and cup:FindFirstChild("Table")
	local tbl = link and link.Value
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tbl and hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(tbl)) then return end
	local secs = F:GetAttribute("CoffeeSeconds") or 300
	local untilT = tonumber(player:GetAttribute("CoffeeUntil")) or 0
	if untilT - now() > secs - 4 then return end                  -- the last cup is still going down
	player:SetAttribute("CoffeeUntil", now() + secs)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"coffee",{seconds=secs,boost=math.floor(((F:GetAttribute("CoffeeBoost") or 1.35)-1)*100+0.5)}) end
	ev:FireClient(player, "coffee", secs, cup)
	print(string.format("Speed: %s drank a coffee (%ds)", player.Name, secs))
end)

-- zoomies: bought in the Acorn Store, where the ShopServer moves the clock (Item_zoomiesuntil); this only reads it

-- the speed itself, from everything above
local lastSet = setmetatable({}, {__mode = "k"})
while true do
	local t = now()
	local base = F:GetAttribute("BaseSpeed") or 16
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local m = 1
			if (tonumber(player:GetAttribute("CoffeeUntil")) or 0) > t then m *= F:GetAttribute("CoffeeBoost") or 1.35 end
			local racing = player:GetAttribute("Racing") == true
			if (tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0) > t and (not racing or F:GetAttribute("PaidInRace") == true) then
				m *= F:GetAttribute("ZoomiesBoost") or 1.3
			end
			local want = math.floor(base * m * 10 + 0.5) / 10
			-- only while the speed is ours to set: something else (a ride, say) may have its own idea for a moment
			-- (WalkSpeed is stored at lower precision, so 21.6 reads back as 21.600000381: compare with a tolerance)
			local mine = lastSet[hum]
			if mine == nil or math.abs(hum.WalkSpeed - mine) < 0.05 or math.abs(hum.WalkSpeed - base) < 0.05 then
				if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
				lastSet[hum] = want
			end
			if player:GetAttribute("SpeedMult") ~= m then player:SetAttribute("SpeedMult", m) end
		end
	end
	task.wait(0.25)
end
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("SpeedEvent")
local function now() return workspace:GetServerTimeNow() end

-- coffee: only for someone sitting at that very table
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CoffeePrompt" or not prompt:IsDescendantOf(F) then return end
	local cup = prompt:FindFirstAncestorOfClass("Model")
	local link = cup and cup:FindFirstChild("Table")
	local tbl = link and link.Value
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tbl and hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(tbl)) then return end
	local secs = F:GetAttribute("CoffeeSeconds") or 300
	local untilT = tonumber(player:GetAttribute("CoffeeUntil")) or 0
	if untilT - now() > secs - 4 then return end                  -- the last cup is still going down
	player:SetAttribute("CoffeeUntil", now() + secs)
	ev:FireClient(player, "coffee", secs, cup)
	print(string.format("Speed: %s drank a coffee (%ds)", player.Name, secs))
end)

-- zoomies: bought in the Acorn Store, where the ShopServer moves the clock (Item_zoomiesuntil); this only reads it

-- the speed itself, from everything above
local lastSet = setmetatable({}, {__mode = "k"})
while true do
	local t = now()
	local base = F:GetAttribute("BaseSpeed") or 16
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local m = 1
			if (tonumber(player:GetAttribute("CoffeeUntil")) or 0) > t then m *= F:GetAttribute("CoffeeBoost") or 1.35 end
			local racing = player:GetAttribute("Racing") == true
			if (tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0) > t and (not racing or F:GetAttribute("PaidInRace") == true) then
				m *= F:GetAttribute("ZoomiesBoost") or 1.3
			end
			local want = math.floor(base * m * 10 + 0.5) / 10
			-- only while the speed is ours to set: something else (a ride, say) may have its own idea for a moment
			-- (WalkSpeed is stored at lower precision, so 21.6 reads back as 21.600000381: compare with a tolerance)
			local mine = lastSet[hum]
			if mine == nil or math.abs(hum.WalkSpeed - mine) < 0.05 or math.abs(hum.WalkSpeed - base) < 0.05 then
				if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
				lastSet[hum] = want
			end
			if player:GetAttribute("SpeedMult") ~= m then player:SetAttribute("SpeedMult", m) end
		end
	end
	task.wait(0.25)
end
]====]})
table.insert(changes,{target=workspace.SquirrelScripts.SquirrelSetup,source=[====[
-- SquirrelSetup (server)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = script.Parent

local function isSquirrelMesh(p)
	return p:IsA("MeshPart") and p:FindFirstChild("Tail2", true) ~= nil and p:FindFirstChild("Root", true) ~= nil
end
local function getTex(mesh)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then return sa.ColorMap end
	return mesh.TextureID
end
local function setTex(mesh, id)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then sa.ColorMap = id else mesh.TextureID = id end
end

if folder:GetAttribute("FoundSound") == nil then folder:SetAttribute("FoundSound", "rbxassetid://1845415163") end
if folder:GetAttribute("NameTagSeconds") == nil then folder:SetAttribute("NameTagSeconds", 3.2) end
if folder:GetAttribute("MaskImage") == nil then folder:SetAttribute("MaskImage", "rbxassetid://77268792392056") end   -- white square, transparent circle
local PER_PLAYER = folder:GetAttribute("PerPlayer")
if PER_PLAYER == nil then PER_PLAYER = true; folder:SetAttribute("PerPlayer", true) end
local TARGET_HEIGHT = folder:GetAttribute("TargetHeight") or 2.9      -- studs tall; the meshes come in at 2.4
folder:SetAttribute("TargetHeight", TARGET_HEIGHT)

local ev = ReplicatedStorage:FindFirstChild("SquirrelFound") or Instance.new("RemoteEvent")
ev.Name = "SquirrelFound"; ev.Parent = ReplicatedStorage
local sync = ReplicatedStorage:FindFirstChild("SquirrelSync") or Instance.new("RemoteFunction")
sync.Name = "SquirrelSync"; sync.Parent = ReplicatedStorage

-- 1. collect every squirrel mesh in the Workspace
local meshes = {}
for _, p in ipairs(workspace:GetDescendants()) do if isSquirrelMesh(p) then table.insert(meshes, p) end end
local function modelOf(mesh) return mesh:FindFirstAncestorOfClass("Model") or mesh end
local function baseName(inst)
	local n = string.lower(modelOf(inst).Name .. " " .. inst.Name)
	n = n:gsub("_gray", ""):gsub("gray", ""):gsub("_color", ""):gsub("color", ""):gsub("%s+", " ")
	return n
end
local function isGray(inst) return string.find(string.lower(modelOf(inst).Name .. " " .. inst.Name), "gray") ~= nil end

-- 2. pair colour + gray by base name (fallback: identical mesh size)
local grays, colours = {}, {}
for _, mesh in ipairs(meshes) do
	if mesh:GetAttribute("GrayTexture") then table.insert(colours, mesh)          -- already set up (saved place)
	elseif isGray(mesh) then table.insert(grays, mesh) else table.insert(colours, mesh) end
end
for _, c in ipairs(colours) do
	if not c:GetAttribute("GrayTexture") then
		local twin
		for i, g in ipairs(grays) do
			if baseName(g) == baseName(c) then twin = g; table.remove(grays, i); break end
		end
		if not twin then
			for i, g in ipairs(grays) do
				if (g.Size - c.Size).Magnitude < 0.01 * c.Size.Magnitude then twin = g; table.remove(grays, i); break end
			end
		end
		if twin then
			c:SetAttribute("GrayTexture", getTex(twin)); c:SetAttribute("ColorTexture", getTex(c))
			modelOf(twin).Parent = nil
			print("SquirrelSetup: paired", modelOf(c):GetFullName(), "with its gray twin")
		else
			c:SetAttribute("ColorTexture", getTex(c))
			warn("SquirrelSetup: no gray twin found for " .. modelOf(c):GetFullName() .. " (import the _gray FBX too, name must contain 'gray'); it will start in colour")
		end
	end
end
for _, g in ipairs(grays) do warn("SquirrelSetup: unpaired gray squirrel " .. modelOf(g):GetFullName()) end

-- display names (shown on the floating tag when found); matched against the model name, first hit wins.
-- Set a DisplayName attribute on a squirrel model to override.
-- the registry: names, bios, maps, framing. Edit SquirrelRegistry, not this script.
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local byId = {}
for _, e in ipairs(Registry.squirrels) do byId[e.id] = e end
local THIS_MAP = folder:GetAttribute("MapId") or "forest"
folder:SetAttribute("MapId", THIS_MAP)
local function baseId(model)
	local n = model.Name:lower():gsub("_color$", ""):gsub("_gray$", "")
	return n
end
-- 3. set each one up
local squirrels = {}     -- id -> mesh
local function setup(mesh)
	local model = modelOf(mesh)
	local entry = byId[baseId(model)]
	if entry then
		model:SetAttribute("SquirrelId", entry.id)
		if not model:GetAttribute("DisplayName") then model:SetAttribute("DisplayName", entry.name) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", entry.bio or "") end
	else
		warn("SquirrelSetup: " .. model.Name .. " is not in SquirrelRegistry; add it there (id = '" .. baseId(model) .. "')")
		if not model:GetAttribute("SquirrelId") then model:SetAttribute("SquirrelId", baseId(model)) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", "A squirrel of mystery. Nobody knows where they came from, least of all them.") end
	end
	if model == mesh then     -- bare MeshPart: wrap it so ScaleTo / PivotTo work
		local wrap = Instance.new("Model"); wrap.Name = mesh.Name; wrap.Parent = mesh.Parent; mesh.Parent = wrap; model = wrap
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true; p.CanTouch = true end
	end
	model.PrimaryPart = model.PrimaryPart or mesh
	-- scale to TargetHeight, keeping the feet where they are
	local targetH = model:GetAttribute("TargetHeight") or TARGET_HEIGHT   -- a squirrel whose prop sticks up (the kite) sets its own
	if math.abs(mesh.Size.Y - targetH) > 0.02 then
		local cf0, sz0 = model:GetBoundingBox()
		local bottom = cf0.Position.Y - sz0.Y / 2
		model:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)
		local cf1, sz1 = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() + Vector3.new(cf0.Position.X - cf1.Position.X, bottom - (cf1.Position.Y - sz1.Y / 2), cf0.Position.Z - cf1.Position.Z))
	end
	local id = model:GetAttribute("SquirrelId")
	if not id or squirrels[id] then
		id = baseId(model); local k = 1
		while squirrels[id] do k += 1; id = baseId(model) .. "_" .. k end
		model:SetAttribute("SquirrelId", id)
	end
	squirrels[id] = mesh
	CollectionService:AddTag(model, "Squirrel")
	if not PER_PLAYER then
		local gray = mesh:GetAttribute("GrayTexture")
		if gray and not model:GetAttribute("Found") then setTex(mesh, gray) end
		if model:GetAttribute("Found") == nil then model:SetAttribute("Found", false) end
	end
	return model, id
end
local total = 0
for _, mesh in ipairs(colours) do setup(mesh); total += 1 end
folder:SetAttribute("Total", total)
local mapTotal = 0
for _, e in ipairs(Registry.squirrels) do if e.map == THIS_MAP then mapTotal += 1 end end
folder:SetAttribute("MapTotal", mapTotal); folder:SetAttribute("AllTotal", #Registry.squirrels)
print(string.format("SquirrelSetup: %d squirrels ready (%s)", total, PER_PLAYER and "per-player finds" or "shared finds"))

-- 4. finds, saved per player in a DataStore so they survive leaving and rejoining
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local USE_STORE = folder:GetAttribute("UseDataStore")
if USE_STORE == nil then USE_STORE = true; folder:SetAttribute("UseDataStore", true) end
local STORE_KEY = folder:GetAttribute("SaveKey") or "SquirrelFinds_v1"
folder:SetAttribute("SaveKey", STORE_KEY)
local store
if USE_STORE and PER_PLAYER then
	local ok, err = pcall(function() store = DataStoreService:GetDataStore(STORE_KEY) end)
	if not ok then warn("SquirrelSetup: DataStore unavailable, finds will not be saved: " .. tostring(err)); store = nil end
end
local found = {}          -- userId -> { [id] = true }
local loaded = {}         -- userId -> true once the DataStore load finished (or was skipped)
local canSave = {}        -- userId -> false when the load failed (never overwrite good data with an empty list)
local dirty = {}          -- userId -> true when there is something new to save
local Journal=require(workspace:WaitForChild("Passport"):WaitForChild("Journal"))
local Http=game:GetService("HttpService")
local passportPending={}
local passportLoaded={}
local owedItems = {}      -- userId -> {itemId = delta}; same reasoning as the purse below, per item
local owed = {}           -- userId -> acorns earned but not yet written, applied as a DELTA so that two
                          -- servers adding to the same purse cannot overwrite one another
local function foundList(player)
	local t = found[player.UserId]
	if not t then t = {}; found[player.UserId] = t end
	return t
end
local function count(t) local n = 0 for _ in pairs(t) do n += 1 end return n end
local function publishCounts(player)
	local t = foundList(player)
	local per = {}
	for _, e in ipairs(Registry.squirrels) do if t[e.id] then per[e.map] = (per[e.map] or 0) + 1 end end
	for _, m in ipairs(Registry.maps) do player:SetAttribute("Found_" .. m.id, per[m.id] or 0) end
	local ids = {}
	for id in pairs(t) do table.insert(ids, id) end
	table.sort(ids)
	player:SetAttribute("FoundIds", table.concat(ids, ","))
end
local function loadPlayer(player)
	local uid = player.UserId
	canSave[uid] = true
	if store then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
			if ok then break end
			task.wait(1.5)
		end
		if ok then
			passportLoaded[uid]=Journal.merge(type(data)=="table" and data.passport or {},passportPending[uid] or {})
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end
			if type(data) == "table" and type(data.area) == "string" then player:SetAttribute("SavedArea", data.area) end
			if type(data) == "table" and type(data.items) == "table" then
				for id, n in pairs(data.items) do
					if type(id) == "string" and tonumber(n) then
						player:SetAttribute("Item_" .. id, tonumber(n) + ((owedItems[uid] or {})[id] or 0))
					end
				end
			end
			if type(data) == "table" and tonumber(data.acorns) then
				player:SetAttribute("Acorns", tonumber(data.acorns) + (owed[uid] or 0))
			end
			print(string.format("SquirrelSetup: loaded %d saved finds for %s", count(t), player.Name))
		else
			canSave[uid] = false
			warn("SquirrelSetup: could not load finds for " .. player.Name .. " (" .. tostring(data) .. "); this session will not be saved")
		end
	end
	passportLoaded[uid]=Journal.merge(passportLoaded[uid] or {},passportPending[uid] or {})
	player:SetAttribute("PassportJournal",Http:JSONEncode(passportLoaded[uid]))
	loaded[uid] = true
	player:SetAttribute("SaveLoaded", true)
	if player:GetAttribute("Acorns") == nil then player:SetAttribute("Acorns", 0) end
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
	publishCounts(player)
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] then return end
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local movedPassport=Journal.merge(passportPending[uid] or {},{})
	local gain = owed[uid] or 0                                   -- captured BEFORE the call: UpdateAsync can
	local movedItems = {}                                         -- likewise, a snapshot of the item deltas
	for id, d in pairs(owedItems[uid] or {}) do movedItems[id] = d end
	local ok, err = pcall(function()                              -- re-run its callback, and more can be earned
		store:UpdateAsync("u" .. uid, function(old)                -- while it is in flight
			-- merge with whatever is already saved, so two servers never erase each other's finds
			local merged = {}
			if type(old) == "table" and type(old.found) == "table" then for _, id in ipairs(old.found) do merged[id] = true end end
			for _, id in ipairs(list) do merged[id] = true end
			local out = {}
			for id in pairs(merged) do table.insert(out, id) end
			local area = player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil
			-- acorns are a purse, not a set: add what was earned to what is there rather than replacing it
			local acorns = ((type(old) == "table" and tonumber(old.acorns)) or 0) + gain
			-- the same treatment for owned things: add what changed, never replace the list
			local items = {}
			if type(old) == "table" and type(old.items) == "table" then
				for id, n in pairs(old.items) do items[id] = tonumber(n) or 0 end
			end
			for id, d in pairs(movedItems) do
				local n = (items[id] or 0) + d
				items[id] = n > 0 and n or nil                    -- a count of zero is simply not owned
			end
			return {found = out, area = area, acorns = acorns, items = items, passport=Journal.merge(type(old)=="table" and old.passport or {},movedPassport), updated = os.time()}
		end)
	end)
	if ok then
		dirty[uid] = nil
		for id,record in pairs(movedPassport) do
		 if passportPending[uid] and passportPending[uid][id] and passportPending[uid][id].at==record.at then passportPending[uid][id]=nil end
		end
		if next(passportPending[uid] or {}) then dirty[uid]=true end
		owed[uid] = (owed[uid] or 0) - gain                        -- only what actually went in, never more
		local pend = owedItems[uid]
		if pend then
			for id, d in pairs(movedItems) do
				local left = (pend[id] or 0) - d
				pend[id] = left ~= 0 and left or nil
			end
		end
	else
		warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))
	end
end
-- The acorn server never touches the DataStore. It fires this, and the one script that owns the key writes it.
local awardEv = game:GetService("ReplicatedStorage"):FindFirstChild("AwardAcorns")
if awardEv and awardEv:IsA("BindableEvent") then
	awardEv.Event:Connect(function(player, n)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		n = tonumber(n) or 0
		if n == 0 then return end
		owed[player.UserId] = (owed[player.UserId] or 0) + n
		dirty[player.UserId] = true
	end)
end
-- Granting or taking away an item. The shop never touches the DataStore; it fires this, and the one script
-- that owns the key records it. A negative n is how something is consumed.
local itemEv = game:GetService("ReplicatedStorage"):FindFirstChild("AwardItems")
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		if type(id) ~= "string" or id == "" then return end
		n = tonumber(n) or 0
		if n == 0 then return end
		local uid = player.UserId
		owedItems[uid] = owedItems[uid] or {}
		owedItems[uid][id] = (owedItems[uid][id] or 0) + n
		local have = (player:GetAttribute("Item_" .. id) or 0) + n
		player:SetAttribute("Item_" .. id, have > 0 and have or 0)
		dirty[uid] = true
	end)
end
local passportSave=ReplicatedStorage:WaitForChild("PassportSave")
passportSave.Event:Connect(function(player,id,record)
 if typeof(player)~="Instance" or not player:IsA("Player") then return end
 local clean=Journal.clean(id,record);if not clean then return end
 local uid=player.UserId
 passportPending[uid]=Journal.merge(passportPending[uid] or {},{[id]=clean})
 passportLoaded[uid]=Journal.merge(passportLoaded[uid] or {},{[id]=clean})
 player:SetAttribute("PassportJournal",Http:JSONEncode(passportLoaded[uid]))
 dirty[uid]=true
end)
Players.PlayerAdded:Connect(loadPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	if dirty[player.UserId] then savePlayer(player) end
	task.delay(5, function()
		local uid = player.UserId
		found[uid] = nil; loaded[uid] = nil; canSave[uid] = nil; dirty[uid] = nil
		owed[uid] = nil; owedItems[uid] = nil;passportPending[uid]=nil;passportLoaded[uid]=nil
	end)
end)
-- save anything new every few seconds rather than on every single click
task.spawn(function()
	while true do
		task.wait(8)
		for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
	end
end)
game:BindToClose(function()
	if not store then return end
	for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
end)
sync.OnServerInvoke = function(player)
	local list = {}
	if PER_PLAYER then
		local waited = 0
		while not loaded[player.UserId] and waited < 15 do task.wait(0.25); waited += 0.25 end
		for id in pairs(foundList(player)) do table.insert(list, id) end
	else
		for id, mesh in pairs(squirrels) do if modelOf(mesh):GetAttribute("Found") then table.insert(list, id) end end
	end
	return list
end
local function onFound(player, model, id, mesh)
 local char=player and player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hrp or not hum or hum.Health<=0 or not loaded[player.UserId] or (hrp.Position-mesh.Position).Magnitude>(folder:GetAttribute("ClickDistance") or 32)+mesh.Size.Magnitude/2 then return end
	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		publishCounts(player)
		ev:FireClient(player, id)                      -- only this player sees it turn to colour
	else
		if model:GetAttribute("Found") then return end
		model:SetAttribute("Found", true)
		setTex(mesh, mesh:GetAttribute("ColorTexture"))
		local n = 0
		for _, m2 in pairs(squirrels) do if modelOf(m2):GetAttribute("Found") then n += 1 end end
		folder:SetAttribute("FoundCount", n)
		ev:FireAllClients(id, player)                  -- everyone sees the reveal
	end
 local e=byId[id];local area=e and e.map or "forest"
 local areas={forest="Great Acorn Forest",village="Rue de Noisette",domaine="Château de l'Acorn"}
 local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"find",{name=model:GetAttribute("DisplayName") or (e and e.name) or id,area=areas[area] or area}) end
	print(string.format("SquirrelSetup: %s found %s", player.Name, id))
end
-- FindBy attribute on the folder: "click" (default), "touch", or "both"
local FIND_BY = folder:GetAttribute("FindBy")
if FIND_BY == nil then FIND_BY = "both"; folder:SetAttribute("FindBy", "both") end
local CLICK_DIST = folder:GetAttribute("ClickDistance") or 32
folder:SetAttribute("ClickDistance", CLICK_DIST)
for id, mesh in pairs(squirrels) do
	local model = modelOf(mesh)
	if FIND_BY == "click" or FIND_BY == "both" then
		for _, old in ipairs(mesh:GetChildren()) do if old:IsA("ClickDetector") then old:Destroy() end end
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = CLICK_DIST
		-- Cursor attribute on the folder: "hand" (Roblox's pointing-hand default), "arrow" (no change), or an asset id
		local cur = folder:GetAttribute("Cursor") or "hand"
		folder:SetAttribute("Cursor", cur)
		if cur == "arrow" then cd.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
		elseif cur ~= "hand" and cur ~= "" then cd.CursorIcon = cur end
		cd.Parent = mesh
		cd.MouseClick:Connect(function(player) onFound(player, model, id, mesh) end)
	end
	if FIND_BY == "touch" or FIND_BY == "both" then
		local debounce = {}
		mesh.Touched:Connect(function(hit)
			local char = hit:FindFirstAncestorOfClass("Model")
			local player = char and Players:GetPlayerFromCharacter(char)
			if not player then return end
			if debounce[player] and os.clock() - debounce[player] < 1 then return end
			debounce[player] = os.clock()
			onFound(player, model, id, mesh)
		end)
	end
end

-- ---- reset: wipe this player's finds on request (the "Reset progress" button asks twice before sending it) ----
local resetEv = ReplicatedStorage:FindFirstChild("SquirrelReset") or Instance.new("RemoteEvent")
resetEv.Name = "SquirrelReset"; resetEv.Parent = ReplicatedStorage
local resetAt = {}
resetEv.OnServerEvent:Connect(function(player)
	local uid = player.UserId
	if os.clock() - (resetAt[uid] or -60) < 5 then return end          -- one wipe at a time
	resetAt[uid] = os.clock()
	found[uid] = {}
	dirty[uid] = nil
	if store and canSave[uid] then
		local ok, err = pcall(function()
			-- a true wipe of the FINDS, not a merge - but the purse survives it. Resetting which squirrels you
			-- have found is not a reason to take away acorns that were earned separately.
			store:UpdateAsync("u" .. uid, function(old)
				return {found = {}, acorns = (type(old) == "table" and tonumber(old.acorns)) or 0, items=type(old)=="table" and old.items or {}, passport=Journal.merge(type(old)=="table" and old.passport or {},passportPending[uid] or {}), updated = os.time()}
			end)
		end)
		if not ok then warn("SquirrelSetup: reset save failed for " .. player.Name .. ": " .. tostring(err)) end
	end
	player:SetAttribute("SquirrelsFound", 0)
	publishCounts(player)
	resetEv:FireClient(player)
	print("SquirrelSetup: " .. player.Name .. " reset their progress")
end)

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
]====],before=[====[
-- SquirrelSetup (server)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = script.Parent

local function isSquirrelMesh(p)
	return p:IsA("MeshPart") and p:FindFirstChild("Tail2", true) ~= nil and p:FindFirstChild("Root", true) ~= nil
end
local function getTex(mesh)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then return sa.ColorMap end
	return mesh.TextureID
end
local function setTex(mesh, id)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then sa.ColorMap = id else mesh.TextureID = id end
end

if folder:GetAttribute("FoundSound") == nil then folder:SetAttribute("FoundSound", "rbxassetid://1845415163") end
if folder:GetAttribute("NameTagSeconds") == nil then folder:SetAttribute("NameTagSeconds", 3.2) end
if folder:GetAttribute("MaskImage") == nil then folder:SetAttribute("MaskImage", "rbxassetid://77268792392056") end   -- white square, transparent circle
local PER_PLAYER = folder:GetAttribute("PerPlayer")
if PER_PLAYER == nil then PER_PLAYER = true; folder:SetAttribute("PerPlayer", true) end
local TARGET_HEIGHT = folder:GetAttribute("TargetHeight") or 2.9      -- studs tall; the meshes come in at 2.4
folder:SetAttribute("TargetHeight", TARGET_HEIGHT)

local ev = ReplicatedStorage:FindFirstChild("SquirrelFound") or Instance.new("RemoteEvent")
ev.Name = "SquirrelFound"; ev.Parent = ReplicatedStorage
local sync = ReplicatedStorage:FindFirstChild("SquirrelSync") or Instance.new("RemoteFunction")
sync.Name = "SquirrelSync"; sync.Parent = ReplicatedStorage

-- 1. collect every squirrel mesh in the Workspace
local meshes = {}
for _, p in ipairs(workspace:GetDescendants()) do if isSquirrelMesh(p) then table.insert(meshes, p) end end
local function modelOf(mesh) return mesh:FindFirstAncestorOfClass("Model") or mesh end
local function baseName(inst)
	local n = string.lower(modelOf(inst).Name .. " " .. inst.Name)
	n = n:gsub("_gray", ""):gsub("gray", ""):gsub("_color", ""):gsub("color", ""):gsub("%s+", " ")
	return n
end
local function isGray(inst) return string.find(string.lower(modelOf(inst).Name .. " " .. inst.Name), "gray") ~= nil end

-- 2. pair colour + gray by base name (fallback: identical mesh size)
local grays, colours = {}, {}
for _, mesh in ipairs(meshes) do
	if mesh:GetAttribute("GrayTexture") then table.insert(colours, mesh)          -- already set up (saved place)
	elseif isGray(mesh) then table.insert(grays, mesh) else table.insert(colours, mesh) end
end
for _, c in ipairs(colours) do
	if not c:GetAttribute("GrayTexture") then
		local twin
		for i, g in ipairs(grays) do
			if baseName(g) == baseName(c) then twin = g; table.remove(grays, i); break end
		end
		if not twin then
			for i, g in ipairs(grays) do
				if (g.Size - c.Size).Magnitude < 0.01 * c.Size.Magnitude then twin = g; table.remove(grays, i); break end
			end
		end
		if twin then
			c:SetAttribute("GrayTexture", getTex(twin)); c:SetAttribute("ColorTexture", getTex(c))
			modelOf(twin).Parent = nil
			print("SquirrelSetup: paired", modelOf(c):GetFullName(), "with its gray twin")
		else
			c:SetAttribute("ColorTexture", getTex(c))
			warn("SquirrelSetup: no gray twin found for " .. modelOf(c):GetFullName() .. " (import the _gray FBX too, name must contain 'gray'); it will start in colour")
		end
	end
end
for _, g in ipairs(grays) do warn("SquirrelSetup: unpaired gray squirrel " .. modelOf(g):GetFullName()) end

-- display names (shown on the floating tag when found); matched against the model name, first hit wins.
-- Set a DisplayName attribute on a squirrel model to override.
-- the registry: names, bios, maps, framing. Edit SquirrelRegistry, not this script.
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local byId = {}
for _, e in ipairs(Registry.squirrels) do byId[e.id] = e end
local THIS_MAP = folder:GetAttribute("MapId") or "forest"
folder:SetAttribute("MapId", THIS_MAP)
local function baseId(model)
	local n = model.Name:lower():gsub("_color$", ""):gsub("_gray$", "")
	return n
end
-- 3. set each one up
local squirrels = {}     -- id -> mesh
local function setup(mesh)
	local model = modelOf(mesh)
	local entry = byId[baseId(model)]
	if entry then
		model:SetAttribute("SquirrelId", entry.id)
		if not model:GetAttribute("DisplayName") then model:SetAttribute("DisplayName", entry.name) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", entry.bio or "") end
	else
		warn("SquirrelSetup: " .. model.Name .. " is not in SquirrelRegistry; add it there (id = '" .. baseId(model) .. "')")
		if not model:GetAttribute("SquirrelId") then model:SetAttribute("SquirrelId", baseId(model)) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", "A squirrel of mystery. Nobody knows where they came from, least of all them.") end
	end
	if model == mesh then     -- bare MeshPart: wrap it so ScaleTo / PivotTo work
		local wrap = Instance.new("Model"); wrap.Name = mesh.Name; wrap.Parent = mesh.Parent; mesh.Parent = wrap; model = wrap
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true; p.CanTouch = true end
	end
	model.PrimaryPart = model.PrimaryPart or mesh
	-- scale to TargetHeight, keeping the feet where they are
	local targetH = model:GetAttribute("TargetHeight") or TARGET_HEIGHT   -- a squirrel whose prop sticks up (the kite) sets its own
	if math.abs(mesh.Size.Y - targetH) > 0.02 then
		local cf0, sz0 = model:GetBoundingBox()
		local bottom = cf0.Position.Y - sz0.Y / 2
		model:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)
		local cf1, sz1 = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() + Vector3.new(cf0.Position.X - cf1.Position.X, bottom - (cf1.Position.Y - sz1.Y / 2), cf0.Position.Z - cf1.Position.Z))
	end
	local id = model:GetAttribute("SquirrelId")
	if not id or squirrels[id] then
		id = baseId(model); local k = 1
		while squirrels[id] do k += 1; id = baseId(model) .. "_" .. k end
		model:SetAttribute("SquirrelId", id)
	end
	squirrels[id] = mesh
	CollectionService:AddTag(model, "Squirrel")
	if not PER_PLAYER then
		local gray = mesh:GetAttribute("GrayTexture")
		if gray and not model:GetAttribute("Found") then setTex(mesh, gray) end
		if model:GetAttribute("Found") == nil then model:SetAttribute("Found", false) end
	end
	return model, id
end
local total = 0
for _, mesh in ipairs(colours) do setup(mesh); total += 1 end
folder:SetAttribute("Total", total)
local mapTotal = 0
for _, e in ipairs(Registry.squirrels) do if e.map == THIS_MAP then mapTotal += 1 end end
folder:SetAttribute("MapTotal", mapTotal); folder:SetAttribute("AllTotal", #Registry.squirrels)
print(string.format("SquirrelSetup: %d squirrels ready (%s)", total, PER_PLAYER and "per-player finds" or "shared finds"))

-- 4. finds, saved per player in a DataStore so they survive leaving and rejoining
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local USE_STORE = folder:GetAttribute("UseDataStore")
if USE_STORE == nil then USE_STORE = true; folder:SetAttribute("UseDataStore", true) end
local STORE_KEY = folder:GetAttribute("SaveKey") or "SquirrelFinds_v1"
folder:SetAttribute("SaveKey", STORE_KEY)
local store
if USE_STORE and PER_PLAYER then
	local ok, err = pcall(function() store = DataStoreService:GetDataStore(STORE_KEY) end)
	if not ok then warn("SquirrelSetup: DataStore unavailable, finds will not be saved: " .. tostring(err)); store = nil end
end
local found = {}          -- userId -> { [id] = true }
local loaded = {}         -- userId -> true once the DataStore load finished (or was skipped)
local canSave = {}        -- userId -> false when the load failed (never overwrite good data with an empty list)
local dirty = {}          -- userId -> true when there is something new to save
local owedItems = {}      -- userId -> {itemId = delta}; same reasoning as the purse below, per item
local owed = {}           -- userId -> acorns earned but not yet written, applied as a DELTA so that two
                          -- servers adding to the same purse cannot overwrite one another
local function foundList(player)
	local t = found[player.UserId]
	if not t then t = {}; found[player.UserId] = t end
	return t
end
local function count(t) local n = 0 for _ in pairs(t) do n += 1 end return n end
local function publishCounts(player)
	local t = foundList(player)
	local per = {}
	for _, e in ipairs(Registry.squirrels) do if t[e.id] then per[e.map] = (per[e.map] or 0) + 1 end end
	for _, m in ipairs(Registry.maps) do player:SetAttribute("Found_" .. m.id, per[m.id] or 0) end
	local ids = {}
	for id in pairs(t) do table.insert(ids, id) end
	table.sort(ids)
	player:SetAttribute("FoundIds", table.concat(ids, ","))
end
local function loadPlayer(player)
	local uid = player.UserId
	canSave[uid] = true
	if store then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
			if ok then break end
			task.wait(1.5)
		end
		if ok then
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end
			if type(data) == "table" and type(data.area) == "string" then player:SetAttribute("SavedArea", data.area) end
			if type(data) == "table" and type(data.items) == "table" then
				for id, n in pairs(data.items) do
					if type(id) == "string" and tonumber(n) then
						player:SetAttribute("Item_" .. id, tonumber(n) + ((owedItems[uid] or {})[id] or 0))
					end
				end
			end
			if type(data) == "table" and tonumber(data.acorns) then
				player:SetAttribute("Acorns", tonumber(data.acorns) + (owed[uid] or 0))
			end
			print(string.format("SquirrelSetup: loaded %d saved finds for %s", count(t), player.Name))
		else
			canSave[uid] = false
			warn("SquirrelSetup: could not load finds for " .. player.Name .. " (" .. tostring(data) .. "); this session will not be saved")
		end
	end
	loaded[uid] = true
	player:SetAttribute("SaveLoaded", true)
	if player:GetAttribute("Acorns") == nil then player:SetAttribute("Acorns", 0) end
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
	publishCounts(player)
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] then return end
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local gain = owed[uid] or 0                                   -- captured BEFORE the call: UpdateAsync can
	local movedItems = {}                                         -- likewise, a snapshot of the item deltas
	for id, d in pairs(owedItems[uid] or {}) do movedItems[id] = d end
	local ok, err = pcall(function()                              -- re-run its callback, and more can be earned
		store:UpdateAsync("u" .. uid, function(old)                -- while it is in flight
			-- merge with whatever is already saved, so two servers never erase each other's finds
			local merged = {}
			if type(old) == "table" and type(old.found) == "table" then for _, id in ipairs(old.found) do merged[id] = true end end
			for _, id in ipairs(list) do merged[id] = true end
			local out = {}
			for id in pairs(merged) do table.insert(out, id) end
			local area = player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil
			-- acorns are a purse, not a set: add what was earned to what is there rather than replacing it
			local acorns = ((type(old) == "table" and tonumber(old.acorns)) or 0) + gain
			-- the same treatment for owned things: add what changed, never replace the list
			local items = {}
			if type(old) == "table" and type(old.items) == "table" then
				for id, n in pairs(old.items) do items[id] = tonumber(n) or 0 end
			end
			for id, d in pairs(movedItems) do
				local n = (items[id] or 0) + d
				items[id] = n > 0 and n or nil                    -- a count of zero is simply not owned
			end
			return {found = out, area = area, acorns = acorns, items = items, updated = os.time()}
		end)
	end)
	if ok then
		dirty[uid] = nil
		owed[uid] = (owed[uid] or 0) - gain                        -- only what actually went in, never more
		local pend = owedItems[uid]
		if pend then
			for id, d in pairs(movedItems) do
				local left = (pend[id] or 0) - d
				pend[id] = left ~= 0 and left or nil
			end
		end
	else
		warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))
	end
end
-- The acorn server never touches the DataStore. It fires this, and the one script that owns the key writes it.
local awardEv = game:GetService("ReplicatedStorage"):FindFirstChild("AwardAcorns")
if awardEv and awardEv:IsA("BindableEvent") then
	awardEv.Event:Connect(function(player, n)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		n = tonumber(n) or 0
		if n == 0 then return end
		owed[player.UserId] = (owed[player.UserId] or 0) + n
		dirty[player.UserId] = true
	end)
end
-- Granting or taking away an item. The shop never touches the DataStore; it fires this, and the one script
-- that owns the key records it. A negative n is how something is consumed.
local itemEv = game:GetService("ReplicatedStorage"):FindFirstChild("AwardItems")
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		if type(id) ~= "string" or id == "" then return end
		n = tonumber(n) or 0
		if n == 0 then return end
		local uid = player.UserId
		owedItems[uid] = owedItems[uid] or {}
		owedItems[uid][id] = (owedItems[uid][id] or 0) + n
		local have = (player:GetAttribute("Item_" .. id) or 0) + n
		player:SetAttribute("Item_" .. id, have > 0 and have or 0)
		dirty[uid] = true
	end)
end
Players.PlayerAdded:Connect(loadPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	if dirty[player.UserId] then savePlayer(player) end
	task.delay(5, function()
		local uid = player.UserId
		found[uid] = nil; loaded[uid] = nil; canSave[uid] = nil; dirty[uid] = nil
		owed[uid] = nil; owedItems[uid] = nil
	end)
end)
-- save anything new every few seconds rather than on every single click
task.spawn(function()
	while true do
		task.wait(8)
		for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
	end
end)
game:BindToClose(function()
	if not store then return end
	for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
end)
sync.OnServerInvoke = function(player)
	local list = {}
	if PER_PLAYER then
		local waited = 0
		while not loaded[player.UserId] and waited < 15 do task.wait(0.25); waited += 0.25 end
		for id in pairs(foundList(player)) do table.insert(list, id) end
	else
		for id, mesh in pairs(squirrels) do if modelOf(mesh):GetAttribute("Found") then table.insert(list, id) end end
	end
	return list
end
local function onFound(player, model, id, mesh)
	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		publishCounts(player)
		ev:FireClient(player, id)                      -- only this player sees it turn to colour
	else
		if model:GetAttribute("Found") then return end
		model:SetAttribute("Found", true)
		setTex(mesh, mesh:GetAttribute("ColorTexture"))
		local n = 0
		for _, m2 in pairs(squirrels) do if modelOf(m2):GetAttribute("Found") then n += 1 end end
		folder:SetAttribute("FoundCount", n)
		ev:FireAllClients(id, player)                  -- everyone sees the reveal
	end
	print(string.format("SquirrelSetup: %s found %s", player.Name, id))
end
-- FindBy attribute on the folder: "click" (default), "touch", or "both"
local FIND_BY = folder:GetAttribute("FindBy")
if FIND_BY == nil then FIND_BY = "click"; folder:SetAttribute("FindBy", "click") end
local CLICK_DIST = folder:GetAttribute("ClickDistance") or 32
folder:SetAttribute("ClickDistance", CLICK_DIST)
for id, mesh in pairs(squirrels) do
	local model = modelOf(mesh)
	if FIND_BY == "click" or FIND_BY == "both" then
		for _, old in ipairs(mesh:GetChildren()) do if old:IsA("ClickDetector") then old:Destroy() end end
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = CLICK_DIST
		-- Cursor attribute on the folder: "hand" (Roblox's pointing-hand default), "arrow" (no change), or an asset id
		local cur = folder:GetAttribute("Cursor") or "hand"
		folder:SetAttribute("Cursor", cur)
		if cur == "arrow" then cd.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
		elseif cur ~= "hand" and cur ~= "" then cd.CursorIcon = cur end
		cd.Parent = mesh
		cd.MouseClick:Connect(function(player) onFound(player, model, id, mesh) end)
	end
	if FIND_BY == "touch" or FIND_BY == "both" then
		local debounce = {}
		mesh.Touched:Connect(function(hit)
			local char = hit.Parent
			local player = char and Players:GetPlayerFromCharacter(char)
			if not player then return end
			if debounce[player] and os.clock() - debounce[player] < 1 then return end
			debounce[player] = os.clock()
			onFound(player, model, id, mesh)
		end)
	end
end

-- ---- reset: wipe this player's finds on request (the "Reset progress" button asks twice before sending it) ----
local resetEv = ReplicatedStorage:FindFirstChild("SquirrelReset") or Instance.new("RemoteEvent")
resetEv.Name = "SquirrelReset"; resetEv.Parent = ReplicatedStorage
local resetAt = {}
resetEv.OnServerEvent:Connect(function(player)
	local uid = player.UserId
	if os.clock() - (resetAt[uid] or -60) < 5 then return end          -- one wipe at a time
	resetAt[uid] = os.clock()
	found[uid] = {}
	dirty[uid] = nil
	if store and canSave[uid] then
		local ok, err = pcall(function()
			-- a true wipe of the FINDS, not a merge - but the purse survives it. Resetting which squirrels you
			-- have found is not a reason to take away acorns that were earned separately.
			store:UpdateAsync("u" .. uid, function(old)
				return {found = {}, acorns = (type(old) == "table" and tonumber(old.acorns)) or 0, updated = os.time()}
			end)
		end)
		if not ok then warn("SquirrelSetup: reset save failed for " .. player.Name .. ": " .. tostring(err)) end
	end
	player:SetAttribute("SquirrelsFound", 0)
	publishCounts(player)
	resetEv:FireClient(player)
	print("SquirrelSetup: " .. player.Name .. " reset their progress")
end)

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
]====]})
table.insert(changes,{target=workspace.ToadstoolRun.RunServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local T = workspace:WaitForChild("Trampolines")
local bounced = T:WaitForChild("Bounced")
local ev = F:WaitForChild("RunEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")

local runs = {}                                      -- player -> {last = order reached, t = time of the last bounce}
local hinted = {}                                    -- player -> when they were last told where the run starts

local function total() return T:GetAttribute("VineyardHops") or 0 end
local function ends()
	if F:GetAttribute("Start") == "bottom" then return total(), 1 end
	return 1, total()
end
local function stop(player, why)
	if not runs[player] then return end
	runs[player] = nil
	player:SetAttribute("ToadRun", nil)
	if why then ev:FireClient(player, why) end
end

bounced.OnServerEvent:Connect(function(player, model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= T or model:GetAttribute("Line") ~= "vineyard" then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local at = model:GetPivot().Position
	if Vector3.new(hrp.Position.X - at.X, 0, hrp.Position.Z - at.Z).Magnitude > 2.8 * (model:GetAttribute("Scale") or 1.3) + 6 then return end
	local o, now = model:GetAttribute("Order"), os.clock()
	local s, f = ends()
	local dir = (f > s) and 1 or -1
	local r = runs[player]
	if r and now - r.t > (F:GetAttribute("MaxGap") or 2.4) then stop(player, "fell"); r = nil end   -- that long without a bounce: they came down somewhere
	if o == s then
		if r then r.t = now; if r.last ~= s then r.last = s; player:SetAttribute("ToadRun", 1) end return end
		runs[player] = {last = s, t = now}
		player:SetAttribute("ToadRun", 1)
		ev:FireClient(player, "start", total())
		return
	end
	if not r then
		if o == f and (not hinted[player] or now - hinted[player] > 20) then hinted[player] = now; ev:FireClient(player, "startshere") end
		return
	end
	r.t = now
	if (o - r.last) * dir > 0 then r.last = o; player:SetAttribute("ToadRun", math.abs(o - s) + 1) end
	if o == f then
		runs[player] = nil
		player:SetAttribute("ToadRun", nil)
		hinted[player] = now                                               -- you go on bouncing on the finish cap: no "it starts up by the chapel" over the cheering
		local n = F:GetAttribute("Reward") or 10
		awardAcorns:Fire(player, n)                                       -- SquirrelSetup's ledger saves it
		player:SetAttribute("Acorns", (tonumber(player:GetAttribute("Acorns")) or 0) + n)
		local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"toadstool",{prize=n}) end
		ev:FireClient(player, "done", n)
	end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "fell" then stop(player, "fell") end
end)
-- a run that has gone quiet ended on the ground, whether or not the player's screen said so
task.spawn(function()
	while true do
		task.wait(0.25)
		local now, gap = os.clock(), F:GetAttribute("MaxGap") or 2.4
		for player, r in pairs(runs) do if now - r.t > gap then stop(player, "fell") end end
	end
end)
Players.PlayerRemoving:Connect(function(p) runs[p] = nil; hinted[p] = nil end)
]====],before=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local T = workspace:WaitForChild("Trampolines")
local bounced = T:WaitForChild("Bounced")
local ev = F:WaitForChild("RunEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")

local runs = {}                                      -- player -> {last = order reached, t = time of the last bounce}
local hinted = {}                                    -- player -> when they were last told where the run starts

local function total() return T:GetAttribute("VineyardHops") or 0 end
local function ends()
	if F:GetAttribute("Start") == "bottom" then return total(), 1 end
	return 1, total()
end
local function stop(player, why)
	if not runs[player] then return end
	runs[player] = nil
	player:SetAttribute("ToadRun", nil)
	if why then ev:FireClient(player, why) end
end

bounced.OnServerEvent:Connect(function(player, model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= T or model:GetAttribute("Line") ~= "vineyard" then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local at = model:GetPivot().Position
	if Vector3.new(hrp.Position.X - at.X, 0, hrp.Position.Z - at.Z).Magnitude > 2.8 * (model:GetAttribute("Scale") or 1.3) + 6 then return end
	local o, now = model:GetAttribute("Order"), os.clock()
	local s, f = ends()
	local dir = (f > s) and 1 or -1
	local r = runs[player]
	if r and now - r.t > (F:GetAttribute("MaxGap") or 2.4) then stop(player, "fell"); r = nil end   -- that long without a bounce: they came down somewhere
	if o == s then
		if r then r.t = now; if r.last ~= s then r.last = s; player:SetAttribute("ToadRun", 1) end return end
		runs[player] = {last = s, t = now}
		player:SetAttribute("ToadRun", 1)
		ev:FireClient(player, "start", total())
		return
	end
	if not r then
		if o == f and (not hinted[player] or now - hinted[player] > 20) then hinted[player] = now; ev:FireClient(player, "startshere") end
		return
	end
	r.t = now
	if (o - r.last) * dir > 0 then r.last = o; player:SetAttribute("ToadRun", math.abs(o - s) + 1) end
	if o == f then
		runs[player] = nil
		player:SetAttribute("ToadRun", nil)
		hinted[player] = now                                               -- you go on bouncing on the finish cap: no "it starts up by the chapel" over the cheering
		local n = F:GetAttribute("Reward") or 10
		awardAcorns:Fire(player, n)                                       -- SquirrelSetup's ledger saves it
		player:SetAttribute("Acorns", (tonumber(player:GetAttribute("Acorns")) or 0) + n)
		ev:FireClient(player, "done", n)
	end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "fell" then stop(player, "fell") end
end)
-- a run that has gone quiet ended on the ground, whether or not the player's screen said so
task.spawn(function()
	while true do
		task.wait(0.25)
		local now, gap = os.clock(), F:GetAttribute("MaxGap") or 2.4
		for player, r in pairs(runs) do if now - r.t > gap then stop(player, "fell") end end
	end
end)
Players.PlayerRemoving:Connect(function(p) runs[p] = nil; hinted[p] = nil end)
]====]})
local sources={}
local illustrationSource=[====[-- Still HUD/store illustrations. Passport uses original uploaded artwork; no per-frame animation.
local Art={}
local C=Color3.fromRGB
local colours={brown=C(112,72,42),gold=C(219,165,58),cream=C(255,246,220),green=C(76,119,92),blue=C(93,148,163)}
function Art.draw(parent,id,size)
 local canvas=Instance.new("Frame");canvas.Name="Illustration_"..id;canvas.Size=UDim2.fromOffset(size,size);canvas.BackgroundTransparency=1;canvas.ZIndex=parent.ZIndex+1;canvas.Parent=parent
 local function shape(x,y,w,h,col,r,rot)
  local f=Instance.new("Frame");f.Position=UDim2.fromScale(x,y);f.Size=UDim2.fromScale(w,h);f.BackgroundColor3=col;f.BorderSizePixel=0;f.Rotation=rot or 0;f.ZIndex=canvas.ZIndex;f.Parent=canvas
  if r then local c=Instance.new("UICorner");c.CornerRadius=UDim.new(r,0);c.Parent=f end
  return f
 end
 local function line(x,y,w,h,col,rot) return shape(x,y,w,h,col,0.5,rot) end
 local function circle(x,y,d,col) return shape(x,y,d,d,col,1) end
 local brown,gold,cream,green,blue=colours.brown,colours.gold,colours.cream,colours.green,colours.blue
 if id~="passport" and id~="goldpassport" then circle(.08,.08,.84,C(236,224,195)) end
 if id=="passport" or id=="goldpassport" then
  -- Pine cover, warm tan pages, brown spine and a friendly gold acorn; no white outline or badge.
  if id=="goldpassport" then
   local earned=shape(.11,.04,.78,.92,C(246,193,70),.14)
   local foil=Instance.new("UIGradient");foil.Color=ColorSequence.new(C(255,229,134),C(198,135,32));foil.Rotation=25;foil.Parent=earned
  end
  local book=Instance.new("ImageLabel");book.Name="PassportCover";book.Size=UDim2.fromScale(1,1);book.BackgroundTransparency=1;book.Image="rbxassetid://134474000744911";book.ScaleType=Enum.ScaleType.Fit;book.ZIndex=canvas.ZIndex+1;book.Parent=canvas
  return canvas
 end
 if id=="acorn" then
  shape(.31,.37,.43,.45,gold,.46,-12);shape(.25,.29,.51,.19,brown,.4,-12);line(.47,.17,.075,.17,brown,12)
  line(.40,.53,.025,.15,cream,-12)
 elseif id=="book" or id=="passport" or id=="goldpassport" then
  local cover=id=="goldpassport" and gold or green
  local foil=id=="goldpassport" and brown or gold
  shape(.24,.16,.55,.70,cover,.10,-6);shape(.22,.18,.05,.65,brown,.4,-6)
  shape(.32,.25,.34,.03,foil,.3,-6);shape(.34,.70,.31,.03,foil,.3,-6)
  circle(.40,.39,.21,foil);line(.48,.33,.04,.09,foil,-12)
 elseif id=="coffee" or id=="zoomies" then
  circle(.59,.43,.24,brown);circle(.64,.48,.13,cream)
  shape(.22,.35,.44,.40,cream,.18);shape(.25,.36,.38,.08,brown,1);line(.18,.76,.56,.04,brown)
  line(.31,.13,.04,.16,gold,-14);line(.47,.10,.04,.17,gold,14)
 elseif id=="glace" then
  shape(.40,.50,.20,.35,gold,.1,10);circle(.28,.27,.32,C(227,158,164));circle(.45,.29,.30,cream);circle(.39,.15,.29,C(122,76,50))
 elseif id=="cheese" then
  shape(.20,.38,.59,.36,gold,.10,-12);shape(.25,.31,.46,.12,C(252,208,95),.25,-12)
  for _,p in ipairs({{.30,.51,.10},{.57,.44,.12},{.57,.63,.06}}) do circle(p[1],p[2],p[3],C(166,114,37)) end
 elseif id=="bubbles" then
  shape(.27,.43,.25,.37,blue,.18);shape(.31,.34,.17,.10,gold,.12)
  for _,p in ipairs({{.52,.17,.22,C(205,144,170)},{.66,.42,.16,C(129,172,148)},{.33,.15,.13,C(160,146,197)}}) do circle(p[1],p[2],p[3],p[4]);circle(p[1]+.035,p[2]+.025,p[3]*.25,cream) end
 elseif id=="hat" then
  shape(.28,.24,.44,.44,green,.2);shape(.27,.57,.47,.10,gold,.1);shape(.14,.65,.72,.12,green,1)
 elseif id=="baguette" then
  shape(.34,.14,.31,.74,gold,.5,35)
  for i=1,3 do line(.32+i*.08,.29+i*.14,.18,.04,cream,-18) end
 elseif id=="bell" then
  circle(.31,.25,.39,gold);shape(.30,.43,.41,.29,gold,.10);shape(.21,.69,.60,.08,brown,.5);circle(.45,.74,.12,gold);line(.46,.16,.06,.12,brown)
 elseif id=="glider" then
  for i=0,4 do shape(.14+i*.145,.25+math.abs(i-2)*.075,.155,.26,({C(189,87,64),gold,cream,green,blue})[i+1],.05,(i-2)*13) end
  line(.48,.40,.04,.38,brown);line(.29,.57,.44,.04,brown);line(.31,.39,.035,.20,brown,-34);line(.65,.39,.035,.20,brown,34)
 elseif id=="ziphandle" then
  line(.12,.21,.76,.04,brown,-16);circle(.40,.19,.18,gold);circle(.44,.23,.10,brown);line(.48,.36,.05,.30,brown);line(.26,.65,.49,.09,brown);shape(.20,.62,.12,.16,gold,.3);shape(.68,.62,.12,.16,gold,.3)
 elseif id=="hoop" then
  shape(.48,.15,.34,.29,cream,.08);shape(.51,.19,.27,.21,blue,.08);line(.38,.43,.40,.06,brown)
  for i=0,3 do line(.39+i*.11,.49,.025,.21,cream,(i-1.5)*-15) end
  circle(.18,.58,.26,gold);line(.20,.70,.22,.025,brown,-14)
 elseif id=="flag" then
  line(.29,.19,.05,.63,brown);shape(.35,.21,.41,.28,green,.05);shape(.39,.25,.10,.10,cream);shape(.58,.37,.10,.09,cream)
 elseif id=="seed" then
  shape(.25,.22,.51,.59,cream,.10,-6);line(.48,.41,.03,.26,green);shape(.32,.38,.19,.10,green,.5,32);shape(.49,.33,.19,.10,green,.5,-32);line(.34,.71,.28,.025,brown)
 elseif id=="binoculars" then
  shape(.20,.28,.23,.39,green,.15,10);shape(.57,.28,.23,.39,green,.15,-10);line(.40,.39,.20,.10,brown);circle(.16,.56,.30,brown);circle(.54,.56,.30,brown);circle(.21,.61,.20,blue);circle(.59,.61,.20,blue)
 elseif id=="slingshot" then
  line(.48,.47,.10,.37,brown);line(.31,.22,.09,.36,brown,-35);line(.60,.22,.09,.36,brown,35);line(.23,.22,.51,.04,gold);circle(.42,.18,.16,brown)
 elseif id=="backpack" then
  shape(.29,.18,.42,.64,brown,.28);shape(.24,.31,.52,.51,green,.22);shape(.34,.53,.32,.22,gold,.14);line(.29,.40,.42,.04,cream)
 elseif id=="portrait" then
  shape(.24,.15,.52,.64,brown,.03);shape(.29,.20,.42,.53,cream,.01);circle(.39,.28,.23,gold);shape(.36,.52,.28,.16,green,.4);line(.31,.77,.04,.12,brown,-12);line(.67,.77,.04,.12,brown,12)
 else -- A friendly squirrel profile, including a large curled tail.
  circle(.14,.25,.40,brown);circle(.23,.32,.23,gold);shape(.38,.46,.30,.32,brown,.5,-15);circle(.53,.27,.26,brown);shape(.57,.19,.10,.19,brown,.4,-14);circle(.71,.37,.035,cream);line(.40,.79,.32,.05,brown)
 end
 return canvas
end
return Art
]====];assert(loadstring(illustrationSource))
sources.Catalogue=[====[-- Released ids stay stable. A Passport records experiences, not purchases of stamps.
return {
 {id="find",name="A new friend",area="forest",icon="rescue",hint="Find a squirrel you haven't met yet.",detail="Click a squirrel or run into it to meet your new friend. Your Passport remembers who you found and where."},
 {id="riddle",name="Curious mind",area="forest",icon="book",hint="Answer the daily forest question.",detail="Visit the question board in Great Acorn Forest and choose your answer. Check tomorrow to see whether you won the grand prize."},
 {id="rescue",name="Swamp rescue",area="forest",icon="rescue",hint="Save Madame Margaux's babies from Croque Monsieur.",detail="Find the cages in the swamp and free the baby squirrels. Watch out for Croque Monsieur! You can distract him with your slingshot."},
 {id="race",name="Forest dash",area="forest",icon="flag",hint="Finish a timed race in the forest.",detail="Start at the forest race board and find every race squirrel. Click them or run into them. Your memory will show your time, personal-best improvement and leaderboard position when available. Café coffee can help!"},
 {id="hoop",name="Nothing but net",area="forest",icon="hoop",hint="Try your aim at the forest hoop.",detail="Use your slingshot near the hoop. Each shot costs 1 acorn and each basket awards 3. You get up to three shots before a rest. Your Passport records your best consecutive baskets in that round, up to three, and the acorns awarded."},
 {id="book",name="One more page",area="village",icon="book",hint="Read a free story in the bookstore.",detail="Step inside the bookstore and choose a book. All stories are free. Meet the amazing, charming and sometimes rather peculiar characters of French Squirrel Country."},
 {id="coffee",name="Café zoomies",area="village",icon="coffee",hint="Enjoy a coffee at the café.",detail="Sit at a café table and drink a coffee. It gives you extra speed for five minutes. Try using the boost in a race!"},
 {id="cheese",name="A little mischief",area="village",icon="cheese",hint="Sample some French cheese on the Rue.",detail="Enjoy some French cheese: the gift that keeps on giving. Your fellow squirrels may notice the after-effects."},
 {id="church",name="A ringing hello",area="domaine",icon="bell",hint="Ring the bell in the church.",detail="Enter the church near the château, find the bell rope and give it a pull. Let French Squirrel Country hear you!"},
 {id="glace",name="Brain freeze!",area="village",icon="glace",hint="Enjoy a glace on the Rue, brain freeze and all.",detail="Choose a cone and tap to lick it. Finish your scoops for a brain freeze. Your Passport remembers the flavours you actually enjoyed, including a mystery scoop if you get one."},
 {id="bubbles",name="A splash of color",area="village",icon="bubbles",hint="Share your style with colourful fountain bubbles.",detail="Choose a colour in the Acorn Store. Everyone on the Rue sees your fountain bubbles. If another colour is running, let it finish before choosing yours."},
 {id="hat",name="Hats off!",area="village",icon="hat",hint="Purchase a hat at the hat shop.",detail="Visit the Chapelier and choose a hat to buy. Your Passport remembers its colour and style."},
 {id="portrait",name="A moment on canvas",area="village",icon="portrait",hint="Have your portrait painted by the river.",detail="Visit the famous French Painter Squirrel by the river. A portrait costs 120 acorns and joins the gallery collection."},
 {id="baguette",name="Baguette bandit",area="village",icon="baguette",multiplayer=true,hint="Play the baguette chase and hold the baguette.",detail="Join the chase with another player. Grab the baguette and keep it as long as you can. Your Passport records how long you held it and the holding rewards you earned."},
 {id="toadstool",name="Toadstool bounce",area="domaine",icon="flag",hint="Complete the Toadstool Run for 10 acorns.",detail="Start at the top of the toadstool course and bounce to the far end without touching the ground. Finish the whole course to earn 10 acorns."},
 {id="windmill",name="Round we go",area="domaine",icon="flag",hint="Take a ride on a windmill sail.",detail="Stand on the stone pad below the windmill and grab a sail as it comes around. Enjoy the view, then let go when you're ready."},
 {id="chickens",name="Feathered friends",area="domaine",icon="acorn",hint="Feed the chickens at the farm.",detail="Find the feed bin at the farm and scatter a little food for the chickens."},
 {id="climb",name="Sandstone summit",area="domaine",icon="bell",hint="Finish the sandstone race and ring the summit bell.",detail="Start the timed Sandstone Climb, race to the top and ring the bell. Your Passport records your time and any personal-best improvement."},
 {id="zipline",name="Above the treetops",area="domaine",icon="ziphandle",hint="Ride the zipline across the map.",detail="Buy a zipline handle in the Acorn Store, then launch from a zipline platform. Hold on and enjoy the trip!"},
 {id="glider",name="A squirrel's-eye view",area="domaine",icon="glider",hint="Ride your hang glider down from the summit.",detail="Take your hang glider to the Sandstone summit and launch. Enjoy the long flight back down."},
 {id="gold",name="Golden discovery",area="gold",icon="rescue",hint="Find today's Golden Squirrel.",detail="Open Clues to see who is golden today and where to look. Click the Golden Squirrel or run into it to collect its acorn reward."},
 {id="keeper",name="Keeper of the Great Acorn",area="domaine",icon="goldpassport",bonus=true,hint="Be first to find all 44 squirrels that day.",detail="Be the first eligible player to complete all 44 squirrels in French Squirrel Country that day. Your statue stands by the fountain and your permanent honour joins the Keeper of the Great Acorn Hall of Fame beside the château."},
}
]====]
sources.Journal=[====[-- Pure, bounded data rules shared by the save owner, server and client.
local J={}
local catalogue=require(script.Parent.Catalogue)
J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end
local keys={name=true,area=true,title=true,character=true,colour=true,flavours=true,hat=true,action=true,
 cs=true,previousBest=true,improvement=true,prize=true,seconds=true,boost=true,streak=true,baskets=true,shots=true,
 rank=true,scope=true,boardReady=true,run=true,keeperNo=true,historical=true,ongoing=true,visited=true,
 ids=true,done=true,seen=true,cycle=true}
function J.clean(id,record)
 if not J.byId[id] and id~="_batch" then return nil end
 if type(record)~="table" or type(record.at)~="number" or record.at~=record.at or record.at<0 or record.at>1e12 or type(record.data)~="table" then return nil end
 local d={}
 for k,v in pairs(record.data) do
  if keys[k] then
   if type(v)=="string" then d[k]=v:sub(1,400)
   elseif type(v)=="boolean" then d[k]=v
   elseif type(v)=="number" and v==v and math.abs(v)<1e12 then d[k]=v end
  end
 end
 return {at=record.at,data=d}
end
function J.merge(a,b)
 local out={}
 for _,source in ipairs({a or {},b or {}}) do
  if type(source)=="table" then for id,record in pairs(source) do
   local v=J.clean(id,record)
   if v and (not out[id] or v.at>=out[id].at) then out[id]=v end
  end end
 end
 return out
end
function J.ids(csv)
 local list,seen={},{}
 for id in tostring(csv or ""):gmatch("[%w_]+") do if J.byId[id] and not seen[id] then list[#list+1]=id;seen[id]=true end end
 return list
end
function J.batchDone(data)
 local ids=J.ids(data and data.ids);local done={}
 for _,id in ipairs(J.ids(data and data.done)) do done[id]=true end
 if #ids==0 then return false end
 for _,id in ipairs(ids) do if not done[id] then return false end end
 return true
end
function J.nextBatch(prior,eligible,memories)
 local seen={};for _,id in ipairs(J.ids(prior and prior.seen)) do seen[id]=true end
 local cycle=prior and prior.cycle or 1
 -- Existing memories count as visited on the first pass; their stamp remains in Stamps.
 if not prior then for id in pairs(memories or {}) do if J.byId[id] then seen[id]=true end end end
 local function choose()
  local ids={}
  for _,e in ipairs(catalogue) do if eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end
  return ids
 end
 local ids=choose()
 -- Completed outings stay in Completed. An empty page waits for new areas or activities.
 for _,id in ipairs(ids) do seen[id]=true end
 local all={};for _,e in ipairs(catalogue) do if seen[e.id] then all[#all+1]=e.id end end
 return {ids=table.concat(ids,","),done="",seen=table.concat(all,","),cycle=cycle}
end
function J.time(cs)
 local seconds=math.max(0,tonumber(cs) or 0)/100
 return string.format("%d:%05.2f",math.floor(seconds/60),seconds%60)
end
function J.describe(id,record,playerName)
 local d=record and record.data or {};local e=J.byId[id]
 if not e then return "" end
 if d.historical then return "A memory from your earlier adventures. Try it again to add the details to this page." end
 if id=="rescue" then return (playerName or "You").." saves the day! You freed Madame Margaux's babies from Croque Monsieur in the swamp."
 elseif id=="race" or id=="climb" then
  if not d.cs then return "Finished the "..(id=="race" and "forest race." or "Sandstone Climb and rang the summit bell.") end
  local s=(id=="race" and "Finished the forest race in " or "Raced up Sandstone and rang the bell in ")..J.time(d.cs)..". "
  if not d.previousBest or d.previousBest<=0 then s..="Your first recorded time!"
  elseif (d.improvement or 0)>0 then s..="A new personal best — "..J.time(d.improvement).." faster!"
  else s..="Your best remains "..J.time(d.previousBest).."." end
  if (d.rank or 0)>0 then s..=" Leaderboard: #"..tostring(d.rank)..(d.scope=="global" and " worldwide." or " in this server.")
  elseif d.boardReady then s..=d.scope=="unavailable" and " Leaderboard position unavailable." or " Outside the top 10 on this leaderboard."
  else s..=" Leaderboard position is being checked." end
  if (d.prize or 0)>0 then s..=" Earned "..d.prize.." acorns." end
  return s
 elseif id=="hoop" then
  if (d.baskets or 0)==0 then return "No baskets this round. Better luck next time — practice makes perfect! 0 acorns won." end
  return string.format("Scored %d %s this round, with %d in a row! Won %d acorns in basket rewards.",d.baskets,d.baskets==1 and "basket" or "baskets",math.min(3,d.streak or 0),d.prize or 0)
 elseif id=="gold" then return "Found "..(d.name or "the Golden Squirrel").." in "..(d.area or "French Squirrel Country").." and earned "..tostring(d.prize or 0).." acorns."
 elseif id=="find" then return "Found "..(d.name or "a new squirrel")..(d.area and " in "..d.area or "").."!"
 elseif id=="book" then return "Read about "..(d.character or "the wonderful squirrels of French Squirrel Country")..(d.title and " in “"..d.title.."”." or ".")
 elseif id=="coffee" then return string.format("Enjoyed a coffee and increased speed by %d%% for %s minutes. Maybe use that in the race?",d.boost or 35,tostring((d.seconds or 300)/60))
 elseif id=="cheese" then return "Enjoyed some French cheese — the gift that keeps on giving."
 elseif id=="bubbles" then return "Shared your sense of style on the Rue with "..(d.colour or "colourful").." bubbles."
 elseif id=="glace" then return "Enjoyed a "..(d.flavours or "delicious").." glace on the Rue, brain freeze and all."
 elseif id=="hat" then return (d.action=="wear" and "Wore your " or "Purchased a ")..(d.hat or "lovely hat")..(d.action=="wear" and "." or " at the hat shop.")
 elseif id=="portrait" then return "Added your portrait to the collection by the famous French Painter Squirrel."
 elseif id=="baguette" then
  local seconds=math.floor(d.seconds or 0);local t=seconds>=60 and string.format("%d min %d sec",math.floor(seconds/60),seconds%60) or tostring(seconds).." seconds"
  return "Played the baguette chase and held the baguette for "..t..". Earned "..tostring(d.prize or 0).." holding acorns."..(d.ongoing and " Still holding it!" or "")
 elseif id=="riddle" then return "Answered the daily forest question. Be sure to check tomorrow to see if you won the grand prize!"
 elseif id=="church" then return "Rang the church bell and let your hello ring out across French Squirrel Country."
 elseif id=="toadstool" then return "Bounced all the way through the Toadstool Run and earned "..tostring(d.prize or 10).." acorns!"
 elseif id=="windmill" then return "Rode a windmill sail and watched French Squirrel Country go round."
 elseif id=="chickens" then return "Fed the chickens at the farm. A very popular visitor!"
 elseif id=="zipline" then return "Rode the zipline across French Squirrel Country."
 elseif id=="glider" then return "Rode your hang glider down from the Sandstone summit."
 elseif id=="keeper" then return "First to complete all 44 squirrels that day! Your statue joined the Keeper of the Great Acorn Hall of Fame."..((d.keeperNo or 0)>0 and " Keeper #"..d.keeperNo.."." or "") end
 return e.hint
end
return J
]====]
sources.PassportClient=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local H=game:GetService("HttpService")
local TextService=game:GetService("TextService")
local p=Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))
local Art=require(F:WaitForChild("PassportVisuals"))
local toggle=RS:WaitForChild("PassportToggle")
local C=Color3.fromRGB
local PAPER,INK,MUTED,GOLD,PINE=C(255,246,220),C(84,40,10),C(40,24,10),C(240,196,110),C(27,66,43)
local accents={C(79,106,83),C(176,102,66),C(186,137,48),C(120,86,60),C(143,107,66)}
local gui=Instance.new("ScreenGui");gui.Name="PassportGui";gui.ResetOnSpawn=false;gui.DisplayOrder=8;gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=pg
local function round(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function stroke(o,col,w,tr)local s=Instance.new("UIStroke");s.Color=col;s.Thickness=w;s.Transparency=tr or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function gradient(o,a,b,rot)local g=Instance.new("UIGradient");g.Color=ColorSequence.new(a,b);g.Rotation=rot or 90;g.Parent=o;return g end
local function text(parent,txt,x,y,w,h,size,col,font)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h);l.Text=txt;l.TextSize=size;l.Font=font or Enum.Font.FredokaOne;l.TextColor3=col or INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextWrapped=true;l.ZIndex=parent.ZIndex+1;l.Parent=parent;return l
end
local function gildedHeading(label,dark)
 -- Keep glyphs crisp at phone sizes; gold glow belongs on the surrounding frames.
 label.TextStrokeTransparency=1
 if dark then label.TextColor3=C(255,225,128) end
end
local function button(parent,name,txt,x,y,w,h)
 local b=Instance.new("TextButton");b.Name=name;b.Text=txt;b.Font=Enum.Font.FredokaOne;b.TextSize=14;b.TextColor3=INK;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.BorderSizePixel=0;b.BackgroundColor3=PAPER;b.ZIndex=parent.ZIndex+1;b.Parent=parent;round(b,11);return b
end
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-14,0,68);panel.BackgroundColor3=C(255,255,255);panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,18)
panel.BackgroundColor3=PAPER
-- Match the existing Baguette Chase: cream, brown type, one travelling gold rim.
local edge=stroke(panel,C(255,255,255),4)
local ring=Instance.new("UIGradient");ring.Name="Ring"
ring.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(196,136,36)),ColorSequenceKeypoint.new(.55,C(228,170,58)),ColorSequenceKeypoint.new(.85,C(255,222,120)),ColorSequenceKeypoint.new(1,C(255,250,215))});ring.Parent=edge
RunService.RenderStepped:Connect(function(dt)if panel.Visible then ring.Rotation=(ring.Rotation+dt*120)%360 end end)
local header=Instance.new("Frame");header.Name="Cover";header.Position=UDim2.fromOffset(5,5);header.Size=UDim2.new(1,-10,0,47);header.BackgroundTransparency=1;header.BorderSizePixel=0;header.ZIndex=2;header.Parent=panel
local heading=text(header,"Official Passport",49,3,230,24,21,PAPER);heading.TextWrapped=false;heading.TextTruncate=Enum.TextTruncate.AtEnd
gildedHeading(heading,false);heading.TextColor3=INK;heading.TextXAlignment=Enum.TextXAlignment.Center
local summary=text(header,"French Squirrel Country",50,26,250,15,11,C(110,70,30),Enum.Font.GothamMedium);summary.TextXAlignment=Enum.TextXAlignment.Center;summary.TextWrapped=false;summary.TextTruncate=Enum.TextTruncate.AtEnd
local close=button(header,"Close","×",0,3,40,40);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-3,0,3);close.TextColor3=INK;close.BackgroundColor3=C(236,226,206);close.BackgroundTransparency=0;close.TextSize=25
local back=button(header,"Back","‹",3,3,40,40);back.TextColor3=INK;back.BackgroundColor3=C(236,226,206);back.BackgroundTransparency=0;back.TextSize=27;back.Visible=false
local tabs={};local selected="Outings";local detail=nil;local returnScroll=Vector2.zero
for _,name in ipairs({"Outings","Completed","Clues"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(14,93);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.ZIndex=3;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,9);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local rows={};local journal={};local render,fit
local function refreshData()
 local ok,v=pcall(function()return H:JSONDecode(p:GetAttribute("PassportJournal") or "{}")end)
 journal=ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function item(id)return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function isPending(id)
 local b=journal._batch and journal._batch.data or {}
 return table.find(J.ids(b.ids),id) and not table.find(J.ids(b.done),id)
end
local function stamp(parent,record,accent)
 local seal=Instance.new("Frame");seal.Name="PassportStamp";seal.Size=UDim2.fromOffset(63,35);seal.Position=UDim2.new(0,9,1,-44);seal.BackgroundTransparency=1;seal.Rotation=-11;seal.ZIndex=5;seal.Parent=parent;round(seal,17);stroke(seal,accent,1.5,.48)
 local inner=Instance.new("Frame");inner.Size=UDim2.new(1,-5,1,-5);inner.Position=UDim2.fromOffset(2.5,2.5);inner.BackgroundTransparency=1;inner.Parent=seal;round(inner,15);stroke(inner,accent,1,.7)
 local a=text(seal,"COMPLETED",0,4,63,13,8,accent,Enum.Font.GothamBold);a.TextXAlignment=Enum.TextXAlignment.Center;a.TextTransparency=.2
 local visited=record.data.visited or record.at
 local date=visited>1000000 and os.date("!%d %b %Y",math.floor(visited)) or "SOUVENIR"
 local b=text(seal,date,0,18,63,10,7,accent,Enum.Font.GothamBold);b.TextXAlignment=Enum.TextXAlignment.Center;b.TextTransparency=.3
end
local function artTile(parent,id,size,accent,record)
 local tile=Instance.new("Frame");tile.Name="PortraitTile";tile.Size=UDim2.fromOffset(size,size);tile.Position=UDim2.fromOffset(10,10);tile.BackgroundColor3=C(255,255,255);tile.BorderSizePixel=0;tile.ZIndex=4;tile.ClipsDescendants=true;tile.Parent=parent;round(tile,12)
 gradient(tile,accent:Lerp(C(255,255,255),.78),accent:Lerp(PAPER,.5),45);stroke(tile,accent,1,.4)
 local art=Art.draw(tile,id,size,record);art.Position=UDim2.fromOffset(0,0)
 return tile
end
local function addRow(id,title,body,record,onTap,expanded,footer)
 local width=math.max(180,scroll.AbsoluteSize.X-5)
 local accent=accents[(#rows%#accents)+1]
 local mobile=UIS.TouchEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<500)
 local tx=expanded and 16 or 81;local y=expanded and (mobile and 82 or 98) or 34;local fontSize=expanded and (mobile and 13 or 14) or 13
 local bodyWidth=width-tx-(expanded and 16 or 13);local bh=TextService:GetTextSize(body,fontSize,Enum.Font.BuilderSans,Vector2.new(bodyWidth,10000)).Y+5
 local bodyHeight=(record or expanded) and bh or math.min(34,bh)
 local height=math.max(record and 113 or expanded and (mobile and 137 or 165) or 102,y+bodyHeight+(expanded and 16 or record and 12 or 30))
 local r=Instance.new(onTap and "TextButton" or "Frame");r.Name="Entry_"..id;r.Size=UDim2.new(1,-5,0,height);r.LayoutOrder=#rows+1;r.BackgroundColor3=C(255,255,255);r.BorderSizePixel=0;r.ZIndex=3;r.Parent=scroll;round(r,13)
 if r:IsA("TextButton")then r.Text="";r.AutoButtonColor=true end
 r.BackgroundColor3=C(255,250,234);stroke(r,C(220,170,59),1,expanded and .2 or .35)
 if expanded then
  local rim=Instance.new("Frame");rim.Name="DescriptionGoldGlow";rim.BackgroundTransparency=1;rim.Position=UDim2.fromOffset(2,2);rim.Size=UDim2.new(1,-4,1,-4);rim.ZIndex=3;rim.Parent=r;round(rim,11)
  stroke(rim,C(255,205,79),expanded and 5 or 4,expanded and .83 or .91)
  local foil=Instance.new("Frame");foil.Name="DescriptionGoldEdge";foil.BackgroundTransparency=1;foil.Position=UDim2.fromOffset(1,1);foil.Size=UDim2.new(1,-2,1,-2);foil.ZIndex=3;foil.Parent=r;round(foil,12)
  gradient(stroke(foil,GOLD,1,expanded and .24 or .5),C(255,226,138),C(205,144,36),35)
 end
 local tile=artTile(r,id,expanded and (mobile and 60 or 76) or 60,accent,record)
 if expanded then tile.Position=UDim2.fromOffset(14,12)end
 local titleX=expanded and (mobile and 88 or 106) or tx
 local titleLabel=text(r,title,titleX,expanded and 13 or 9,width-titleX-(onTap and 29 or 16),expanded and (mobile and 56 or 66) or 23,expanded and (mobile and 18 or 20) or 16)
 gildedHeading(titleLabel,false)
 if not expanded then titleLabel.TextWrapped=false;titleLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 local bodyLabel=text(r,body,tx,y,bodyWidth,bodyHeight,fontSize,MUTED,Enum.Font.BuilderSans);bodyLabel.Name="Description";bodyLabel.TextYAlignment=Enum.TextYAlignment.Top
 if expanded then bodyLabel.TextXAlignment=Enum.TextXAlignment.Center end
 if not record and not expanded then bodyLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 if record then stamp(r,record,accent)
 elseif not expanded then
  local foot=text(r,footer or (onTap and "Tap for details" or ""),tx,height-25,width-tx-12,18,10,accent,Enum.Font.GothamBold);foot.TextWrapped=false;foot.TextTruncate=Enum.TextTruncate.AtEnd
 end
 if onTap then local arrow=text(r,"›",width-30,8,20,26,24,accent);arrow.TextXAlignment=Enum.TextXAlignment.Center;r.Activated:Connect(onTap)end
 rows[#rows+1]=r;return r
end
local function openDetail(id)
 if selected=="Completed" or (journal[id] and not isPending(id)) then return end
 returnScroll=scroll.CanvasPosition;detail=id;scroll.CanvasPosition=Vector2.zero;fit();render()
end
local moreBusy=false
render=function()
 if not panel.Visible then return end
 refreshData();local previous=scroll.CanvasPosition
 -- A newly finished outing closes its description and moves to Completed.
 if detail and journal[detail] and not isPending(detail) then detail=nil;fit()end
 for _,r in ipairs(rows)do r:Destroy()end;table.clear(rows)
 local total=0;for _,e in ipairs(catalogue)do if journal[e.id]then total+=1 end end
 local outings=item("passport_outings")
 heading.Text=detail and "How to do it" or "Official Passport";heading.TextSize=detail and 19 or 21
 summary.Text=detail and J.byId[detail].name or "French Squirrel Country"
 for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail end
 back.Visible=detail~=nil
 if detail then
  local e=J.byId[detail];addRow(e.id,e.name,e.detail,nil,nil,true,"Complete this outing to earn its stamp")
 elseif not p:GetAttribute("PassportReady")then
  addRow("find","Opening your Passport","Loading your progress...")
 elseif selected=="Outings" then
  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)
  summary.Text=string.format("%d of %d completed · %d left to explore",#done,#ids,#ids-#done)
  if #ids==0 then
   summary.Text=total>=21 and "21 adventures completed" or "More adventures to unlock"
   local need=workspace.Boundary:GetAttribute("Need") or 10
   local hint=(p:GetAttribute("Found_forest") or 0)<need and ("Find "..need.." forest squirrels to unlock the Rue and its outings.") or (p:GetAttribute("Found_village") or 0)<need and ("Find "..need.." squirrels on the Rue to unlock the château and its outings.") or "Bring a friend into this server to play the baguette chase. Check Clues for today's Golden Squirrel."
   addRow("keeper",total>=21 and "All outings completed!" or "Keep exploring",total>=21 and "Beat your best race time, take on the daily question, or check Clues for today's Golden Squirrel." or hint,nil,nil,true,"Your results are saved in Completed")
  end
  for _,id in ipairs(ids)do if not table.find(done,id)then local e=J.byId[id];addRow(e.id,e.name,e.hint,nil,function()openDetail(id)end)end end
  if J.batchDone(batch)then
   summary.Text=total>=21 and "21 adventures completed" or string.format("%d of %d outings completed",#done,#ids)
   local card=Instance.new("Frame");card.Name="BatchComplete";card.BackgroundColor3=C(255,255,255);card.BorderSizePixel=0;card.Size=UDim2.new(1,-5,0,104);card.LayoutOrder=1;card.ZIndex=3;card.Parent=scroll;round(card,13);gradient(card,C(255,251,218),C(246,225,157));stroke(card,GOLD,1,.3);rows[#rows+1]=card
   text(card,"Well done, Squirrel Adventurer!",13,7,scroll.AbsoluteSize.X-31,25,17,INK)
   text(card,total>=21 and "Check Clues for daily finds and bonus challenges." or "Ready to explore more of Squirrel Country?",13,32,scroll.AbsoluteSize.X-31,18,11,MUTED,Enum.Font.Gotham)
   local b=button(card,"CompleteMore",moreBusy and "Opening..." or total>=21 and "Open Clues  ›" or "Explore more  ›",12,55,280,40);b.Size=UDim2.new(1,-24,0,40);b.BackgroundColor3=C(255,255,255);gradient(b,C(255,223,104),C(234,172,37));stroke(b,C(167,110,25),1,.4)
   b.Activated:Connect(function()
    if total>=21 then selected="Clues";scroll.CanvasPosition=Vector2.zero;render();return end
    if moreBusy then return end;moreBusy=true;b.Text="Opening..."
    local ok,accepted,message=pcall(function()return F.PassportAction:InvokeServer("more")end);moreBusy=false
    if ok and accepted then scroll.CanvasPosition=Vector2.zero;render()else b.Text=message or "Try again in a moment" end
   end)
  end
 elseif selected=="Completed"then
  summary.Text=string.format("%d %s completed",total,total==1 and "adventure" or "adventures")
  if total==0 then addRow("find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end
  local entries={};for _,e in ipairs(catalogue)do if journal[e.id]then entries[#entries+1]=e end end
  table.sort(entries,function(a,b)return(journal[a.id].data.visited or journal[a.id].at)>(journal[b.id].data.visited or journal[b.id].at)end)
  for _,e in ipairs(entries)do addRow(e.id,e.name,J.describe(e.id,journal[e.id],p.DisplayName),journal[e.id])end
 else
  summary.Text="Daily finds & bonus challenges"
  local daily=workspace:FindFirstChild("Daily");local goldName=daily and daily:GetAttribute("GoldName")or"";local goldArea=daily and daily:GetAttribute("GoldArea")or""
  addRow("gold","Today's Golden Squirrel",goldName~="" and(goldName.." is hiding in "..goldArea..".")or"Today's clue is getting ready.",nil,not journal.gold and function()openDetail("gold")end or nil,false,"A fresh Golden Squirrel each day")
  local e=J.byId.keeper
  addRow("keeper",e.name,journal.keeper and "Your honour is recorded in Completed. Visit your statue at the Hall of Fame!" or e.hint,nil,not journal.keeper and function()openDetail("keeper")end or nil,false,"BONUS · never holds up your outings")
  addRow("gold","Your golden cover","Enjoy three different activities in a day. Five such days earn a golden cover. Missing a day never takes progress away.\n\nProgress: "..math.min(outings,5).." / 5 days.",nil,nil,true)
 end
 scroll.CanvasPosition=previous
end
fit=function()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 local width=math.min(mobile and 350 or 412,vp.X-28)
 local height=math.min(560,math.max(140,vp.Y-68-(mobile and 92 or 24)))
 panel.Size=UDim2.fromOffset(width,height)
 local top=detail and 60 or 93
 scroll.Position=UDim2.fromOffset(14,top);scroll.Size=UDim2.fromOffset(width-25,height-top-10)
 local hx=49
 heading.Position=UDim2.fromOffset(hx,3);summary.Position=UDim2.fromOffset(hx,26)
 heading.Size=UDim2.fromOffset(width-hx-62,24);summary.Size=UDim2.fromOffset(width-hx-62,15)
 local tw=(width-36)/3
 for i,name in ipairs({"Outings","Completed","Clues"})do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end
end
back.Activated:Connect(function()detail=nil;fit();render();scroll.CanvasPosition=returnScroll end)

local suppressed={};local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel");local quiet=active=="passport" or active=="shop" or active=="book"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then if suppressed[g]==nil then suppressed[g]=g.Enabled end;g.Enabled=false end end
 else for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end;table.clear(suppressed) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)
local openedAt=0
local function closePage()panel.Visible=false;if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end end
local function openPage()
 pg:SetAttribute("OpenPanel","passport");panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function()if panel.Visible then closePage() else openPage() end end);close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  g:GetPropertyChangedSignal("Enabled"):Connect(function()if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren())do watchGui(g)end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings") and not pending then pending=true;task.defer(function()pending=false;render()end)end
end)
local cameraConnection
local function cameraChanged()
 if cameraConnection then cameraConnection:Disconnect() end;fit()
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()fit();render()end)end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
UIS.InputBegan:Connect(function(input,processed)if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB)then closePage()end end)
RunService.Heartbeat:Connect(function()
 if not panel.Visible then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not char or p:GetAttribute("Racing") or p:GetAttribute("Climbing") or p:GetAttribute("InChase") or char:GetAttribute("Riding") or char:GetAttribute("Gliding") or char:GetAttribute("MillRiding") then closePage();return end
 if hum and hum.MoveDirection.Magnitude>0.1 and os.clock()-openedAt>0.35 then closePage()end
end)
task.spawn(function()while gui.Parent do task.wait(30);if panel.Visible and selected=="Clues" then render()end end end)
print("Passport: outings and completed stamps ready")
]====]
sources.PassportServer=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local H=game:GetService("HttpService")
local F=script.Parent
local catalogue=require(F.Catalogue)
local J=require(F.Journal)
local Rules=require(F.Rules)
local award=RS:WaitForChild("AwardItems")
local activity=RS:WaitForChild("PassportActivity")
local save=RS:WaitForChild("PassportSave") -- server-only records; SquirrelSetup owns the single save key
local action=F:WaitForChild("PassportAction")
local states,queued,lastRequest={},{},{}
local allowed={};for _,e in ipairs(catalogue) do allowed[e.id]=true end
local function item(p,id) return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function today()
 local daily=workspace:FindFirstChild("Daily")
 return math.floor((os.time()-(daily and daily:GetAttribute("DayOffsetHours") or 9)*3600)/86400)
end
local function decode(s)
 local ok,v=pcall(function() return H:JSONDecode(s or "{}") end)
 return ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function write(p,id,data,at)
 local state=states[p];if not state then return end
 local old=state.journal[id]
 local record=J.clean(id,{at=at or math.max(workspace:GetServerTimeNow(),old and old.at+0.0001 or 0),data=data})
 if not record then return end
 state.journal[id]=record
 p:SetAttribute("PassportJournal",H:JSONEncode(state.journal))
 save:Fire(p,id,record)
end
local function eligible(p,e)
 if e.bonus then return false end
 local need=workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need") or 10
 if e.area=="village" and (p:GetAttribute("Found_forest") or 0)<need then return false end
 if e.area=="domaine" and (p:GetAttribute("Found_village") or 0)<need then return false end
 if e.multiplayer and #Players:GetPlayers()<(workspace.Baguette:GetAttribute("MinPlayers") or 2) then return false end
 if e.area=="gold" then
  local area=workspace.Daily:GetAttribute("GoldArea") or ""
  if area:find("Rue") and (p:GetAttribute("Found_forest") or 0)<need then return false end
  if (area:find("Château") or area:find("Chateau")) and (p:GetAttribute("Found_village") or 0)<need then return false end
 end
 return true
end
local function advance(p)
 local s=states[p];if not s then return false,"Your Passport is still loading." end
 local b=s.journal._batch
 if b and #J.ids(b.data.ids)>0 and not J.batchDone(b.data) then return false,"Stamp these outings before opening the next page." end
 write(p,"_batch",J.nextBatch(b and b.data,function(e) return eligible(p,e) end,s.journal))
 return true
end
local function fillEmpty(p)
 local s=states[p];local b=s and s.journal._batch
 if not b or #J.ids(b.data.ids)>0 then return end
 local nextPage=J.nextBatch(b.data,function(e)return eligible(p,e)end,s.journal)
 if #J.ids(nextPage.ids)>0 then write(p,"_batch",nextPage)end
end
local function mark(p,id,data)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players or not allowed[id] then return end
 local s=states[p]
 if not s then queued[p]=queued[p] or {};queued[p][id]=data or {};return end
 data=type(data)=="table" and table.clone(data) or {}
 data.visited=workspace:GetServerTimeNow()
 -- The stamp ledger stays compatible with the first Passport release.
 local changes=Rules.record(s,id,today(),allowed)
 if changes then for _,pair in ipairs(changes) do award:Fire(p,pair[1],pair[2]) end end
 write(p,id,data)
 local batch=s.journal._batch
 if batch then
  local b=table.clone(batch.data);local ids=J.ids(b.ids);local done=J.ids(b.done);local seen=J.ids(b.seen);local changed=false
  if table.find(ids,id) and not table.find(done,id) then done[#done+1]=id;b.done=table.concat(done,",");changed=true end
  if not table.find(seen,id) then seen[#seen+1]=id;b.seen=table.concat(seen,",");changed=true end
  if changed then write(p,"_batch",b) end
 end
end
activity.Event:Connect(mark)
-- These ledger awards are the actual successful action, not loading saved attributes.
award.Event:Connect(function(p,id,n)
 if type(n)~="number" or n<=0 then return end
 if id=="gassy" then mark(p,"cheese")
 elseif id=="q_round_forest" then mark(p,"riddle") end
end)
local function watchCharacter(p,char)
 for attribute,id in pairs({Riding="zipline",Gliding="glider"}) do
  char:GetAttributeChangedSignal(attribute):Connect(function() if char:GetAttribute(attribute)==true then mark(p,id) end end)
 end
end
local function watchBoard(p,id)
 p:GetAttributeChangedSignal("PassportBoard_"..id):Connect(function()
  local s=states[p];local old=s and s.journal[id]
  if not old or not old.data.cs then return end
  local ok,b=pcall(function() return H:JSONDecode(p:GetAttribute("PassportBoard_"..id)) end)
  if not ok or type(b)~="table" then return end
  local d=table.clone(old.data);d.rank=b.rank or 0;d.scope=b.scope;d.boardReady=true
  d.visited=d.visited or old.at
  write(p,id,d) -- result detail update, not another completed outing
 end)
end
local function rememberKeeper(p)
 local s=states[p]
 if s and (p:GetAttribute("ChampionNo") or 0)>0 and not s.journal.keeper then write(p,"keeper",{keeperNo=p:GetAttribute("ChampionNo")},1);s.stamps.keeper=1;award:Fire(p,"passport_keeper",1)end
end
local function watch(p)
 p:SetAttribute("PassportReady",false)
 p.CharacterAdded:Connect(function(char) watchCharacter(p,char) end)
 if p.Character then watchCharacter(p,p.Character) end
 watchBoard(p,"race");watchBoard(p,"climb")
 p:GetAttributeChangedSignal("ChampionNo"):Connect(function()rememberKeeper(p)end)
 p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" then task.defer(fillEmpty,p)end end)
 task.spawn(function()
  while p.Parent==Players and not p:GetAttribute("SaveLoaded") do task.wait(0.1) end
  if p.Parent~=Players then return end
  task.wait()
  if p.Parent~=Players then return end
  local s={stamps={},last=item(p,"passport_outing_last"),outings=item(p,"passport_outings"),journal=decode(p:GetAttribute("PassportJournal"))}
  for id in pairs(allowed) do s.stamps[id]=item(p,"passport_"..id) end
  states[p]=s
  for id,day in pairs(s.stamps) do if day>0 and not s.journal[id] then write(p,id,{historical=true},1) end end
  -- A known Keeper's honour remains visible even if it predates the Passport.
  rememberKeeper(p)
  if not s.journal._batch then advance(p) end
  fillEmpty(p)
  local waiting=queued[p];queued[p]=nil
  if waiting then for id,data in pairs(waiting) do mark(p,id,data) end end
  p:SetAttribute("PassportReady",true)
  for other in pairs(states)do fillEmpty(other)end
 end)
end
action.OnServerInvoke=function(p,what)
 if what~="more" then return false,"Unknown Passport action." end
 local now=os.clock();if now-(lastRequest[p] or -10)<1 then return false,"One page at a time." end;lastRequest[p]=now
 return advance(p)
end
Players.PlayerAdded:Connect(watch)
for _,p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) states[p]=nil;queued[p]=nil;lastRequest[p]=nil end)
print("Passport: 22 personal memories, five-outing pages, saved details")
]====]
sources.PassportVisuals=[====[-- Real game artwork, softly lit. No live scripts, physics or per-frame rendering work.
local V={}
local RS=game:GetService("ReplicatedStorage")
local C=Color3.fromRGB
local art=RS:WaitForChild("PassportArt")
local map={find="detective_squirrel",riddle="squirrel_scientist",rescue="super_squirrel",race="cyclist_squirrel",hoop="super_squirrel",book="spy_squirrel",coffee="coffee",cheese="chevre_squirrel",church="church_mouse",glace="glace",bubbles="florist_squirrel",hat="hat",portrait="painter_squirrel",baguette="baguette",toadstool="toadstool",windmill="windmill",chickens="farmer_fernand",climb="ranger_squirrel",zipline="parachute_squirrel",glider="parachute_squirrel",gold="fairy_squirrel",keeper="tourist_squirrel"}
function V.draw(parent,id,size,record)
 local source=art:FindFirstChild(map[id] or id) or art:FindFirstChild("detective_squirrel")
 if (id=="find" or id=="gold") and record and record.data.name then
  for _,o in ipairs(art:GetChildren())do if o:GetAttribute("CharacterName")==record.data.name then source=o;break end end
 end
 local holder=Instance.new("Frame");holder.Name="GameArtwork";holder.Size=UDim2.fromOffset(size,size);holder.BackgroundTransparency=1;holder.ZIndex=parent.ZIndex+1;holder.Parent=parent
 local vp=Instance.new("ViewportFrame");vp.Name="OriginalGameArt";vp.Size=UDim2.fromScale(1,1);vp.BackgroundTransparency=1;vp.Ambient=C(200,203,218);vp.LightColor=C(255,246,221);vp.LightDirection=Vector3.new(-.4,-1,-.6);vp.ZIndex=holder.ZIndex;vp.Parent=holder
 local copy=source:Clone();local world=Instance.new("WorldModel");world.Parent=vp;copy.Parent=world
 if id=="coffee" then
  -- A directional key light and warm shadow preserve the cup's curved shape.
  vp.Ambient=C(104,95,78);vp.LightColor=C(255,239,211);vp.LightDirection=Vector3.new(-.7,-.8,-.4)
  local cup=copy:FindFirstChild("Cup",true);local brew=copy:FindFirstChild("Brew",true);local saucer=copy:FindFirstChild("Saucer",true)
  if cup then cup.Color=C(241,229,202);cup.Material=Enum.Material.SmoothPlastic;cup.Reflectance=.08 end
  if saucer then saucer.Color=C(212,187,145);saucer.Material=Enum.Material.SmoothPlastic end
  if cup and brew then
   -- In the world model the dark surface sits inside the solid cylinder. Lift it only in this UI copy.
   brew.Position=Vector3.new(cup.Position.X,cup.Position.Y+cup.Size.X/2+.012,cup.Position.Z);brew.Color=C(75,39,20)
  end
 end
 local cam=Instance.new("Camera");cam.FieldOfView=30;cam.Parent=vp;vp.CurrentCamera=cam
 local cf,sz=copy:GetBoundingBox();local centre=cf.Position
 if source:GetAttribute("Portrait") then
  local mesh=copy:FindFirstChildWhichIsA("MeshPart",true);local h=mesh.Size.Y;local fwd=source:GetAttribute("Front");local left=Vector3.yAxis:Cross(fwd)
  centre=mesh.Position+Vector3.new(0,(.15+(source:GetAttribute("up") or 0))*h,0)+fwd*(.3*h)
  local head=mesh:FindFirstChild("Head",true);if head then centre+=left*(head.WorldPosition-centre):Dot(left)end
  centre+=left*((source:GetAttribute("side") or 0)*h)
  cam.FieldOfView=24;cam.CFrame=CFrame.lookAt(centre+fwd*((source:GetAttribute("dist") or 1.35)*1.18*h)+Vector3.new(0,(source:GetAttribute("camUp") or .05)*h,0),centre)
 else
  local radius=sz.Magnitude*.52;local dist=radius/math.sin(math.rad(cam.FieldOfView/2))*1.02
  cam.CFrame=CFrame.lookAt(centre+(id=="coffee" and Vector3.new(.35,.85,1) or Vector3.new(.65,.35,1)).Unit*dist,centre)
 end
 return holder
end
return V
]====]
local function normalized(s) return (s:gsub("^%s+","")) end
for _,c in ipairs(changes) do local f,e=loadstring(c.source);assert(f,c.target:GetFullName()..": "..tostring(e));assert(normalized(c.target.Source)==normalized(c.before) or normalized(c.target.Source)==normalized(c.source),"Source changed since backup: "..c.target:GetFullName()) end
for n,s in pairs(sources) do local f,e=loadstring(s);assert(f,n..": "..tostring(e)) end
local history=game:GetService("ChangeHistoryService");history:SetWaypoint("Before Passport memories")
local F=workspace.Passport;local RS=game:GetService("ReplicatedStorage")
local save=RS:FindFirstChild("PassportSave") or Instance.new("BindableEvent");assert(save:IsA("BindableEvent"));save.Name="PassportSave";save.Parent=RS
local action=F:FindFirstChild("PassportAction") or Instance.new("RemoteFunction");assert(action:IsA("RemoteFunction"));action.Name="PassportAction";action.Parent=F
for n,s in pairs(sources) do local o=F:FindFirstChild(n) or Instance.new((n=="PassportServer" or n=="PassportClient") and "Script" or "ModuleScript");o.Name=n;o.Source=s;if n=="PassportClient" then o.RunContext=Enum.RunContext.Client end;o.Parent=F end
for _,c in ipairs(changes) do c.target.Source=c.source end
RS.SquirrelIllustrations.Source=illustrationSource
workspace.SquirrelScripts:SetAttribute("FindBy","both");workspace.AcornSystem:SetAttribute("FindBy","both");F:SetAttribute("Version","2.1.0")
-- Preserve the game's actual meshes and textures in small, inert UI previews.
do
 local RS=game:GetService("ReplicatedStorage")
 local old=RS:FindFirstChild("PassportArt")
 local art=Instance.new("Folder");art.Name="PassportArt"
 local registry=require(workspace.SquirrelScripts.SquirrelRegistry)
 local lookup={};for _,e in ipairs(registry.squirrels) do lookup[e.id]=e end
 local function preview(id,source,face)
  if not source then return end
  local model=Instance.new("Model");model.Name=id
  local copy=source:Clone();copy.Parent=model
  for _,d in ipairs(model:GetDescendants()) do
   for _,tag in ipairs(game:GetService("CollectionService"):GetTags(d))do game:GetService("CollectionService"):RemoveTag(d,tag)end
   if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Constraint") or d:IsA("JointInstance") or d:IsA("LayerCollector") or d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("Highlight") then d:Destroy()
   elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false end
  end
  if not model:FindFirstChildWhichIsA("BasePart",true) then model:Destroy();return end
  if source:IsA("MeshPart") and face then
   local head=copy:FindFirstChild("Head",true);local root=copy:FindFirstChild("Root",true)
   local fwd=source.CFrame.LookVector
   if head and root then local f=head.WorldPosition-root.WorldPosition;f=Vector3.new(f.X,0,f.Z);if f.Magnitude>.05 then fwd=f.Unit end end
   model:SetAttribute("Front",fwd);model:SetAttribute("Portrait",true)
   for k,v in pairs(face)do model:SetAttribute(k,v)end
   local colour=source:GetAttribute("ColorTexture")
   if colour then local sa=copy:FindFirstChildOfClass("SurfaceAppearance");if sa then sa.ColorMap=colour else copy.TextureID=colour end end
  end
  model.Parent=art
 end
 for id,e in pairs(lookup)do
  local source=workspace:FindFirstChild(id.."_color",true) or workspace:FindFirstChild(id.."_gray",true)
  local mesh=source and source:FindFirstChildWhichIsA("MeshPart",true)
  if mesh then preview(id,mesh,e.face or {});art[id]:SetAttribute("CharacterName",e.name)end
 end
 preview("coffee",workspace.Speed:FindFirstChild("CoffeeCup",true))
 preview("hat",workspace.HatShop:FindFirstChild("Show_cloche_1",true))
 preview("glace",workspace.Glaces:FindFirstChild("Cart"))
 preview("book",workspace.Bookshop:FindFirstChild("Shelf",true))
 preview("baguette",workspace.Baguette:FindFirstChild("ChaseBaguette",true))
 preview("windmill",workspace.Domaine.Props:FindFirstChild("windmill"))
 preview("church",workspace.Chapel:FindFirstChild("BellRope",true))
 preview("portrait",workspace.PortraitGallery:FindFirstChild("Easel",true))
 for _,m in ipairs(workspace.Trampolines:GetChildren())do if m:IsA("Model")then preview("toadstool",m);break end end
 assert(art:FindFirstChild("detective_squirrel"),"Squirrel portrait art missing")
 if old then old:Destroy() end
 art.Parent=RS
 warn("QQ P2 ART: "..#art:GetChildren().." inert previews from the game's original artwork")
end

history:SetWaypoint("Passport personal memories and click/touch collection")
warn("QQ P2 INSTALLED: 20 integrations, 5 Passport sources and illustrated book icon; both collection inputs; free books preserved")
end
