-- GardenCans (server): the watering can in each gate-garden can be picked up (prompt), is carried as a Tool with its
-- spout pointing straight ahead, and a click or tap pours it: the can tips forward and showers water; if the player
-- stands by a bed, its soil darkens, sparkles rise and the bed pushes up new growth for a minute. "Put down" (prompt on
-- the carried can, or Backspace) rests it at the player's feet; it goes back to its stand when left there a while,
-- when the carrier leaves the garden, or when the carrier leaves the game.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local domaine = script.Parent
local props = domaine:WaitForChild("Props")
local C = Color3.fromRGB

-- the beds, in the garden kit's own coordinates (gen_domaine_props.garden): soil rectangle and what grows there
local BEDS = {
	{x = -5.5, z = -4.0, w = 5.4, d = 3.4, top = 0.70, kind = "lettuce"},
	{x =  5.5, z = -4.0, w = 5.4, d = 3.4, top = 0.70, kind = "tomato"},
	{x = -5.5, z =  4.0, w = 5.4, d = 3.4, top = 0.70, kind = "pumpkin"},
	{x =  5.5, z =  4.0, w = 5.4, d = 3.4, top = 0.70, kind = "carrot"},
	{x = -3.0, z = -6.4, w = 3.6, d = 1.2, top = 0.65, kind = "flower"},
	{x =  3.0, z = -6.4, w = 3.6, d = 1.2, top = 0.65, kind = "flower"},
}
local SPOUT_LOCAL = Vector3.new(-0.9, 0.52, 0)          -- the spout tip in the can mesh's own (import-flipped) space; the spout is the mesh's -X
-- the R15 hand, measured in the tool-hold pose: the character's forward and up expressed in the RightGrip frame
local F_H = Vector3.new(0.1857, 0.1406, -0.9724)
local U_H = Vector3.new(-0.0701, 0.9898, 0.1297)
local GX = (-F_H).Unit                                   -- the can's +X points backward, so its spout (-X) points straight ahead
local GZ = GX:Cross(U_H).Unit
local GY = GZ:Cross(GX)
local GRIP = CFrame.new(0.4, 0.34, 0) * CFrame.fromMatrix(Vector3.zero, GX, GY, GZ):Inverse()   -- hand at the top of the body, can upright
local TILT = CFrame.fromAxisAngle(F_H:Cross(U_H).Unit, 0.85)                                  -- pouring: the can pitches forward about the hand's right axis
local LEAVE_RADIUS, REST_HOME_AFTER = 28, 120
local FLOWERS = {C(240, 90, 120), C(250, 200, 70), C(230, 80, 70), C(190, 120, 220), C(250, 250, 240), C(255, 150, 60)}
local LEAF, LETTUCE, TOMATO, PUMPKIN, STEM = C(114, 158, 76), C(140, 190, 90), C(216, 50, 50), C(234, 140, 38), C(90, 130, 64)

local function mkPart(parent, name, size, cf, col, shape)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic; p.Color = col; p.Size = size; p.CFrame = cf; p.CastShadow = true
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
-- a plant that grows up out of the ground over a second, stands for a minute and shrinks away
local function grow(parent, name, size, cf, col, shape, hold)
	local p = mkPart(parent, name, size * 0.05, cf - Vector3.new(0, size.Y * 0.47, 0), col, shape)
	TweenService:Create(p, TweenInfo.new(1.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = size, CFrame = cf}):Play()
	task.delay(hold or 60, function()
		if p.Parent then
			TweenService:Create(p, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = size * 0.05, CFrame = cf - Vector3.new(0, size.Y * 0.47, 0)}):Play()
			task.delay(1.05, function() p:Destroy() end)
		end
	end)
	return p
end

local function soak(st, bed)
	local garden, o = st.garden, st.origin
	local rng = st.rng
	local function W(x, y, z) return o:PointToWorldSpace(Vector3.new(x, y, z)) end
	local function at(x, y, z) return CFrame.new(W(x, y, z)) * o.Rotation end
	-- the soil darkens and dries over the next minute
	local wet = mkPart(garden, "Wet", Vector3.new(bed.w - 0.2, 0.03, bed.d - 0.2), at(bed.x, bed.top + 0.02, bed.z), C(58, 40, 26))
	wet.Transparency = 0.25
	TweenService:Create(wet, TweenInfo.new(55, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	task.delay(56, function() wet:Destroy() end)
	-- sparkles over the bed
	local sp = st.sparkles[bed]
	if not sp then
		local a = Instance.new("Attachment"); a.Name = "BedSparkle"; a.Parent = garden:FindFirstChild("Soil") or garden:FindFirstChildWhichIsA("BasePart")
		a.WorldPosition = W(bed.x, bed.top + 0.5, bed.z)
		sp = Instance.new("ParticleEmitter"); sp.Name = "Sparkle"; sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sp.Color = ColorSequence.new(C(220, 245, 255), C(160, 230, 170)); sp.Size = NumberSequence.new(0.3, 0); sp.Lifetime = NumberRange.new(0.8, 1.3)
		sp.Speed = NumberRange.new(1.5, 3); sp.SpreadAngle = Vector2.new(70, 70); sp.Acceleration = Vector3.new(0, -2.5, 0); sp.LightEmission = 0.6
		sp.Transparency = NumberSequence.new(0.1, 1); sp.Rate = 0; sp.Parent = a
		st.sparkles[bed] = sp
	end
	sp.Rate = 45
	task.delay(1.6, function() sp.Rate = 0 end)
	-- new growth for the kind of bed
	local k = bed.kind
	if k == "lettuce" then
		for i = 1, 5 do
			local x, z = bed.x + rng:NextNumber(-2.2, 2.2), bed.z + rng:NextNumber(-1.2, 1.2)
			grow(garden, "Sprout", Vector3.new(0.5, 0.4, 0.5), at(x, bed.top + 0.2, z), LETTUCE, Enum.PartType.Ball)
		end
	elseif k == "tomato" then
		for i = 1, 6 do
			local x = 3.5 + (i % 4) * 1.35 + rng:NextNumber(-0.3, 0.3)
			grow(garden, "Sprout", Vector3.new(0.22, 0.22, 0.22), at(x, rng:NextNumber(1.1, 2.3), bed.z + rng:NextNumber(-0.3, 0.3)), TOMATO, Enum.PartType.Ball)
		end
		for i = 1, 3 do
			grow(garden, "Sprout", Vector3.new(0.13, 0.13, 0.13), at(3.5 + rng:NextNumber(0, 4), rng:NextNumber(1.3, 2.4), bed.z + rng:NextNumber(-0.35, 0.35)), C(250, 220, 80), Enum.PartType.Ball)
		end
	elseif k == "pumpkin" then
		grow(garden, "Sprout", Vector3.new(0.7, 0.55, 0.7), at(bed.x + 1.1, bed.top + 0.27, bed.z + 1.0), PUMPKIN, Enum.PartType.Ball)
		for i = 1, 3 do
			grow(garden, "Sprout", Vector3.new(0.45, 0.16, 0.45), at(bed.x + rng:NextNumber(-2.2, 2.2), bed.top + 0.12, bed.z + rng:NextNumber(-1.2, 1.2)), LEAF, Enum.PartType.Ball)
		end
		for i = 1, 2 do
			grow(garden, "Sprout", Vector3.new(0.2, 0.2, 0.2), at(bed.x + rng:NextNumber(-2, 2), bed.top + 0.35, bed.z + rng:NextNumber(-1, 1)), C(250, 220, 80), Enum.PartType.Ball)
		end
	elseif k == "carrot" then
		for i = 1, 6 do
			local x, z = bed.x + rng:NextNumber(-2.2, 2.2), bed.z + rng:NextNumber(-1.2, 1.2)
			for j = -1, 1 do
				grow(garden, "Sprout", Vector3.new(0.07, 0.7, 0.07), at(x + j * 0.08, bed.top + 0.35, z) * CFrame.Angles(0, 0, j * 0.28), LEAF)
			end
			grow(garden, "Sprout", Vector3.new(0.05, 0.22, 0.22), at(x, bed.top + 0.03, z) * CFrame.Angles(0, 0, math.pi / 2), C(240, 130, 40), Enum.PartType.Cylinder)
		end
	else
		for i = 1, 6 do
			local x, z = bed.x + rng:NextNumber(-1.55, 1.55), bed.z + rng:NextNumber(-0.35, 0.35)
			grow(garden, "Sprout", Vector3.new(0.05, 0.8, 0.05), at(x, bed.top + 0.4, z), STEM)
			grow(garden, "Sprout", Vector3.new(0.32, 0.32, 0.32), at(x, bed.top + 0.85, z), FLOWERS[rng:NextInteger(1, #FLOWERS)], Enum.PartType.Ball)
		end
	end
end

local function setGrip(tool, cf, dur)
	local from = tool.Grip
	local steps = math.max(1, math.floor(dur / 0.05))
	for i = 1, steps do
		task.wait(0.05)
		if not tool.Parent then return end
		tool.Grip = from:Lerp(cf, i / steps)
	end
end

local function bedNear(st, pos)                          -- the bed within reach of a world position, if any
	local lp = st.origin:PointToObjectSpace(pos)
	local bed, best
	for _, b in ipairs(BEDS) do
		local dx = math.max(0, math.abs(lp.X - b.x) - b.w / 2)
		local dz = math.max(0, math.abs(lp.Z - b.z) - b.d / 2)
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < 3.4 and (not best or dist < best) then bed, best = b, dist end
	end
	return bed
end

local function water(st, player)
	if st.busy or not st.tool then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	st.busy = true
	local tool = st.tool
	local handle = tool:FindFirstChild("Handle")
	local pour = handle and handle:FindFirstChild("SpoutTip") and handle.SpoutTip:FindFirstChildOfClass("ParticleEmitter")
	local snd = handle and handle:FindFirstChildOfClass("Sound")
	if pour then pour.Rate = 220 end
	if snd then snd:Play(); task.delay(0.9, function() snd:Play() end) end
	task.spawn(setGrip, tool, GRIP * TILT, 0.35)
	-- the bed the player stands by, if any
	local bed = bedNear(st, root.Position)
	if bed then st.watered[bed] = os.clock(); task.delay(0.5, function() if st.tool == tool then soak(st, bed) end end) end
	task.delay(2.4, function()
		if pour then pour.Rate = 0 end
		if tool.Parent then task.spawn(setGrip, tool, GRIP, 0.4) end
		st.busy = false
	end)
end

-- the can rests at cf, visible, ready to be picked up
local function restCan(st, cf, away)
	st.can.CFrame = cf
	st.can.Transparency = st.canTransparency; st.can.CanCollide = st.canCollide
	st.prompt.Enabled = true; st.prompt.ActionText = "Pick up"
	st.away = away; st.restAt = os.clock()
end
-- put the can down on the ground at pos (spout along look); no pos = back on its stand
local function putDown(st, pos, look, char)
	local tool = st.tool
	st.tool = nil; st.carrier = nil; st.busy = false
	if tool then tool:Destroy() end
	if pos then
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {char, st.can}
		local r = workspace:Raycast(pos + Vector3.new(0, 1.5, 0), Vector3.new(0, -12, 0), rp)
		if r then
			local L = look and Vector3.new(look.X, 0, look.Z)
			L = (L and L.Magnitude > 0.01) and L.Unit or Vector3.new(0, 0, -1)
			local o = Vector3.new(pos.X, r.Position.Y + st.can.Size.Y / 2 + 0.02, pos.Z)
			restCan(st, CFrame.fromMatrix(o, -L, Vector3.yAxis, (-L):Cross(Vector3.yAxis)), true)
			return
		end
	end
	restCan(st, st.home, false)
end
local function putBack(st) putDown(st, nil) end

local function pickUp(st, player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local tool = Instance.new("Tool"); tool.Name = "Watering can"; tool.ToolTip = "Click or tap to water"; tool.CanBeDropped = true; tool.RequiresHandle = true
	tool.Grip = GRIP
	local handle = st.can:Clone(); handle.Name = "Handle"; handle:ClearAllChildren()
	handle.Anchored = false; handle.CanCollide = false; handle.CanQuery = false; handle.Massless = true; handle.Transparency = 0; handle.Parent = tool
	local tip = Instance.new("Attachment"); tip.Name = "SpoutTip"; tip.Position = SPOUT_LOCAL; tip.Parent = handle
	local pour = Instance.new("ParticleEmitter"); pour.Name = "Pour"; pour.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pour.Color = ColorSequence.new(C(130, 190, 255), C(205, 235, 255)); pour.Size = NumberSequence.new(0.28, 0.18); pour.Squash = NumberSequence.new(-1.5)
	pour.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.4)}); pour.Orientation = Enum.ParticleOrientation.VelocityParallel
	pour.Lifetime = NumberRange.new(0.7, 0.9); pour.Speed = NumberRange.new(4, 6); pour.SpreadAngle = Vector2.new(10, 10)
	pour.Acceleration = Vector3.new(0, -26, 0); pour.EmissionDirection = Enum.NormalId.Left; pour.LightEmission = 0.2; pour.Rate = 0; pour.Parent = tip
	local snd = Instance.new("Sound"); snd.SoundId = "rbxasset://sounds/impact_water.mp3"; snd.Volume = 0.35; snd.RollOffMaxDistance = 40; snd.Parent = handle
	-- "Put down" on the carried can itself
	local pd = Instance.new("ProximityPrompt"); pd.Name = "PutDown"; pd.ActionText = "Put down"; pd.ObjectText = "Watering can"
	pd.MaxActivationDistance = 10; pd.HoldDuration = 0; pd.RequiresLineOfSight = false; pd.UIOffset = Vector2.new(0, -36); pd.Parent = handle
	local hint = Instance.new("BillboardGui"); hint.Name = "Hint"; hint.Size = UDim2.new(0, 280, 0, 46); hint.StudsOffset = Vector3.new(0, 5.6, 0)
	hint.AlwaysOnTop = true; hint.MaxDistance = 40; hint.Adornee = char:FindFirstChild("Head"); hint.Parent = char:FindFirstChild("Head") or handle   -- above the head, clear of the hands
	local hl = Instance.new("TextLabel"); hl.Size = UDim2.fromScale(1, 1); hl.BackgroundColor3 = C(38, 30, 52); hl.BackgroundTransparency = 0.2
	hl.TextColor3 = C(255, 246, 220); hl.Font = Enum.Font.FredokaOne; hl.TextSize = 18; hl.TextWrapped = true; hl.Text = "Carry it up to a bed to water it (or click to pour)"; hl.Parent = hint
	local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 10); hc.Parent = hl
	task.delay(9, function() if hint.Parent then hint:Destroy() end end)
	tool.Parent = player.Backpack
	hum:EquipTool(tool)
	st.carrier = player; st.tool = tool
	task.spawn(function()                                              -- standing by a bed with the can pours on its own
		while st.tool == tool and tool.Parent do
			task.wait(0.5)
			if st.tool == tool and not st.busy then
				local c = player.Character
				local root = c and c:FindFirstChild("HumanoidRootPart")
				local bed = root and bedNear(st, root.Position)
				if bed and os.clock() - (st.watered[bed] or -1e9) > 15 then water(st, player) end
			end
		end
	end)
	st.can.Transparency = 1; st.can.CanCollide = false; st.prompt.Enabled = false
	tool.Activated:Connect(function() water(st, player) end)
	pd.Triggered:Connect(function(who)
		if who ~= st.carrier or st.tool ~= tool then return end
		local c = who.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root then putDown(st, root.Position + root.CFrame.LookVector * 1.7, root.CFrame.LookVector, c) else putBack(st) end
	end)
	tool.AncestryChanged:Connect(function()
		if st.tool ~= tool then return end
		if tool.Parent == workspace then                              -- dropped with Backspace: it lands at the player's feet
			local c = player.Character
			local root = c and c:FindFirstChild("HumanoidRootPart")
			local h = tool:FindFirstChild("Handle")
			if root and h then putDown(st, Vector3.new(h.Position.X, root.Position.Y, h.Position.Z), root.CFrame.LookVector, c) else putBack(st) end
		elseif not tool:IsDescendantOf(game) then
			putBack(st)
		end
	end)
end

local cans = {}
local function setup(garden)
	local can = garden:FindFirstChild("Iron")
	local origin = garden:GetAttribute("KitOrigin")
	if not (can and origin) or cans[garden] then return end
	local st = {garden = garden, can = can, origin = origin, home = can.CFrame, sparkles = {}, watered = {}, rng = Random.new(garden:GetAttribute("Seed") or 7),
		canTransparency = can.Transparency, canCollide = can.CanCollide, away = false}
	local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Pick up"; prompt.ObjectText = "Watering can"
	prompt.MaxActivationDistance = 8; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false; prompt.UIOffset = Vector2.new(0, -40); prompt.Parent = can
	st.prompt = prompt
	prompt.Triggered:Connect(function(player)
		if not st.carrier then pickUp(st, player) end
	end)
	cans[garden] = st
end
for _, m in ipairs(props:GetChildren()) do if m.Name == "garden" then setup(m) end end
props.ChildAdded:Connect(function(m) if m.Name == "garden" then task.defer(setup, m) end end)
-- a can carried out of the garden, or left lying about, goes back to its stand
task.spawn(function()
	while true do
		task.wait(2)
		for _, st in pairs(cans) do
			if st.carrier then
				local char = st.carrier.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root or (root.Position - st.origin.Position).Magnitude > LEAVE_RADIUS then putBack(st) end
			elseif st.away and st.restAt and os.clock() - st.restAt > REST_HOME_AFTER then
				restCan(st, st.home, false)
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	for _, st in pairs(cans) do if st.carrier == player then putBack(st) end end
end)
