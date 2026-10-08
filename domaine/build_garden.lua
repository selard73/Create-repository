-- The garden: what the seed packet is for. Shannon: "seed packets, variations you might get are a giant grinning
-- pumpkin that says 'bonjour', acorn bushes that you can harvest more acorns from, and a few more goofy ones."
--
-- Four personal beds in the corners of the vegetable garden between the Rue and the Chateau. Walk up with a seed
-- packet (Acorn Store, 15 acorns, Item_seed) and plant it; the bed grows one of six things, picked for you by the
-- server, and only YOU see your plants - a bed looks empty to everyone else until they plant their own, so nobody
-- can take the plot. What comes up:
--   1 pumpkin     a giant grinning pumpkin that says "Bonjour!" when you come near (and other pleasantries)
--   2 acorn bush  click its acorns to pick them (1 each); they grow back after a while, Harvests rounds, then it withers
--   3 sunflower   a sunflower with a face that turns to follow you round the garden
--   4 mushroom    a red toadstool: jump on the cap and it bounces you sky high
--   5 carrot      a shy carrot: it pops up to look when you approach and dives back down if you get too close
--   6 strawberry  a giant strawberry that giggles and wiggles when you touch it
-- A seed only sprouts. It grows as you WATER it, with one of the garden's own black watering cans (the Domaine script's
-- "Pick up" cans): stand by your bed holding one and it pours a tick a second, or click to pour; WaterSeconds ticks is
-- full grown - the plant scales up as the ticks come in. A plant is five counts in the save ledger (merge-safe deltas):
-- Item_bed<k> = variant, Item_bed<k>t = planted (server time), Item_bed<k>g = water ticks, Item_bed<k>h = last harvest,
-- Item_bed<k>n = harvests (rounds picked clean), Item_bed<k>p = acorns picked this round (a bitmask).
-- The client draws from those attributes and redraws when they change; the server only ever moves counts.
-- Attributes on workspace.Garden: GrowSeconds (45), HarvestAcorns (4), HarvestCooldown (600), Harvests (5).
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local G = workspace:FindFirstChild("Garden")
	if not G then G = Instance.new("Folder"); G.Name = "Garden"; G.Parent = workspace end
	local function default(name, v) if G:GetAttribute(name) == nil or opts[name] then G:SetAttribute(name, opts[name] or v) end end
	default("WaterSeconds", 30); default("HarvestAcorns", 4); default("HarvestCooldown", 600); default("Harvests", 5)
	G:SetAttribute("GrowSeconds", nil)                                  -- growth is watered now, not timed
	if not G:FindFirstChild("GardenAction") then local f = Instance.new("RemoteFunction"); f.Name = "GardenAction"; f.Parent = G end
	for _, o in ipairs(G:GetChildren()) do if o.Name:match("^Bed%d$") or o.Name == "GardenServer" or o.Name == "GardenClient" then o:Destroy() end end

	-- ---- the four beds, in the corners of the pad, clear of the kit beds, the path, the boxwoods and the oleanders
	local BEDS = opts.beds or {{357, -128}, {357, -112}, {384, -128}, {384, -112}}
	-- each bed stands on whatever is under it: the GardenPad by the path, or the lawn (Terrain, higher) at the back.
	-- Shannon (Sep 24): the back beds sat buried under the grass when they were all built at the pad's height.
	local function groundAt(x, z)
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {G}
		local r = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0), params)
		return r and r.Position.Y or 0.5
	end
	local WOOD, WOOD_DARK, SOIL = C(150, 110, 70), C(112, 80, 50), C(92, 64, 44)
	local function part(parent, name, size, cf, colour, material, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.Wood; p.Anchored = true; p.CanCollide = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	for k, b in ipairs(BEDS) do
		local bed = Instance.new("Model"); bed.Name = "Bed" .. k
		local cx, cz = b[1], b[2]
		local GROUND = groundAt(cx, cz)
		local base = CFrame.new(cx, GROUND, cz)
		for _, e in ipairs({{0, -2.25, 5, 0.5}, {0, 2.25, 5, 0.5}, {-2.25, 0, 0.5, 4}, {2.25, 0, 0.5, 4}}) do
			part(bed, "Plank", Vector3.new(e[3], 0.9, e[4]), base * CFrame.new(e[1], 0.45, e[2]), WOOD)
		end
		local soil = part(bed, "Soil", Vector3.new(4.4, 0.7, 4.4), base * CFrame.new(0, 0.5, 0), SOIL, Enum.Material.Ground)
		local prompt = Instance.new("ProximityPrompt"); prompt.Name = "BedPrompt"; prompt.ActionText = "Plant a seed"; prompt.ObjectText = "Garden bed"
		prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.MaxActivationDistance = 8; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0; prompt.Parent = soil
		bed.PrimaryPart = soil
		bed:SetAttribute("Bed", k)
		bed.Parent = G
	end

	do local old = game:GetService("ServerStorage"):FindFirstChild("WateringCan"); if old then old:Destroy() end end   -- the separate can is gone

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[
-- GardenServer: plant / harvest / dig, as moves in the item ledger. The client draws; nothing here is trusted from it.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local G = script.Parent
local action = G:WaitForChild("GardenAction")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local rng = Random.new()
-- what comes up, and how often: the bush and the pumpkin are the stars
local VARIANTS = {{1, 20}, {2, 25}, {3, 14}, {4, 14}, {5, 14}, {6, 13}}
local function pick()
	local total = 0
	for _, v in ipairs(VARIANTS) do total += v[2] end
	local r = rng:NextInteger(1, total)
	for _, v in ipairs(VARIANTS) do r -= v[2]; if r <= 0 then return v[1] end end
	return 1
end
local function get(player, id) return player:GetAttribute("Item_" .. id) or 0 end
local function setTo(player, id, value)                       -- the ledger takes deltas; the attribute follows from SquirrelSetup
	local cur = get(player, id)
	if value ~= cur then awardItems:Fire(player, id, value - cur) end
end
local lastWater = {}
-- one tick of water on bed k, if the player stands within reach holding a can; returns ok, ticks, grown
local function waterTick(player, k, tool)
	local id = "bed" .. k
	if get(player, id) == 0 then return false, "nothing planted there" end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local bed = G:FindFirstChild("Bed" .. k); local soil = bed and bed:FindFirstChild("Soil")
	if not (hrp and soil) or (hrp.Position - soil.Position).Magnitude > 14 then return false, "too far from the bed" end
	tool = tool or (char:FindFirstChild("Watering can") or char:FindFirstChild("WateringCan"))
	if not tool then return false, "you need a watering can in hand" end
	local need = G:GetAttribute("WaterSeconds") or 30
	local g = get(player, id .. "g")
	local t = os.clock()
	if t - (lastWater[player] or 0) < 0.85 then return true, g, g >= need end
	lastWater[player] = t
	-- the can's own pour, for everyone to see, for a moment after each tick
	local handle = tool:FindFirstChild("Handle")
	local tip = handle and handle:FindFirstChild("SpoutTip")
	local pour = tip and tip:FindFirstChildOfClass("ParticleEmitter")
	if pour then pour:Emit(24) end
	local snd = handle and handle:FindFirstChildOfClass("Sound")
	if snd and not snd.IsPlaying then snd:Play() end
	if g >= need then return true, g, true end
	setTo(player, id .. "g", g + 1)
	return true, g + 1, g + 1 >= need
end
-- the bed the player is closest to, of those planted, within reach
local function nearestPlanted(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local best, bestD
	for k = 1, 4 do
		if get(player, "bed" .. k) > 0 then
			local soil = G:FindFirstChild("Bed" .. k) and G["Bed" .. k]:FindFirstChild("Soil")
			local d = soil and (soil.Position - hrp.Position).Magnitude
			if d and d < 9 and (not bestD or d < bestD) then best, bestD = k, d end
		end
	end
	return best
end
-- the garden's black cans: a click on one beside your bed waters it; carried up to your plant, it pours on its own
local function watchCan(player, tool)
	if not tool:IsA("Tool") or (tool.Name ~= "Watering can" and tool.Name ~= "WateringCan") then return end
	if not tool:GetAttribute("GardenWatched") then                  -- one click hook per can, however often it is re-equipped
		tool:SetAttribute("GardenWatched", true)
		tool.Activated:Connect(function() local k = nearestPlanted(player); if k then waterTick(player, k, tool) end end)
	end
	task.spawn(function()
		while tool.Parent and tool.Parent == player.Character do
			local k = nearestPlanted(player)
			if k then waterTick(player, k, tool) end
			task.wait(1)
		end
	end)
end
local function watchCharacter(player, char)
	for _, c in ipairs(char:GetChildren()) do watchCan(player, c) end
	char.ChildAdded:Connect(function(c) watchCan(player, c) end)
end
local busy = {}
local function handle(player, kind, k, a)
	k = tonumber(k)
	if not k or k < 1 or k > 4 or k % 1 ~= 0 then return false, "no such bed" end
	local id = "bed" .. k
	local now = math.floor(workspace:GetServerTimeNow())
	local variant = get(player, id)
	if kind == "plant" then
		if variant > 0 then return false, "something is growing there" end
		if get(player, "seed") < 1 then return false, "you need a seed packet - the Acorn Store has them" end
		local v = pick()
		setTo(player, "seed", get(player, "seed") - 1)
		setTo(player, id .. "t", now); setTo(player, id .. "g", 0); setTo(player, id .. "h", 0); setTo(player, id .. "n", 0); setTo(player, id .. "p", 0)
		setTo(player, id, v)
		print(string.format("Garden: %s planted bed %d -> variant %d", player.Name, k, v))
		return true, v
	elseif kind == "pick" then                                -- one acorn off the bush, by a click on it
		if variant ~= 2 then return false, "nothing to pick there" end
		local need = G:GetAttribute("WaterSeconds") or 30
		local cool = G:GetAttribute("HarvestCooldown") or 600
		local max = G:GetAttribute("Harvests") or 5
		local per = G:GetAttribute("HarvestAcorns") or 4
		local i = tonumber(a)
		if not i or i < 1 or i > per or i % 1 ~= 0 then return false, "no such acorn" end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local bed = G:FindFirstChild("Bed" .. k); local soil = bed and bed:FindFirstChild("Soil")
		if not (hrp and soil) or (hrp.Position - soil.Position).Magnitude > 18 then return false, "too far from the bush" end
		local last, n, mask = get(player, id .. "h"), get(player, id .. "n"), get(player, id .. "p")
		if get(player, id .. "g") < need then return false, "still growing - water it" end
		if n >= max then return false, "the bush has given all it had" end
		if mask == 0 and last > 0 and now - last < cool then return false, "the acorns are still growing back" end
		local bit = 2 ^ (i - 1)
		if math.floor(mask / bit) % 2 == 1 then return false, "that one is picked" end
		mask = mask + bit
		awardAcorns:Fire(player, 1)
		player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + 1)
		local all = mask >= 2 ^ per - 1
		if all then
			setTo(player, id .. "p", 0); setTo(player, id .. "h", now); setTo(player, id .. "n", n + 1)
			print(string.format("Garden: %s picked bed %d clean (round %d/%d)", player.Name, k, n + 1, max))
		else
			setTo(player, id .. "p", mask)
		end
		return true, mask, all, n + 1 >= max
	elseif kind == "water" then
		return waterTick(player, k)
	elseif kind == "takecan" then
		return false, "the watering cans stand by the big beds - Pick up"
	elseif kind == "dig" then
		if variant == 0 then return false, "the bed is already empty" end
		setTo(player, id, 0); setTo(player, id .. "t", 0); setTo(player, id .. "g", 0); setTo(player, id .. "h", 0); setTo(player, id .. "n", 0); setTo(player, id .. "p", 0)
		return true
	end
	return false, "no such thing"
end
action.OnServerInvoke = function(player, kind, k, a)
	if busy[player] then return false, "one thing at a time" end
	busy[player] = true
	local ok, res, extra, extra2 = pcall(handle, player, kind, k, a)
	busy[player] = nil
	if not ok then warn("Garden: " .. tostring(kind) .. " failed - " .. tostring(res)); return false, "the garden is not answering" end
	return res, extra, extra2
end
-- every character is watched for a watering can in hand
local function onJoin(player)
	if player.Character then watchCharacter(player, player.Character) end
	player.CharacterAdded:Connect(function(char) watchCharacter(player, char) end)
end
Players.PlayerAdded:Connect(onJoin)
for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; lastWater[p] = nil end)
print("GardenServer: four beds ready - water to grow")
]==]

	-- ---------------------------------------------------------------- the client ----
	local CLIENT = [==[
-- GardenClient: draws this player's own plants in the beds from their Item_bed* attributes, grows them, gives each its
-- behaviour, and drives the bed prompts and signs for this player alone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local G = script.Parent
local action = G:WaitForChild("GardenAction")
local C = Color3.fromRGB
local NAMES = {"Pumpkin", "Acorn bush", "Sunflower", "Toadstool", "Shy carrot", "Strawberry"}
local local_ = Instance.new("Folder"); local_.Name = "MyPlants"; local_.Parent = G
local function now() return workspace:GetServerTimeNow() end
local toast                                                  -- defined further down; the bush's clicks use it
local function get(id) return player:GetAttribute("Item_" .. id) or 0 end
local function part(parent, name, size, cf, colour, material, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local function sound(parent, id, volume, speed)
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = volume or 0.6; s.PlaybackSpeed = speed or 1; s.Parent = parent; s:Play(); Debris:AddItem(s, 4)
end
-- a small speech bubble up and to the RIGHT of the speaker on screen (Shannon: it must not cover the pumpkin's face),
-- with a tail pointing back down-left at them. ExtentsOffset is camera-relative, so it stays to the right from any angle.
local function bubble(over, text, secs)
	local short = #text <= 2
	local bg = Instance.new("BillboardGui"); bg.Name = "Bubble"; bg.Size = short and UDim2.new(0, 46, 0, 40) or UDim2.new(0, 150, 0, 44)
	bg.StudsOffset = Vector3.new(0, 0.6, 0); bg.ExtentsOffset = Vector3.new(short and 1.1 or 0.75, 0.9, 0); bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.Parent = over
	local f = Instance.new("Frame"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = C(255, 250, 240); f.BorderSizePixel = 0; f.ZIndex = 2; f.Parent = bg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = f
	local st = Instance.new("UIStroke"); st.Color = C(120, 80, 46); st.Thickness = 1.5; st.Parent = f
	-- the tail: a little rotated square poking out of the bottom-left corner, toward the speaker
	local tail = Instance.new("Frame"); tail.AnchorPoint = Vector2.new(0.5, 0.5); tail.Position = UDim2.new(0.16, 0, 1, -3); tail.Size = UDim2.fromOffset(13, 13)
	tail.Rotation = 45; tail.BackgroundColor3 = C(255, 250, 240); tail.BorderSizePixel = 0; tail.ZIndex = 1; tail.Parent = bg
	local ts = Instance.new("UIStroke"); ts.Color = C(120, 80, 46); ts.Thickness = 1.5; ts.Parent = tail
	local cover = Instance.new("Frame"); cover.Position = UDim2.new(0.16, -8, 1, -12); cover.Size = UDim2.fromOffset(16, 11); cover.BackgroundColor3 = C(255, 250, 240); cover.BorderSizePixel = 0; cover.ZIndex = 3; cover.Parent = f
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -16, 1, -10); l.Position = UDim2.fromOffset(8, 5); l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextScaled = true
	l.TextColor3 = C(64, 42, 22); l.Text = text; l.ZIndex = 4; l.Parent = f
	Debris:AddItem(bg, secs or 3)
end
local function face(parent, cf, w, colour)                    -- two eyes and a grin, on the +z side of cf
	colour = colour or C(30, 20, 16)
	part(parent, "Eye", Vector3.new(w * 0.12, w * 0.14, 0.2), cf * CFrame.new(-w * 0.2, w * 0.12, 0), colour, nil, BALL)
	part(parent, "Eye", Vector3.new(w * 0.12, w * 0.14, 0.2), cf * CFrame.new(w * 0.2, w * 0.12, 0), colour, nil, BALL)
	part(parent, "Grin", Vector3.new(w * 0.46, w * 0.07, 0.2), cf * CFrame.new(0, -w * 0.14, 0), colour)
	part(parent, "Grin", Vector3.new(w * 0.1, w * 0.07, 0.2), cf * CFrame.new(-w * 0.26, -w * 0.09, 0) * CFrame.Angles(0, 0, math.rad(50)), colour)
	part(parent, "Grin", Vector3.new(w * 0.1, w * 0.07, 0.2), cf * CFrame.new(w * 0.26, -w * 0.09, 0) * CFrame.Angles(0, 0, math.rad(-50)), colour)
end

-- ---- the six plants: each builder gets the model and its base CFrame (soil top, facing the path) and returns a
-- behaviour table {tick(dt, dist, hrp), touched(part), acorns(ready, withered, mask)}
local BUILD = {}
BUILD[1] = function(m, base)                                  -- the pumpkin that says bonjour
	local body = part(m, "Body", Vector3.new(4.2, 4.2, 4.2), base * CFrame.new(0, 1.9, 0), C(236, 120, 34), nil, BALL)
	for i = 0, 5 do part(m, "Rib", Vector3.new(3.6, 0.35, 0.35), base * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, math.rad(i * 30), 0) * CFrame.new(2.0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), C(210, 100, 28), nil, CYL) end
	part(m, "Stem", Vector3.new(1.0, 0.7, 0.7), base * CFrame.new(0.2, 4.4, 0) * CFrame.Angles(0, 0, math.rad(102)), C(90, 130, 60), nil, CYL)
	part(m, "Leaf", Vector3.new(1.4, 0.1, 0.9), base * CFrame.new(-0.5, 4.2, 0.4) * CFrame.Angles(0, math.rad(30), math.rad(-15)), C(96, 150, 70))
	face(m, base * CFrame.new(0, 2.0, 2.05), 3.2)
	local lines = {"Bonjour!", "Bonjour, mon ami!", "Ca va?", "Magnifique!", "Bonjour! Bonjour!"}
	local last, k = 0, 0
	return {tick = function(dt, dist)
		if dist < 9 and now() - last > 9 then
			last = now(); k = k % #lines + 1
			bubble(body, lines[k], 3)
			sound(body, "rbxasset://sounds/button.wav", 0.5, 1.1)
			local t0 = body.CFrame
			TweenService:Create(body, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {CFrame = t0 + Vector3.new(0, 0.5, 0)}):Play()
		end
	end}
end
-- a little +1 that floats up off a picked acorn
local function plusOne(over)
	local bg = Instance.new("BillboardGui"); bg.Size = UDim2.new(0, 60, 0, 30); bg.StudsOffset = Vector3.new(0, 0.6, 0); bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.Adornee = over; bg.Parent = over.Parent
	local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextColor3 = C(255, 236, 150); l.TextStrokeTransparency = 0.4; l.Text = "+1"; l.Parent = bg
	TweenService:Create(bg, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {StudsOffset = Vector3.new(0, 2.4, 0)}):Play()
	TweenService:Create(l, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	Debris:AddItem(bg, 1)
end
BUILD[2] = function(m, base)                                  -- the acorn bush: click (tap) each acorn to pick it
	local k = tonumber(m.Name:match("%d+"))
	for _, b in ipairs({{0, 1.5, 0, 3.4}, {-1.1, 1.2, 0.6, 2.6}, {1.0, 1.3, -0.5, 2.5}, {0.2, 2.5, 0.3, 2.4}}) do
		part(m, "Leaves", Vector3.new(b[4], b[4], b[4]), base * CFrame.new(b[1], b[2], b[3]), C(74, 132, 66), nil, BALL)
	end
	-- the acorns sit on the path side and the top, where they can be clicked; HarvestAcorns of them (the spots repeat past six)
	local SPOTS = {{1.2, 1.9, 1.1}, {-1.3, 2.2, 0.9}, {0.3, 3.4, 0.8}, {-0.4, 1.2, 1.5}, {1.3, 3.0, 0.1}, {-1.2, 1.1, -0.2}}
	local per = G:GetAttribute("HarvestAcorns") or 4
	local nuts = {}
	local busy = false
	local function pick(i)
		local nut, cap = nuts[i].nut, nuts[i].cap
		if busy or nut.Transparency > 0.5 then return end
		busy = true
		local ok, res, extra, all = pcall(function() return action:InvokeServer("pick", k, i) end)
		busy = false
		if not ok then toast("The garden is not answering."); return end
		if not res then toast(tostring(extra)); return end
		-- the acorn pops off: a copy flies up and fades; the bush itself follows the ledger
		for _, src in ipairs({nut, cap}) do
			local fly = src:Clone(); fly.Parent = m
			TweenService:Create(fly, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = src.CFrame + Vector3.new(0, 2.2, 0), Size = src.Size * 0.3, Transparency = 1}):Play()
			Debris:AddItem(fly, 0.6)
		end
		nut.Transparency = 1; cap.Transparency = 1
		sound(nut, "rbxasset://sounds/snap.mp3", 0.6, 1.4)
		plusOne(nut)
		if all then toast("Picked clean! The acorns grow back in a while.") end
	end
	for i = 1, per do
		local sp = SPOTS[(i - 1) % #SPOTS + 1]
		local lift = math.floor((i - 1) / #SPOTS) * 0.6
		local nut = part(m, "Nut", Vector3.new(0.7, 0.8, 0.7), base * CFrame.new(sp[1], sp[2] + lift, sp[3]), C(196, 136, 66), nil, BALL)
		local cap = part(m, "Cap", Vector3.new(0.76, 0.3, 0.76), base * CFrame.new(sp[1], sp[2] + lift + 0.32, sp[3]), C(120, 78, 40), nil, CYL); cap.CFrame = cap.CFrame * CFrame.Angles(0, 0, math.rad(90))
		for _, q in ipairs({nut, cap}) do
			q.CanQuery = true
			local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 16; cd.Parent = q
			cd.MouseClick:Connect(function() pick(i) end)
		end
		nuts[i] = {nut = nut, cap = cap}
	end
	return {acorns = function(ready, withered, mask)
		for i, q in ipairs(nuts) do
			local picked = math.floor((mask or 0) / 2 ^ (i - 1)) % 2 == 1
			local show = ready and not picked
			q.nut.Transparency = show and 0 or 1; q.cap.Transparency = show and 0 or 1
		end
		if withered then for _, q in ipairs(m:GetChildren()) do if q.Name == "Leaves" then q.Color = C(120, 96, 60) end end end
	end}
end
BUILD[3] = function(m, base)                                  -- the sunflower that follows you
	part(m, "Stalk", Vector3.new(0.4, 6.0, 0.4), base * CFrame.new(0, 3.0, 0), C(86, 140, 62), nil, CYL).CFrame = base * CFrame.new(0, 3.0, 0) * CFrame.Angles(0, 0, math.rad(90))
	part(m, "Leaf", Vector3.new(1.8, 0.12, 1.0), base * CFrame.new(0.9, 2.2, 0) * CFrame.Angles(0, 0, math.rad(20)), C(96, 150, 70))
	part(m, "Leaf", Vector3.new(1.8, 0.12, 1.0), base * CFrame.new(-0.9, 3.4, 0) * CFrame.Angles(0, 0, math.rad(-20)), C(96, 150, 70))
	local head = Instance.new("Model"); head.Name = "Head"; head.Parent = m
	local hb = base * CFrame.new(0, 6.3, 0)
	local disc = part(head, "Disc", Vector3.new(2.4, 0.5, 2.4), hb * CFrame.Angles(math.rad(90), 0, 0), C(96, 62, 34), nil, CYL)
	disc.CFrame = hb * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(90), 0)
	for i = 0, 11 do part(head, "Petal", Vector3.new(0.8, 1.6, 0.15), hb * CFrame.Angles(0, 0, math.rad(i * 30)) * CFrame.new(0, 1.8, -0.05), C(250, 204, 40)) end
	face(head, hb * CFrame.new(0, 0, 0.3), 2.0, C(40, 26, 18))
	head.PrimaryPart = disc
	local pivot0 = head:GetPivot()
	return {tick = function(dt, dist, hrp)
		if not hrp then return end
		local target = hrp.Position + Vector3.new(0, 1, 0)
		local want = CFrame.lookAt(pivot0.Position, target)
		local cur = head:GetPivot()
		head:PivotTo(cur:Lerp(want, math.min(1, dt * 4)))
	end}
end
BUILD[4] = function(m, base)                                  -- the toadstool trampoline: a stepped low-poly dome on a stalk
	part(m, "Stalk", Vector3.new(2.8, 1.8, 1.8), base * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90)), C(246, 236, 210), nil, CYL)
	local RED = C(214, 50, 46)
	local caps = {}
	for i, d in ipairs({{5.6, 0.5}, {5.1, 0.5}, {4.3, 0.5}, {3.2, 0.45}, {1.8, 0.4}}) do           -- discs, widest at the bottom
		local y = 2.8 + 0.25 + (i - 1) * 0.47
		local disc = part(m, "Cap", Vector3.new(d[2], d[1], d[1]), base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), RED, nil, CYL)
		disc.CanTouch = true; disc.CanQuery = true; disc.CanCollide = true                        -- you can stand on it - and bounce
		caps[#caps + 1] = disc
	end
	for _, s in ipairs({{1.0, 3.25, 0.9, 0.8}, {-1.5, 3.25, 0.3, 0.7}, {0.3, 3.72, -1.4, 0.7}, {-0.7, 4.19, -0.5, 0.6}, {1.2, 3.72, -0.9, 0.55}}) do
		part(m, "Spot", Vector3.new(0.12, s[4], s[4]), base * CFrame.new(s[1], s[2] + 0.2, s[3]) * CFrame.Angles(0, 0, math.rad(90)), C(250, 246, 236), nil, CYL)
	end
	local lastBounce = 0
	local function bounce(hit, hrp)
		if not hrp or os.clock() - lastBounce < 0.7 then return end
		lastBounce = os.clock()
		local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end                        -- off the ground first, or the humanoid eats the push
		task.defer(function() hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X * 0.3, 95, hrp.AssemblyLinearVelocity.Z * 0.3) end)
		sound(caps[1], "rbxasset://sounds/Short spring sound.wav", 0.8, 1)
		for _, c in ipairs(caps) do
			local s0 = c.Size
			TweenService:Create(c, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = Vector3.new(s0.X * 0.6, s0.Y * 1.08, s0.Z * 1.08)}):Play()
		end
	end
	return {touched = bounce, touchParts = caps}
end
BUILD[5] = function(m, base)                                  -- the shy carrot
	local root = Instance.new("Model"); root.Name = "Root"; root.Parent = m
	for i, r in ipairs({{1.8, 0.0}, {1.4, -1.2}, {0.9, -2.2}, {0.4, -2.9}}) do
		part(root, "Carrot", Vector3.new(r[1], 1.2, r[1]), base * CFrame.new(0, r[2] - 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), C(240, 120, 40), nil, CYL)
	end
	for i = 0, 4 do part(root, "Tuft", Vector3.new(0.35, 1.8, 0.35), base * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, math.rad(i * 72), math.rad(20)) * CFrame.new(0.3, 0.4, 0), C(90, 150, 70), nil, CYL).CFrame = base * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, math.rad(i * 72), 0) * CFrame.new(0.35, 0, 0) * CFrame.Angles(0, 0, math.rad(15)) end
	face(root, base * CFrame.new(0, -0.5, 0.92), 1.4)
	root.PrimaryPart = root:FindFirstChild("Carrot")
	local down = root:GetPivot()
	local up = down + Vector3.new(0, 2.6, 0)
	local state = "down"
	local function go(cf, secs)
		local t = {}
		for _, p in ipairs(root:GetDescendants()) do if p:IsA("BasePart") then t[p] = down:ToObjectSpace(p.CFrame) end end
		local cur = root:GetPivot()
		local t0, T = os.clock(), secs
		local conn; conn = RunService.RenderStepped:Connect(function()
			local a = math.min(1, (os.clock() - t0) / T)
			a = 1 - (1 - a) ^ 3
			root:PivotTo(cur:Lerp(cf, a))
			if a >= 1 then conn:Disconnect() end
		end)
	end
	return {tick = function(dt, dist)
		if state == "down" and dist < 13 and dist > 5 then state = "up"; go(up, 0.5); bubble(root.PrimaryPart, "!", 1.2)
		elseif state == "up" and dist <= 4.5 then state = "hiding"; go(down, 0.35); sound(root.PrimaryPart, "rbxasset://sounds/snap.mp3", 0.6, 1.6); bubble(root.PrimaryPart, "Oh la la!", 1.5); task.delay(4, function() if state == "hiding" then state = "down" end end)
		elseif state == "up" and dist > 16 then state = "down"; go(down, 0.6) end
	end}
end
BUILD[6] = function(m, base)                                  -- the giggling strawberry
	local body = part(m, "Body", Vector3.new(3.4, 3.4, 3.4), base * CFrame.new(0, 1.6, 0), C(220, 40, 60), nil, BALL)
	local rng = Random.new(6)
	for i = 1, 22 do
		local a, b = rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.9, 0.7)
		local r = 1.72
		local x, y, z = math.cos(a) * math.sqrt(1 - b * b) * r, b * r, math.sin(a) * math.sqrt(1 - b * b) * r
		part(m, "Seed", Vector3.new(0.22, 0.32, 0.22), base * CFrame.new(x, 1.6 + y, z), C(250, 220, 90), nil, BALL)
	end
	for i = 0, 5 do part(m, "Leaf", Vector3.new(1.4, 0.12, 0.7), base * CFrame.new(0, 3.2, 0) * CFrame.Angles(0, math.rad(i * 60), 0) * CFrame.new(0.9, 0, 0) * CFrame.Angles(0, 0, math.rad(-20)), C(80, 150, 70)) end
	part(m, "Stem", Vector3.new(0.4, 0.9, 0.4), base * CFrame.new(0, 3.6, 0), C(90, 130, 60), nil, CYL).CFrame = base * CFrame.new(0, 3.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	face(m, base * CFrame.new(0, 1.5, 1.68), 2.4, C(60, 20, 30))
	body.CanTouch = true; body.CanQuery = true
	local last = 0
	return {touched = function(hit)
		if os.clock() - last < 1.6 then return end
		last = os.clock()
		bubble(body, "Hee hee!", 1.5)
		sound(body, "rbxasset://sounds/uuhhh.mp3", 0.5, 1.7)
		local parts = {}
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then parts[p] = p.CFrame end end
		local t0 = os.clock()
		local conn; conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			local ang = math.sin(t * 22) * math.rad(12) * math.max(0, 1 - t / 1.2)
			local pivot = base * CFrame.new(0, 0, 0)
			for p, cf in pairs(parts) do p.CFrame = pivot * CFrame.Angles(0, 0, ang) * pivot:ToObjectSpace(cf) end
			if t > 1.2 then conn:Disconnect(); for p, cf in pairs(parts) do p.CFrame = cf end end
		end)
	end, touchPart = body}
end

-- ---- Shannon's Meshy plants: a template per variant in ReplicatedStorage.PlantMeshes replaces the part build
local RS = game:GetService("ReplicatedStorage")
local MESH_NAMES = {[1] = "Pumpkin", [3] = "Sunflower", [5] = "Carrot", [6] = "Strawberry"}
local function meshTemplate(v)
	local f = RS:FindFirstChild("PlantMeshes")
	return f and MESH_NAMES[v] and f:FindFirstChild(MESH_NAMES[v])
end
-- a clone of a template, standing on `cf` (position = ground point, LookVector = the way it faces), scaled by `scale`
local function placeMesh(tpl, parent, cf, scale)
	local inst = tpl:Clone()
	local model = inst
	if not inst:IsA("Model") then model = Instance.new("Model"); inst.Parent = model; model.PrimaryPart = inst end
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end end
	if scale and math.abs(scale - 1) > 0.001 then pcall(function() model:ScaleTo(scale) end) end
	local bb, size = model:GetBoundingBox()
	local pivotInBB = bb:ToObjectSpace(model:GetPivot())
	local yaw = tpl:GetAttribute("FaceYaw") or 0
	local targetBB = cf * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(0, size.Y / 2, 0)
	model:PivotTo(targetBB * pivotInBB)
	model.Parent = parent
	return model, size, pivotInBB
end
local function firstPart(model) return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) end
local MESH_BUILD = {}
MESH_BUILD[1] = function(m, base, tpl)                        -- the pumpkin: greets, and hops when it does
	local pk, size, pin = placeMesh(tpl, m, base, 0.85)
	local lines = {"Bonjour!", "Bonjour, mon ami!", "Ca va?", "Magnifique!", "Bonjour! Bonjour!"}
	local last, k, hop = 0, 0, 0
	local rest = pk:GetPivot()
	return {tick = function(dt, dist)
		if dist < 9 and now() - last > 9 then
			last = now(); k = k % #lines + 1; hop = 1
			bubble(firstPart(pk), lines[k], 3); sound(firstPart(pk), "rbxasset://sounds/button.wav", 0.5, 1.1)
		end
		if hop > 0 then
			hop = math.max(0, hop - dt * 2.2)
			local h = math.sin((1 - hop) * math.pi) * 0.6
			pk:PivotTo(rest + Vector3.new(0, h, 0))
		end
	end}
end
MESH_BUILD[3] = function(m, base, tpl)                        -- the sunflower: turns on its stalk to follow you, face first
	local sf, size, pin = placeMesh(tpl, m, base, 1)
	local yaw0 = math.rad(tpl:GetAttribute("FaceYaw") or 0)
	local faceBase = base * CFrame.Angles(0, yaw0, 0)        -- the way the FACE points at rest (FaceYaw turns the mesh to the path)
	local cur = 0
	return {tick = function(dt, dist, hrp)
		if not hrp then return end
		local to = hrp.Position - base.Position
		local flat = Vector3.new(to.X, 0, to.Z)
		if flat.Magnitude < 0.5 then return end
		local want = math.atan2(-flat.Unit:Dot(faceBase.RightVector), flat.Unit:Dot(faceBase.LookVector))
		want = math.clamp(want, math.rad(-70), math.rad(70))
		cur = cur + (want - cur) * math.min(1, dt * 3)
		local targetBB = base * CFrame.Angles(0, yaw0 + cur, 0) * CFrame.new(0, size.Y / 2, 0)
		sf:PivotTo(targetBB * pin)
	end}
end
MESH_BUILD[5] = function(m, base, tpl)                        -- three shy carrots in a row: they pop up to look, and duck
	local carrots = {}
	for i, x in ipairs({-1.4, 0, 1.4}) do
		local cf = base * CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad((i - 2) * 12), 0)
		local c, size, pin = placeMesh(tpl, m, cf, 0.6)
		local upPivot = c:GetPivot()
		carrots[i] = {model = c, up = upPivot, down = upPivot - Vector3.new(0, size.Y * 0.42, 0), pos = 0, target = 0, delay = (i - 1) * 0.18}
		c:PivotTo(carrots[i].down)
	end
	local state, since = "down", 0
	local mid = carrots[2].model
	return {tick = function(dt, dist)
		since += dt
		if state == "down" and dist < 13 and dist > 5 then state = "up"; since = 0; bubble(firstPart(mid), "!", 1.2)
		elseif state == "up" and dist <= 4.5 then state = "hiding"; since = 0; sound(firstPart(mid), "rbxasset://sounds/snap.mp3", 0.6, 1.6); bubble(firstPart(mid), "Oh la la!", 1.5)
		elseif state == "hiding" and since > 4 then state = "down"
		elseif state == "up" and dist > 16 then state = "down" end
		local t = os.clock()
		for i, c in ipairs(carrots) do
			c.target = (state == "up" and since > c.delay) and 1 or 0
			local speed = (c.target > c.pos) and 3.5 or 6
			c.pos = c.pos + (c.target - c.pos) * math.min(1, dt * speed)
			local hop = math.max(0, math.sin(t * 3.2 + i * 1.3)) ^ 2 * 0.3 * c.pos      -- a little bounce while it is up (Shannon)
			c.model:PivotTo(c.down:Lerp(c.up, c.pos) + Vector3.new(0, hop, 0))
		end
	end}
end
MESH_BUILD[6] = function(m, base, tpl)                        -- three giggling strawberries in a row
	local berries, parts = {}, {}
	for i, x in ipairs({-1.45, 0, 1.45}) do
		local cf = base * CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad((i - 2) * 25), 0)
		local b = placeMesh(tpl, m, cf, 0.55)
		berries[i] = {model = b, rest = b:GetPivot(), phase = i * 0.7}
		for _, d in ipairs(b:GetDescendants()) do if d:IsA("BasePart") then d.CanTouch = true; d.CanQuery = true; parts[#parts + 1] = d end end
	end
	local last, wiggleT = 0, -1
	return {touched = function()
		if os.clock() - last < 1.6 then return end
		last = os.clock(); wiggleT = 0
		bubble(firstPart(berries[2].model), "Hee hee!", 1.5); sound(firstPart(berries[2].model), "rbxasset://sounds/uuhhh.mp3", 0.5, 1.7)
	end, tick = function(dt)
		local t = os.clock()
		local fade = 0
		if wiggleT >= 0 then
			wiggleT += dt
			fade = math.max(0, 1 - wiggleT / 1.3)
			if fade <= 0 then wiggleT = -1 end
		end
		for _, b in ipairs(berries) do
			local ang = (fade > 0) and math.sin(wiggleT * 22 + b.phase) * math.rad(14) * fade or 0
			local hop = math.max(0, math.sin(t * 3.0 + b.phase * 2)) ^ 2 * 0.22                -- a little bounce (Shannon)
			b.model:PivotTo((b.rest + Vector3.new(0, hop, 0)) * CFrame.Angles(0, 0, ang))
		end
	end, touchParts = parts}
end

-- ---- the beds: draw, grow, prompt
local beds = {}
local function bedInfo(k)
	local bed = G:FindFirstChild("Bed" .. k)
	local soil = bed and bed:FindFirstChild("Soil")
	return bed, soil, soil and soil:FindFirstChild("BedPrompt"), bed and bed:FindFirstChild("SignBoard")
end
local function setSign(board, text)
	if not board then return end
	for _, sg in ipairs(board:GetChildren()) do local t = sg:FindFirstChild("Text"); if t then t.Text = text end end
end
local function clearBed(k)
	local rec = beds[k]
	if rec then
		if rec.conn then rec.conn:Disconnect() end
		for _, c in ipairs(rec.touchConns or {}) do c:Disconnect() end
		if rec.model then rec.model:Destroy() end
	end
	beds[k] = nil
end
local function need() return G:GetAttribute("WaterSeconds") or 30 end
local function bushState(k)
	local cool = G:GetAttribute("HarvestCooldown") or 600
	local max = G:GetAttribute("Harvests") or 5
	local last, n, mask = get("bed" .. k .. "h"), get("bed" .. k .. "n"), get("bed" .. k .. "p")
	local grown = get("bed" .. k .. "g") >= need()
	local withered = n >= max
	local ready = grown and not withered and (mask ~= 0 or last == 0 or now() - last >= cool)   -- a round under way stays out
	return ready, withered, grown, mask
end
local function drawBed(k)
	clearBed(k)
	local bed, soil, prompt, board = bedInfo(k)
	if not soil then return end
	local v = get("bed" .. k)
	if v == 0 or not BUILD[v] then
		setSign(board, "Your bed")
		if prompt then prompt.ActionText = "Plant a seed"; prompt.ObjectText = get("seed") > 0 and ("Garden bed  -  seeds: " .. get("seed")) or "Garden bed  -  buy a seed packet"; prompt.HoldDuration = 0 end
		return
	end
	local m = Instance.new("Model"); m.Name = "Plant" .. k; m.Parent = local_
	local base = CFrame.new(soil.Position + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, (soil.Position.X < 370) and math.rad(90) or math.rad(-90), 0)   -- faces the path
	local tpl = meshTemplate(v)
	local beh = (tpl and MESH_BUILD[v]) and (MESH_BUILD[v](m, base, tpl) or {}) or (BUILD[v](m, base) or {})
	local ground = Instance.new("Part"); ground.Name = "Root"; ground.Size = Vector3.new(0.2, 0.2, 0.2); ground.Transparency = 1; ground.Anchored = true; ground.CanCollide = false; ground.CanQuery = false; ground.CanTouch = false; ground.CFrame = base; ground.Parent = m
	m.PrimaryPart = ground
	local rec = {model = m, beh = beh, variant = v}
	beds[k] = rec
	setSign(board, NAMES[v])
	-- growth: a sprout at planting, full size at WaterSeconds ticks of watering; the scale eases toward the ticks
	local function targetScale()
		local a = math.clamp(get("bed" .. k .. "g") / need(), 0, 1)
		return 0.12 + 0.88 * (1 - (1 - a) ^ 2)
	end
	rec.scale = (rec.keepScale) or targetScale()
	pcall(function() m:ScaleTo(rec.scale) end)
	local touchParts = beh.touchParts or (beh.touchPart and {beh.touchPart}) or {}
	rec.touchConns = {}
	for _, tp in ipairs(touchParts) do
		rec.touchConns[#rec.touchConns + 1] = tp.Touched:Connect(function(hit)
			local char = player.Character
			if char and hit:IsDescendantOf(char) and beh.touched then beh.touched(hit, char:FindFirstChild("HumanoidRootPart")) end
		end)
	end
	rec.conn = RunService.RenderStepped:Connect(function(dt)
		if not m.Parent then return end
		local want = targetScale()
		if math.abs(want - rec.scale) > 0.002 then rec.scale = rec.scale + (want - rec.scale) * math.min(1, dt * 3); pcall(function() m:ScaleTo(rec.scale) end) end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local dist = hrp and (hrp.Position - base.Position).Magnitude or 1000
		if beh.tick and rec.scale >= 0.98 then beh.tick(dt, dist, hrp) end
	end)
	local function refreshPrompt()
		if not prompt then return end
		if v == 2 then
			local ready, withered, grown, mask = bushState(k)
			if beh.acorns then beh.acorns(ready, withered, mask) end
			if withered then prompt.ActionText = "Dig up the old bush"; prompt.ObjectText = "Acorn bush  -  it gave all it had"; prompt.HoldDuration = 0.8
			elseif not grown then prompt.ActionText = "Dig up"; prompt.ObjectText = string.format("Acorn bush  -  water it (%d/%d)", get("bed" .. k .. "g"), need()); prompt.HoldDuration = 1.2
			elseif ready then prompt.ActionText = "Dig up"; prompt.ObjectText = "Acorn bush  -  click the acorns!"; prompt.HoldDuration = 1.2
			else prompt.ActionText = "Dig up"; prompt.ObjectText = "Acorn bush  -  acorns growing back"; prompt.HoldDuration = 1.2 end
		else
			local g = get("bed" .. k .. "g")
			prompt.ActionText = "Dig up"; prompt.ObjectText = (g < need()) and string.format("%s  -  water it (%d/%d)", NAMES[v], g, need()) or NAMES[v]; prompt.HoldDuration = 1.2
		end
	end
	refreshPrompt()
	rec.refreshPrompt = refreshPrompt
end
local function drawAll() for k = 1, 4 do drawBed(k) end end
-- the toast, defined before anything below can call it
function toast(text)
	local gui = player.PlayerGui:FindFirstChild("GardenToast")
	if not gui then gui = Instance.new("ScreenGui"); gui.Name = "GardenToast"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8; gui.Parent = player.PlayerGui end
	for _, c in ipairs(gui:GetChildren()) do c:Destroy() end
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 1); l.Position = UDim2.new(0.5, 0, 1, -118); l.Size = UDim2.fromOffset(420, 44)
	l.BackgroundColor3 = C(58, 36, 16); l.BackgroundTransparency = 0.1; l.BorderSizePixel = 0; l.Font = Enum.Font.FredokaOne; l.TextSize = 20; l.TextColor3 = C(255, 202, 62); l.TextWrapped = true; l.Text = text; l.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = l
	Debris:AddItem(l, 4)
end
-- redraw whenever the ledger moves - except water ticks, which only ease the plant up and splash the soil
local function splash(k)
	local bed, soil = bedInfo(k)
	if not soil then return end
	local att = Instance.new("Attachment"); att.Position = Vector3.new(0, 0.4, 0); att.Parent = soil
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(C(160, 210, 250))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.3)}); pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Lifetime = NumberRange.new(0.3, 0.5); pe.Speed = NumberRange.new(3, 5); pe.SpreadAngle = Vector2.new(70, 70); pe.Acceleration = Vector3.new(0, -20, 0); pe.Rate = 0; pe.Parent = att
	pe:Emit(10)
	Debris:AddItem(att, 1.5)
end
for k = 1, 4 do
	for _, suffix in ipairs({"", "t", "h", "n"}) do
		player:GetAttributeChangedSignal("Item_bed" .. k .. suffix):Connect(function() drawBed(k) end)
	end
	player:GetAttributeChangedSignal("Item_bed" .. k .. "p"):Connect(function() local rec = beds[k]; if rec and rec.refreshPrompt then rec.refreshPrompt() else drawBed(k) end end)
	player:GetAttributeChangedSignal("Item_bed" .. k .. "g"):Connect(function()
		local rec = beds[k]
		local g = get("bed" .. k .. "g")
		if not rec then drawBed(k); return end
		if g > 0 then
			splash(k)
			local _, soil = bedInfo(k)
			local tag = soil and soil:FindFirstChild("WaterTag")
			if soil and not tag then
				tag = Instance.new("BillboardGui"); tag.Name = "WaterTag"; tag.Size = UDim2.new(0, 150, 0, 40); tag.StudsOffset = Vector3.new(0, 4.6, 0); tag.AlwaysOnTop = true; tag.Parent = soil
				local tl = Instance.new("TextLabel"); tl.Name = "Text"; tl.Size = UDim2.fromScale(1, 1); tl.BackgroundColor3 = C(58, 36, 16); tl.BackgroundTransparency = 0.25; tl.Font = Enum.Font.FredokaOne; tl.TextScaled = true; tl.TextColor3 = C(160, 210, 250); tl.Parent = tag
				local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = tl
			end
			if tag then tag.Text.Text = (g >= need()) and "fully grown!" or string.format("water  %d / %d", g, need()); tag.Enabled = true; tag:SetAttribute("At", os.clock()); task.delay(2.2, function() if tag.Parent and os.clock() - (tag:GetAttribute("At") or 0) >= 2.1 then tag.Enabled = false end end) end
		end
		if rec.refreshPrompt then rec.refreshPrompt() end
		if g >= need() and (rec.lastG or 0) < need() then
			toast(string.format("Your %s is fully grown!", NAMES[rec.variant] or "plant"):lower():gsub("^%l", string.upper))
			local soil = select(2, bedInfo(k))
			if soil then
				local att = Instance.new("Attachment"); att.Position = Vector3.new(0, 2.5, 0); att.Parent = soil
				local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(C(255, 230, 120), C(255, 250, 220))
				pe.Size = NumberSequence.new(0.6, 0); pe.Lifetime = NumberRange.new(0.8, 1.4); pe.Speed = NumberRange.new(3, 6); pe.SpreadAngle = Vector2.new(180, 180); pe.LightEmission = 0.8; pe.Rate = 0; pe.Parent = att
				pe:Emit(40)
				Debris:AddItem(att, 3)
			end
		end
		rec.lastG = g
	end)
end
player:GetAttributeChangedSignal("Item_seed"):Connect(function() for k = 1, 4 do if get("bed" .. k) == 0 then drawBed(k) end end end)
-- the bush's readiness changes with the clock, not the ledger
task.spawn(function() while true do task.wait(5) for k = 1, 4 do local rec = beds[k]; if rec and rec.refreshPrompt then rec.refreshPrompt() end end end end)
-- the prompts
for k = 1, 4 do
	task.spawn(function()
		local bed = G:WaitForChild("Bed" .. k, 60)
		local soil = bed and bed:WaitForChild("Soil", 60)
		local prompt = soil and soil:WaitForChild("BedPrompt", 60)
		if not prompt then return end
		prompt.Triggered:Connect(function()
			local v = get("bed" .. k)
			local kind
			if v == 0 then kind = "plant"
			else kind = "dig" end
			local ok, res, extra, extra2 = pcall(function() return action:InvokeServer(kind, k) end)
			if not ok then toast("The garden is not answering."); return end
			if not res then toast(tostring(extra)); return end
			if kind == "plant" then toast("Planted! Fetch a watering can from the big beds (Pick up) and stand by your plant to water it.")
			elseif kind == "dig" then toast("Bed " .. k .. " is clear again.") end
			task.delay(0.2, function() drawBed(k) end)
		end)
		drawBed(k)
	end)
end
]==]
	local function install(name, ctx, src)
		local s = Instance.new("Script"); s.Name = name; s.RunContext = ctx; s.Source = src; s.Parent = G
	end
	install("GardenServer", Enum.RunContext.Server, SERVER)
	install("GardenClient", Enum.RunContext.Client, CLIENT)
	print(string.format("Garden: 4 beds; grow %ss, bush %s acorns every %ss for %s harvests", tostring(G:GetAttribute("GrowSeconds")), tostring(G:GetAttribute("HarvestAcorns")), tostring(G:GetAttribute("HarvestCooldown")), tostring(G:GetAttribute("Harvests"))))
end
