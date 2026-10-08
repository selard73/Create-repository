-- Fountain colour: the Acorn Store's 15-acorn treat (id "bubbles", bought as often as you like). You pick one of
-- six colours in the shop; for the next TEN MINUTES (Minutes, real time, kept if you leave: the moment it ends is
-- stored as the item "fountainuntil") the village fountain runs YOUR colour - every jet and stream tinted, the
-- water in the basin shaded, and coloured bubbles rising off the water and popping - and it does so ON YOUR SCREEN
-- ONLY. Shannon: "I want the bubble and other changes only to show locally on the player's screen, not for all
-- players in the server." Two people can stand at the same fountain and each see their own colour.
--
-- HOW IT IS KEPT: the shop records the chosen colour as the item "fountaincolour" whose COUNT is the palette
-- index (1-6) - the same delta ledger every other item uses, so it survives sessions and merges safely - and
-- the count of "bubbles" bought. The client reads Item_fountaincolour and does everything else itself: Color
-- changes made on a client stay on that client, and parts it creates exist only there.
--
-- The fountain is the saved place's own (workspace.Village.Props.fountain: Stone, Water, eight Jet attachments
-- with Arc emitters, RimStream attachments with Stream emitters); nothing here rebuilds it, and everything is put
-- back if the colour is ever cleared. The palette lives as Colour1..Colour6 attributes on workspace.FountainColour
-- so the shop's swatches and the fountain agree by construction.
-- Re-runnable. Run in edit mode: require(workspace.FountainColour.PatchModule)()
return function(opts)
	opts = opts or {}
	local F = workspace:FindFirstChild("FountainColour")
	if not F then F = Instance.new("Folder"); F.Name = "FountainColour"; F.Parent = workspace end
	local PALETTE = {
		Color3.fromRGB(250, 120, 175),  -- 1 pink (was red - Shannon: "looks like blood in the fountain")
		Color3.fromRGB(240, 140, 50),   -- 2 orange
		Color3.fromRGB(255, 208, 70),   -- 3 gold
		Color3.fromRGB(90, 200, 110),   -- 4 green
		Color3.fromRGB(80, 150, 240),   -- 5 blue
		Color3.fromRGB(170, 100, 220),  -- 6 violet
	}
	for i, c in ipairs(PALETTE) do F:SetAttribute("Colour" .. i, c) end
	F:SetAttribute("Colours", #PALETTE)
	F:SetAttribute("BubbleCount", opts.bubbles or 26)          -- how many are in the air at once
	-- WHERE THEY ARE BORN: the fountain has two waters - the basin (the Water mesh's floor, from the pedestal out to
	-- the rim) and the upper bowl (the RimRing disc). BasinShare of the bubbles come off the basin, the rest off the
	-- bowl. Shannon: "more bubbles coming up from the bottom tier of the fountain too, and more transparent".
	F:SetAttribute("BasinShare", opts.basinShare or 0.35)                 -- "more should come from the top tier"
	-- THE LOOK OF A BUBBLE: Glass at 0.72 picked up whatever stood behind it and went grey (Shannon), so they are
	-- Neon - the colour is its own light, whatever is behind - lifted BubbleTint towards white, half see-through.
	F:SetAttribute("BubbleTransparency", opts.bubbleTransparency or 0.5)
	F:SetAttribute("BubbleMaterial", opts.bubbleMaterial or "Neon")
	F:SetAttribute("BubbleTint", opts.bubbleTint or 0.15)
	F:SetAttribute("Reach", opts.reach or 150)                 -- the bubbles run only while you are this close
	F:SetAttribute("Minutes", opts.minutes or 10)              -- how long a purchase runs; buying again switches colour and restarts it
	-- THE WATERS: the pure colour (WaterBlend 0 = no white in it) seen through at least WaterTransparency - a pastel
	-- at the mesh's own 25% read as milk in the basin (Shannon); tinted water wants saturation and see-through.
	F:SetAttribute("WaterBlend", opts.waterBlend or 0.0)
	F:SetAttribute("WaterTransparency", opts.waterTransparency or 0.5)
	-- THE FLOAT (Shannon: "float softly out away from the fountain and up, not straight up"): each bubble heads
	-- straight out from the middle of the water, give or take BubbleSpread degrees, at BubbleOut studs/s easing
	-- off, while climbing at BubbleUp studs/s and gathering; it lives BubbleLife seconds and wobbles BubbleWobble.
	F:SetAttribute("BubbleOut", opts.bubbleOut or 1.6); F:SetAttribute("BubbleUp", opts.bubbleUp or 1.0)
	F:SetAttribute("BubbleLife", opts.bubbleLife or 5.5); F:SetAttribute("BubbleWobble", opts.bubbleWobble or 0.3)
	F:SetAttribute("BubbleSpread", opts.bubbleSpread or 25)

	local old = F:FindFirstChild("FountainClient"); if old then old:Destroy() end
	local CLIENT = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local F = script.Parent
local function cfgN(name, default) local v = F:GetAttribute(name); return typeof(v) == "number" and v or default end
-- a fresh start: bubbles left by an earlier copy of this script (a hot reload) would hang frozen in the air
for _, old in ipairs(workspace:GetChildren()) do if old.Name == "FountainBubbles_local" then old:Destroy() end end

local function fountain()
	local v = workspace:FindFirstChild("Village")
	local p = v and v:FindFirstChild("Props")
	if not p then return nil end
	for _, m in ipairs(p:GetChildren()) do if m.Name == "fountain" then return m end end
	return nil
end

-- THE TINT. Every emitter under the fountain takes the colour (and a paler version of it, so sprays still read as
-- water catching light); the basin water is shaded towards it. Originals are remembered so clearing the colour
-- restores the fountain exactly.
local original = {}
local function applyColour(idx)
	local fm = fountain(); if not fm then return end
	local col = idx and idx > 0 and F:GetAttribute("Colour" .. idx) or nil
	for _, d in ipairs(fm:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			if original[d] == nil then original[d] = d.Color end
			d.Color = col and ColorSequence.new(col, col:Lerp(Color3.new(1, 1, 1), 0.45)) or original[d]
		end
	end
	-- both waters take the colour itself (WaterBlend towards white; 0 = the pure colour), so the basin and the
	-- bowl read as the same water as the sprays. Shannon: "the water in the bottom tier should be the same color
	-- as the water spraying out" - the old 55% blend from the original left the basin washed out next to the jets.
	for _, name in ipairs({"Water", "RimRing"}) do
		local part = fm:FindFirstChild(name, true)
		if part then
			if original[part] == nil then original[part] = {colour = part.Color, transparency = part.Transparency} end
			part.Color = col and col:Lerp(Color3.new(1, 1, 1), cfgN("WaterBlend", 0)) or original[part].colour
			part.Transparency = col and math.max(original[part].transparency, cfgN("WaterTransparency", 0.5)) or original[part].transparency
		end
	end
end

-- THE BUBBLES. Glass balls in the colour, born small on the water, floating OUT from the middle of the fountain
-- and gently up - out quickly at first and easing off, climbing more as they go - wobbling a little, and popping
-- (a quick fade) at the end of their life. Made here, they exist for this player alone. They run only while the
-- player is near enough to see them. Shannon: "float softly out away from the fountain and up, not straight up."
local folder = Instance.new("Folder"); folder.Name = "FountainBubbles_local"; folder.Parent = workspace
local bubbles = {}
local rng = Random.new()
-- YOUR COLOUR, IF THE CLOCK IS STILL RUNNING: the index in Item_fountaincolour counts only while Item_fountainuntil
-- (server time, seconds) lies ahead; the server clears both a few seconds after it passes, but the client stops
-- on its own the moment it does
local function activeColour()
	local idx = player:GetAttribute("Item_fountaincolour") or 0
	local untilT = player:GetAttribute("Item_fountainuntil") or 0
	return (idx > 0 and untilT > workspace:GetServerTimeNow()) and idx or 0
end
local shownIdx = 0
local function clearBubbles()
	for b in pairs(bubbles) do if b.part then b.part:Destroy() end end
	bubbles = {}
end
-- THE TWO WATERS, read off the fountain itself: the basin's surface is the floor of the Water mesh (measured: a
-- ray from above meets it at -2.9 from the centre, from radius 3.2 out to 5.5), the upper bowl's is the RimRing
-- disc (+2.1, radius 3). The Water mesh's TOP is the bowl, not the basin - the first version spawned everything
-- there, so bubbles hung in the air over the basin.
local function waters(fm)
	local water = fm:FindFirstChild("Water", true)
	if not water then return nil end
	local ring = fm:FindFirstChild("RimRing", true)
	local upperR = ring and (math.max(ring.Size.Y, ring.Size.Z) / 2 - 0.3) or 2.8
	local upperY = ring and (ring.Position.Y + 0.1) or (water.Position.Y + water.Size.Y / 2 + 0.1)
	local basin = {y = water.Position.Y - water.Size.Y / 2 + 0.25, r0 = upperR + 0.4, r1 = math.min(water.Size.X, water.Size.Z) / 2 - 0.6}
	local upper = {y = upperY, r0 = 0.3, r1 = upperR}
	return water.Position, basin, upper
end
local function spawnBubble(fm, col)
	local centre, basin, upper = waters(fm)
	if not centre then return end
	local tier = rng:NextNumber() < cfgN("BasinShare", 0.35) and basin or upper
	local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(tier.r0, tier.r1)
	local size = rng:NextNumber(0.3, 0.7)
	local T = cfgN("BubbleTransparency", 0.5)
	local p = Instance.new("Part"); p.Name = "FountainBubble"; p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.05, 0.05, 0.05); p.Color = col:Lerp(Color3.new(1, 1, 1), cfgN("BubbleTint", 0.15)); p.Transparency = T
	local okM, mat = pcall(function() return Enum.Material[F:GetAttribute("BubbleMaterial") or "Neon"] end)
	p.Material = okM and mat or Enum.Material.Neon
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Position = Vector3.new(centre.X + math.cos(a) * d, tier.y + size / 2, centre.Z + math.sin(a) * d)
	p.Parent = folder
	-- its own heading: straight out from the middle of the water, give or take BubbleSpread degrees
	local yaw = a + math.rad(rng:NextNumber(-1, 1) * cfgN("BubbleSpread", 25))
	bubbles[{part = p, born = os.clock(), life = cfgN("BubbleLife", 5.5) * rng:NextNumber(0.75, 1.25),
		out = cfgN("BubbleOut", 1.6) * rng:NextNumber(0.7, 1.3), up = cfgN("BubbleUp", 1.0) * rng:NextNumber(0.7, 1.3),
		dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw)), side = Vector3.new(-math.sin(yaw), 0, math.cos(yaw)),
		phase = rng:NextNumber(0, 6.28), size = size}] = true
end
local running = false
local function step(dt)
	local fm = fountain(); if not fm then clearBubbles() return end
	local idx = activeColour()
	if idx ~= shownIdx then shownIdx = idx; applyColour(idx) end          -- the clock ran out (or a purchase landed)
	local col = idx > 0 and F:GetAttribute("Colour" .. idx)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	-- WHERE THE FOUNTAIN IS: its bounding box, never its pivot. This model's pivot sits a couple of hundred
	-- studs away in the farm, and a "near" test against it kept the bubbles off for anyone actually beside the
	-- water. (The same trap took the windmill to x 862 once; landmarks by bounding box, always.)
	local here = fm:GetBoundingBox().Position
	local near = root and (root.Position - here).Magnitude < (F:GetAttribute("Reach") or 150)
	if not col or not near then clearBubbles() return end
	local now = os.clock()
	local count = 0
	for b in pairs(bubbles) do
		local age = now - b.born
		if age > b.life or not b.part.Parent then
			b.part:Destroy(); bubbles[b] = nil
		else
			count += 1
			local p = b.part
			local k = age / b.life
			local wob = cfgN("BubbleWobble", 0.3)
			-- out quickly at first and easing off, up gently and gathering: it leaves the water and floats away
			local vel = b.dir * (b.out * (1 - 0.35 * k)) + Vector3.new(0, b.up * (0.6 + 0.8 * k), 0)
				+ b.side * (math.sin(now * 1.9 + b.phase) * wob) + Vector3.new(0, math.cos(now * 1.3 + b.phase) * wob * 0.5, 0)
			p.Position = p.Position + vel * dt
			local s = b.size * math.min(1, age / 0.45)                       -- born small, a soft swell
			p.Size = Vector3.new(s, s, s)
			local T = cfgN("BubbleTransparency", 0.5)
			p.Transparency = T + (1 - T) * math.max(0, k - 0.75) / 0.25      -- fades out in its last quarter
		end
	end
	local want = F:GetAttribute("BubbleCount") or 14
	if count < want and rng:NextNumber() < 0.35 then spawnBubble(fm, col) end
end
RunService.Heartbeat:Connect(step)

local function refresh()
	shownIdx = activeColour()
	applyColour(shownIdx)
end
player:GetAttributeChangedSignal("Item_fountaincolour"):Connect(refresh)
player:GetAttributeChangedSignal("Item_fountainuntil"):Connect(refresh)
task.spawn(function()
	for _ = 1, 120 do if fountain() then break end task.wait(0.5) end
	refresh()
end)
]==]
	local s = Instance.new("Script"); s.Name = "FountainClient"; s.RunContext = Enum.RunContext.Client; s.Source = CLIENT; s.Parent = F

	-- ---------------------------------------------------------------- the server half: the clock ----
	-- Every few seconds, anyone whose colour has run out has both items cleared through the same ledger the shop
	-- used to set them, so the save agrees with what the client already stopped showing.
	local oldS = F:FindFirstChild("FountainServer"); if oldS then oldS:Destroy() end
	local SERVER = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local awardItems = RS:WaitForChild("AwardItems")
while true do
	local now = workspace:GetServerTimeNow()
	for _, p in ipairs(Players:GetPlayers()) do
		local idx = p:GetAttribute("Item_fountaincolour") or 0
		local untilT = p:GetAttribute("Item_fountainuntil") or 0
		if (idx > 0 or untilT > 0) and untilT <= now then
			if idx > 0 then awardItems:Fire(p, "fountaincolour", -idx) end
			if untilT > 0 then awardItems:Fire(p, "fountainuntil", -untilT) end
		end
	end
	task.wait(5)
end
]==]
	local ss = Instance.new("Script"); ss.Name = "FountainServer"; ss.RunContext = Enum.RunContext.Server; ss.Source = SERVER; ss.Parent = F
	print(string.format("FountainColour: %d colours as attributes on workspace.FountainColour | %d bubbles at a time within %d studs | client-only tint and bubbles keyed off Item_fountaincolour",
		#PALETTE, F:GetAttribute("BubbleCount"), F:GetAttribute("Reach")))
	return F
end
