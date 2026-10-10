-- FountainModeClient (workspace.FountainModes, RunContext Client): the Fontana del Limone's bought modes (Shannon, Oct 10
-- 2026). "spaghetti": noodles pour where the water does, the water turns to sauce, smiling meatballs bounce out and roll
-- away. "frogs": the Frog Resort - frogs lounging on lily pads and the rims (sunglasses, a sun hat, a swim ring), lotus
-- flowers, a parasol, a deck chair, a pool ladder, string lights and a sign. "petals": every jet a stream of flower petals
-- and a carpet of them on the water. Bought in the Acorn Store like the French fountain colour: the whole server's fountain
-- for Minutes; ShopServer sets ActiveMode / ActiveUntil / ActiveBy on the folder. Everything here is local to this client
-- and runs only within Reach of the fountain; the fountain itself is never changed - its emitters are switched off locally
-- while noodles or petals run and back on after. Assets (the frog, the flowers) live in ReplicatedStorage.FountainModeAssets.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local F = script.Parent
local cam = workspace.CurrentCamera
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function str(name, d) local v = F:GetAttribute(name) return type(v) == "string" and v or d end
local rng = Random.new()
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

-- ---------- the fountain ----------
local function fountain()
	local node = workspace
	for seg in string.gmatch(str("FountainPath", "PortoNocciola/13 Hillside town/Fontana del Limone"), "[^/]+") do
		node = node and node:FindFirstChild(seg)
	end
	return node
end
-- read off the fountain itself (the same build as the French one, see acorns/build_fountain.lua): the basin's surface is
-- the floor of the Water mesh, the upper bowl is the RimRing disc, the spout is where the Jet attachments are
local function geometry()
	local fm = fountain(); if not fm then return nil end
	local water = fm:FindFirstChild("Water", true)
	local ring = fm:FindFirstChild("RimRing", true)
	local stone = fm:FindFirstChild("Stone", true)
	if not (water and ring) then return nil end
	local c = water.Position
	local g = {fm = fm, water = water, ring = ring, stone = stone, centre = c}
	g.basinY = c.Y - water.Size.Y / 2 + 0.25
	g.bowlR = ring.Size.Y / 2 - 0.2
	g.basinR0 = g.bowlR + 0.6; g.basinR1 = math.min(water.Size.X, water.Size.Z) / 2 - 0.6
	g.bowlY = ring.Position.Y + ring.Size.X / 2
	g.rimY = num("RimY", g.basinY + 1.3); g.rimR = num("RimR", 6.2)   -- the stone rim round the basin (the installer measures it)
	g.groundY = num("GroundY", g.basinY - 1.85)
	local jet = water:FindFirstChild("Jet"); g.spout = jet and jet.WorldPosition or (c + Vector3.new(0, 5.1, 0))
	return g
end
local function near(g)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - g.centre).Magnitude <= num("Reach", 150)
end

-- ---------- helpers ----------
local scene = nil   -- a Folder under the camera holding everything a mode makes on this client
local gen = 0       -- goes up whenever a mode starts or stops; loops check it
local function part(name, size, cf, colour, material, shape)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Size = size; p.CFrame = cf; p.Color = colour; p.Material = material or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = scene
	return p
end
local function around(g, r, a, y) return g.centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r) + Vector3.new(0, y - g.centre.Y, 0) end
local function facing(pos, target) return CFrame.lookAt(pos, Vector3.new(target.X, pos.Y, target.Z)) end
-- sets a model or part down so its underside rests on the frame given (an imported mesh pivots at its middle)
local function sitOn(m, cf)
	m:PivotTo(cf)
	local bb, size
	if m:IsA("Model") then bb, size = m:GetBoundingBox() else bb, size = m.CFrame, m.Size end
	m:PivotTo(cf * CFrame.new(0, cf.Position.Y - (bb.Position.Y - size.Y / 2), 0))
end
local function sound(id, where, volume, speed)
	if not id or id <= 0 or not where then return end
	local s = Instance.new("Sound"); s.SoundId = string.format("rbxassetid://%d", id); s.Volume = volume or 0.6; s.PlaybackSpeed = speed or 1; s.RollOffMaxDistance = 80; s.Parent = where; s:Play(); Debris:AddItem(s, 8)
end
-- the water's own emitters, switched off on this client while noodles or petals pour, and back on after
local waterOff = {}
local function setWater(g, on)
	for _, d in ipairs(g.water:GetDescendants()) do
		if d:IsA("ParticleEmitter") and (d.Name == "Arc" or d.Name == "Stream") then
			if on then d.Enabled = false; waterOff[d] = true end
		end
	end
	if not on then for d in pairs(waterOff) do if d.Parent then d.Enabled = true end end; waterOff = {} end
end
local waterLook = nil
local function tintWater(g, colour, transparency)
	if not waterLook then waterLook = {wc = g.water.Color, wt = g.water.Transparency, rc = g.ring.Color, rt = g.ring.Transparency, rm = g.ring.Material} end
	g.water.Color = colour; g.water.Transparency = transparency; g.ring.Color = colour; g.ring.Transparency = transparency
end
local function untintWater(g)
	if not waterLook then return end
	g.water.Color = waterLook.wc; g.water.Transparency = waterLook.wt; g.ring.Color = waterLook.rc; g.ring.Transparency = waterLook.rt; g.ring.Material = waterLook.rm
	waterLook = nil
end

-- ---------- petals ----------
local PETALS = {Color3.fromRGB(255, 110, 150), Color3.fromRGB(228, 52, 78), Color3.fromRGB(255, 242, 236), Color3.fromRGB(250, 190, 70), Color3.fromRGB(242, 140, 190)}
local function petalTexture() local t = str("PetalTexture", ""); return t ~= "" and t or "rbxasset://textures/particles/smoke_main.dds" end
local function petalEmitter(src, i)
	-- a clone of the water's own emitter (so it flies the same arc), made petals
	local e = src:Clone(); e.Name = "PetalStream"
	e.Texture = petalTexture()
	e.Color = ColorSequence.new(PETALS[(i % #PETALS) + 1])
	e.LightEmission = 0.05; e.LightInfluence = 0.5
	e.Size = NumberSequence.new(num("PetalSize", 0.55))
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1)})
	-- slow and dreamy (Shannon: "the petals are a blur, falling too quickly"): they leave the jets at a fraction of the water's
	-- speed, fall under a gentle pull against air drag, and drift for seconds, turning slowly
	local k = num("PetalSpeed", 0.4)
	e.Speed = NumberRange.new(src.Speed.Min * k, src.Speed.Max * k)
	e.Acceleration = Vector3.new(0, -num("PetalFall", 5), 0)
	e.Drag = num("PetalDrag", 1.2)
	local life = num("PetalLife", 3.2) * (src.Name == "Stream" and 0.6 or 1)   -- about the time to drift down to the water; the rim streams have less far to go
	e.Lifetime = NumberRange.new(life, life * 1.4)
	e.Rate = src.Rate * num("PetalRate", 0.3)
	e.Rotation = NumberRange.new(0, 360); e.RotSpeed = NumberRange.new(-110, 110)
	e.Orientation = Enum.ParticleOrientation.FacingCamera
	e.Squash = NumberSequence.new(str("PetalTexture", "") ~= "" and 0 or 0.6)
	e.Enabled = true
	e.Parent = src.Parent
	return e
end
local function carpet(g, n, r0, r1, y, size)
	-- petals lying on the water (and a few on the paving): thin flat ovals, bobbing a little
	local list = {}
	for i = 1, n do
		local a, r = rng:NextNumber(0, 2 * math.pi), math.sqrt(rng:NextNumber(r0 * r0, r1 * r1))
		local p = part("Petal", Vector3.new(0.04, size, size * 0.7), CFrame.new(around(g, r, a, y + 0.03)) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0), PETALS[rng:NextInteger(1, #PETALS)], Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		p.CFrame = CFrame.new(around(g, r, a, y + 0.03)) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), math.rad(90))
		list[i] = {p = p, cf = p.CFrame, ph = rng:NextNumber(0, 6)}
	end
	return list
end
local function startPetals(g)
	setWater(g, true)
	local emitters = {}
	local i = 0
	for _, d in ipairs(g.water:GetDescendants()) do
		if d:IsA("ParticleEmitter") and (d.Name == "Arc" or d.Name == "Stream") then i += 1; table.insert(emitters, petalEmitter(d, i)) end
	end
	local floating = carpet(g, num("CarpetCount", 90), g.basinR0, g.basinR1, g.basinY, 0.5)
	for _, e in ipairs(carpet(g, 22, 0.6, g.bowlR - 0.3, g.bowlY, 0.42)) do table.insert(floating, e) end
	for _, e in ipairs(carpet(g, 30, g.rimR + 0.6, g.rimR + 3.2, g.groundY, 0.45)) do table.insert(floating, e) end
	local my = gen
	task.spawn(function()
		while gen == my do
			local t = os.clock()
			for _, e in ipairs(floating) do if e.p.Parent then e.p.CFrame = e.cf + Vector3.new(0, 0.04 * math.sin(t * 1.3 + e.ph), 0) end end
			RunService.RenderStepped:Wait()
		end
		for _, e in ipairs(emitters) do e:Destroy() end
	end)
end

-- ---------- spaghetti ----------
-- Shannon (Oct 10, after the first look): "it should be individual pasta pieces coming out and falling down like the water
-- does" and the pink sauce "looks gruesome". So: the water's own emitters cloned into streams of noodle pieces (long, thin,
-- along the way they fly), real strands tossed out of the spout that tumble, land and fade, meatballs the same way, and
-- an opaque tomato-orange sauce in the basin and the bowl.
local NOODLE = Color3.fromRGB(242, 216, 140)
local SAUCE = Color3.fromRGB(198, 70, 32)
local function noodleEmitter(src, i)
	local e = src:Clone(); e.Name = "NoodleStream"
	local tex = str("NoodleTexture", "")
	e.Texture = tex ~= "" and tex or "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(NOODLE:Lerp(Color3.fromRGB(255, 236, 170), (i % 3) * 0.3))
	e.LightEmission = 0.05; e.LightInfluence = 0.6
	e.Size = NumberSequence.new(num("NoodleWidth", 0.24))
	e.Squash = NumberSequence.new(num("NoodleStretch", 5))   -- long and thin along the way it flies: a piece of spaghetti
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(src.Lifetime.Min * 1.9, src.Lifetime.Max * 2.2)
	e.Rate = src.Rate * num("NoodleRate", 0.5)
	e.Rotation = NumberRange.new(0); e.RotSpeed = NumberRange.new(0)
	e.Enabled = true
	e.Parent = src.Parent
	return e
end
-- something tossed out of the spout: a hop into the bowl, one into the basin, one out over the rim, a roll, a rest, a fade
local function toss(obj, g, spinAxis)
	local a = rng:NextNumber(0, 2 * math.pi)
	local hops = {
		{p = around(g, rng:NextNumber(1.2, g.bowlR - 0.4), a, g.bowlY + 0.45), h = rng:NextNumber(3.5, 5), T = 0.75},
		{p = around(g, rng:NextNumber(g.basinR0 + 0.2, g.basinR1 - 0.2), a + rng:NextNumber(-0.5, 0.5), g.basinY + 0.45), h = rng:NextNumber(1.6, 2.4), T = 0.6},
		{p = around(g, rng:NextNumber(g.rimR + 1.2, g.rimR + 3.5), a + rng:NextNumber(-0.7, 0.7), g.groundY + 0.45), h = rng:NextNumber(1.4, 2.2), T = 0.65},
	}
	hops[4] = {p = hops[3].p + Vector3.new(math.cos(a) * 1.5, 0, math.sin(a) * 1.5), h = 0.5, T = 0.4}   -- a last little roll outward
	local my = gen
	task.spawn(function()
		local from = g.spout
		local tumble = CFrame.Angles(rng:NextNumber(-3, 3), rng:NextNumber(-3, 3), 0)
		for _, hop in ipairs(hops) do
			local t0 = os.clock()
			while true do
				local t = (os.clock() - t0) / hop.T
				if t >= 1 or gen ~= my or not obj.Parent then break end
				local pos = from:Lerp(hop.p, t) + Vector3.new(0, 4 * hop.h * t * (1 - t), 0)
				obj:PivotTo(CFrame.new(pos) * CFrame.Angles(0, a, 0) * CFrame.fromAxisAngle(spinAxis, -t * 4) * tumble)
				RunService.RenderStepped:Wait()
			end
			if gen ~= my or not obj.Parent then break end
			obj:PivotTo(facing(hop.p, g.centre))
			from = hop.p
			sound(num("BounceSoundId", 0), obj:IsA("Model") and obj.PrimaryPart or obj, 0.35)
		end
		if obj.Parent and gen == my then
			obj:PivotTo(facing(from, g.centre))   -- sits looking at the fountain
			task.wait(2.5)
			if obj.Parent then
				for _, d in ipairs(obj:IsA("Model") and obj:GetDescendants() or {obj}) do
					if d:IsA("BasePart") then TweenService:Create(d, TweenInfo.new(0.7), {Transparency = 1}):Play() end
					if d:IsA("Decal") then TweenService:Create(d, TweenInfo.new(0.7), {Transparency = 1}):Play() end
				end
				if obj:IsA("BasePart") then for _, d in ipairs(obj:GetChildren()) do if d:IsA("Decal") then TweenService:Create(d, TweenInfo.new(0.7), {Transparency = 1}):Play() end end end
			end
			Debris:AddItem(obj, 0.8)
		end
	end)
end
local function meatball(g)
	local m = part("Meatball", Vector3.new(0.95, 0.95, 0.95), CFrame.new(g.spout), Color3.fromRGB(118, 68, 40), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local face = Instance.new("Decal"); face.Name = "Smile"; face.Texture = "rbxasset://textures/face.png"; face.Face = Enum.NormalId.Front; face.Parent = m
	toss(m, g, Vector3.xAxis)
end
local function strand(g)
	-- a real strand: five short lengths in a gentle wave, pale yellow, tossed like the meatballs
	local m = Instance.new("Model"); m.Name = "Strand"
	local colour = NOODLE:Lerp(Color3.fromRGB(255, 236, 170), rng:NextNumber(0, 0.6))
	local segLen, prev = 0.55, nil
	for i = 1, 5 do
		local seg = Instance.new("Part"); seg.Name = "Seg"; seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false; seg.CastShadow = false
		seg.Shape = Enum.PartType.Cylinder; seg.Size = Vector3.new(segLen + 0.08, 0.13, 0.13); seg.Color = colour; seg.Material = Enum.Material.SmoothPlastic
		local bend = 0.35 * math.sin(i * 1.3)
		seg.CFrame = CFrame.new((i - 3) * segLen, 0.12 * math.sin(i * 1.3), 0) * CFrame.Angles(0, 0, bend)
		seg.Parent = m
		if i == 1 then m.PrimaryPart = seg end
	end
	m:PivotTo(CFrame.new(g.spout))
	m.Parent = scene
	toss(m, g, Vector3.zAxis)
end
local function startSpaghetti(g)
	setWater(g, true)
	-- the sauce: opaque tomato orange-red (a tint over the water read as pink - Shannon: "gruesome")
	tintWater(g, SAUCE, 0)
	g.ring.Material = Enum.Material.SmoothPlastic
	-- the pour: the water's own emitters, as noodle pieces
	local emitters = {}
	local i = 0
	for _, d in ipairs(g.water:GetDescendants()) do
		if d:IsA("ParticleEmitter") and (d.Name == "Arc" or d.Name == "Stream") then i += 1; table.insert(emitters, noodleEmitter(d, i)) end
	end
	-- a dusting of parmesan over the spout
	local jet = g.water:FindFirstChild("Jet")
	if jet then
		local e = Instance.new("ParticleEmitter"); e.Name = "Parmesan"; e.Texture = "rbxasset://textures/particles/smoke_main.dds"; e.Color = ColorSequence.new(Color3.fromRGB(255, 250, 230))
		e.Size = NumberSequence.new(0.14); e.Lifetime = NumberRange.new(1.2, 1.8); e.Rate = 10; e.Speed = NumberRange.new(2, 4); e.SpreadAngle = Vector2.new(60, 60)
		e.Acceleration = Vector3.new(0, -6, 0); e.LightEmission = 0.3; e.Parent = jet
		table.insert(emitters, e)
	end
	local my = gen
	task.spawn(function()
		task.wait(0.6)
		local nextBall, nextStrand = os.clock() + 1.2, os.clock()
		while gen == my do
			local t = os.clock()
			if t >= nextStrand then strand(g); nextStrand = t + num("StrandEvery", 0.45) + rng:NextNumber(0, 0.25) end
			if t >= nextBall then meatball(g); nextBall = t + num("MeatballEvery", 1.6) + rng:NextNumber(-0.3, 0.5) end
			task.wait(0.1)
		end
		for _, e in ipairs(emitters) do e:Destroy() end
	end)
end

-- ---------- the frog resort ----------
local assets = RS:FindFirstChild("FountainModeAssets")
local function asset(name) return assets and assets:FindFirstChild(name, true) end
local function frog(cf, scale, accessory)
	-- a frog from the imported model: Body, EyeL, EyeR, and one of Sunglasses / SunHat / SwimRing (the others go)
	local src = asset("Frog"); if not src then return nil end
	local m = src:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
			if (d.Name == "Sunglasses" or d.Name == "SunHat" or d.Name == "SwimRing") and d.Name ~= accessory then d:Destroy() end
		end
	end
	pcall(m.ScaleTo, m, scale or 1)
	sitOn(m, cf); m.Parent = scene
	return m
end
local function lilyPad(cf, withLotus)
	local pad = asset("LilyPad")
	local p
	if pad then p = pad:Clone(); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; sitOn(p, cf); p.Parent = scene
	else p = part("LilyPad", Vector3.new(0.08, 1.6, 1.6), cf * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 150, 70), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder) end
	if withLotus then
		local l = asset("Lotus")
		if l then local c = l:Clone(); for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false end end; sitOn(c, cf * CFrame.new(0, 0.1, 0)); c.Parent = scene end
	end
	return p
end
local function parasol(g, pos)
	local wood = Color3.fromRGB(150, 110, 70)
	part("ParasolPole", Vector3.new(0.14, 6.2, 0.14), CFrame.new(pos + Vector3.new(0, 3.1, 0)), wood, Enum.Material.Wood)
	local top = part("ParasolTop", Vector3.new(4.6, 1.3, 4.6), CFrame.new(pos + Vector3.new(0, 5.9, 0)), Color3.fromRGB(245, 125, 105), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	part("ParasolKnob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos + Vector3.new(0, 6.6, 0)), Color3.fromRGB(255, 246, 220), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	for i = 0, 7 do   -- white panels on the canopy
		local a = i * math.pi / 4
		part("ParasolStripe", Vector3.new(0.5, 1.1, 2.0), CFrame.new(pos + Vector3.new(math.cos(a) * 1.25, 5.95, math.sin(a) * 1.25)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(255, 246, 230))
	end
	return top
end
local function deckChair(g, cf)
	local wood, cloth = Color3.fromRGB(170, 125, 80), Color3.fromRGB(120, 180, 230)
	part("ChairSeat", Vector3.new(1.6, 0.12, 1.5), cf * CFrame.new(0, 0.55, 0) * CFrame.Angles(math.rad(-8), 0, 0), cloth)
	part("ChairBack", Vector3.new(1.6, 0.12, 1.5), cf * CFrame.new(0, 1.25, -0.95) * CFrame.Angles(math.rad(55), 0, 0), cloth)
	for _, x in ipairs({-0.8, 0.8}) do
		part("ChairRail", Vector3.new(0.1, 0.1, 2.1), cf * CFrame.new(x, 0.62, -0.1) * CFrame.Angles(math.rad(-8), 0, 0), wood, Enum.Material.Wood)
		part("ChairLeg", Vector3.new(0.1, 0.6, 0.1), cf * CFrame.new(x, 0.3, 0.6), wood, Enum.Material.Wood)
		part("ChairLeg", Vector3.new(0.1, 0.6, 0.1), cf * CFrame.new(x, 0.3, -0.7), wood, Enum.Material.Wood)
	end
end
local function ladder(g, a)
	-- a pool ladder hooked over the basin's rim
	local chrome = Color3.fromRGB(205, 210, 215)
	local base = around(g, g.rimR, a, g.rimY)
	local outward = Vector3.new(math.cos(a), 0, math.sin(a))
	local side = Vector3.new(-math.sin(a), 0, math.cos(a))
	for _, s in ipairs({-0.45, 0.45}) do
		local o = side * s
		part("LadderRail", Vector3.new(0.12, 2.6, 0.12), CFrame.new(base + o + outward * 0.5 - Vector3.new(0, 1.0, 0)), chrome, Enum.Material.Metal)
		local hp = base + o + Vector3.new(0, 0.35, 0); part("LadderHoop", Vector3.new(0.12, 0.12, 1.2), CFrame.lookAt(hp, hp + outward), chrome, Enum.Material.Metal)
		part("LadderRail", Vector3.new(0.12, 1.4, 0.12), CFrame.new(base + o - outward * 0.5 - Vector3.new(0, 0.4, 0)), chrome, Enum.Material.Metal)
	end
	for i = 0, 2 do local rp = base + outward * 0.5 - Vector3.new(0, 0.3 + i * 0.6, 0); part("LadderRung", Vector3.new(1.0, 0.1, 0.1), CFrame.lookAt(rp, rp + outward), chrome, Enum.Material.Metal) end
end
local function sign(g, pos, facingPos)
	local wood = Color3.fromRGB(150, 105, 60)
	part("SignPost", Vector3.new(0.18, 3.2, 0.18), CFrame.new(pos + Vector3.new(0, 1.6, 0)), wood, Enum.Material.Wood)
	local plank = part("SignPlank", Vector3.new(3.0, 1.1, 0.16), facing(pos + Vector3.new(0, 2.9, 0), facingPos) * CFrame.Angles(0, 0, math.rad(-4)), Color3.fromRGB(190, 140, 85), Enum.Material.Wood)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(600, 220); sg.LightInfluence = 0.4; sg.Parent = plank
	local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextScaled = true; l.TextColor3 = Color3.fromRGB(255, 246, 220); l.TextStrokeTransparency = 0.6; l.Text = str("SignText", "FROG RESORT"); l.Parent = sg
	local sg2 = sg:Clone(); sg2.Face = Enum.NormalId.Back; sg2.Parent = plank
end
local function stringLights(g, from, to, n)
	local lights = {}
	for i = 0, n do
		local t = i / n
		local p = from:Lerp(to, t) - Vector3.new(0, 1.6 * math.sin(t * math.pi), 0)
		if i > 0 and i < n then
			local b = part("Bulb", Vector3.new(0.28, 0.28, 0.28), CFrame.new(p), Color3.fromRGB(255, 220, 140), Enum.Material.Neon, Enum.PartType.Ball)
			local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 220, 150); l.Brightness = 0.6; l.Range = 6; l.Shadows = false; l.Parent = b
			table.insert(lights, b)
		end
		if i > 0 then
			local q = from:Lerp(to, (i - 1) / n) - Vector3.new(0, 1.6 * math.sin((i - 1) / n * math.pi), 0)
			part("Wire", Vector3.new(0.04, 0.04, (p - q).Magnitude), CFrame.lookAt((p + q) / 2, p), Color3.fromRGB(60, 50, 40))
		end
	end
	return lights
end
local function startFrogs(g)
	local frogs = {}
	local function add(m, kind) if m then table.insert(frogs, {m = m, home = m:GetPivot(), kind = kind, ph = rng:NextNumber(0, 6)}) end end
	-- the pond: lily pads on the basin, some with lotus flowers, some with frogs
	local pads = {}
	for i, spec in ipairs({{a = 0.4, r = 4.3, frog = "Sunglasses", scale = 1.0}, {a = 1.7, r = 4.5, lotus = true}, {a = 2.5, r = 4.0, frog = "", scale = 0.8}, {a = 3.6, r = 4.6, lotus = true}, {a = 4.4, r = 4.2}, {a = 5.3, r = 4.5, frog = "", scale = 1.1}, {a = 6.0, r = 4.0, lotus = true}}) do
		local pos = around(g, spec.r, spec.a, g.basinY)
		local pad = lilyPad(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), spec.lotus)
		table.insert(pads, {p = pad, cf = pad:GetPivot(), ph = rng:NextNumber(0, 6)})   -- (GetPivot after sitOn: where it rests)
		if spec.frog then add(frog(facing(pos + Vector3.new(0, 0.1, 0), g.centre) * CFrame.Angles(0, math.pi + rng:NextNumber(-0.6, 0.6), 0), spec.scale, spec.frog), "pad") end
	end
	-- in the water, in a swim ring; two on the rim, one in a sun hat
	add(frog(facing(around(g, 4.4, 3.1, g.basinY + 0.15), g.centre), 1.0, "SwimRing"), "swim")
	add(frog(facing(around(g, g.rimR - 0.2, 1.2, g.rimY), g.centre) * CFrame.Angles(0, math.pi, 0), 1.0, "SunHat"), "rim")
	add(frog(facing(around(g, g.rimR - 0.2, 4.9, g.rimY), g.centre), 0.9, ""), "rim")
	-- one up top, by the spout
	add(frog(facing(g.spout + Vector3.new(0.9, 0.05, 0.2), g.centre + Vector3.new(0, 20, 0)), 0.7, ""), "top")
	-- the deck: a parasol, a deck chair with a frog in it and a drink, the sign, a ladder, string lights
	local deckA = num("DeckAngle", 0.9)
	local deckPos = around(g, g.rimR + 3.6, deckA, g.groundY)
	parasol(g, deckPos + Vector3.new(math.cos(deckA + 1.5) * 1.4, 0, math.sin(deckA + 1.5) * 1.4))
	local chairCF = facing(deckPos, g.centre) * CFrame.Angles(0, math.pi, 0)
	deckChair(g, chairCF)
	add(frog(chairCF * CFrame.new(0, 0.62, 0.1) * CFrame.Angles(math.rad(-20), 0, 0), 1.0, "SunHat"), "chair")
	local glassPos = deckPos + Vector3.new(math.cos(deckA - 1.5) * 1.3, 0, math.sin(deckA - 1.5) * 1.3)
	part("DrinkTable", Vector3.new(0.08, 0.9, 0.9), CFrame.new(glassPos + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(170, 125, 80), Enum.Material.Wood, Enum.PartType.Cylinder)
	part("DrinkTable", Vector3.new(0.08, 0.9, 0.08), CFrame.new(glassPos + Vector3.new(0, 0.45, 0)), Color3.fromRGB(170, 125, 80), Enum.Material.Wood)
	local glass = part("Drink", Vector3.new(0.5, 0.34, 0.34), CFrame.new(glassPos + Vector3.new(0, 1.2, 0)), Color3.fromRGB(255, 160, 120), Enum.Material.Glass, Enum.PartType.Cylinder); glass.Transparency = 0.25
	glass.CFrame = glass.CFrame * CFrame.Angles(0, 0, math.rad(90))
	part("Straw", Vector3.new(0.05, 0.7, 0.05), CFrame.new(glassPos + Vector3.new(0.08, 1.45, 0)) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(255, 80, 90))
	sign(g, around(g, g.rimR + 2.4, deckA - 1.1, g.groundY), g.centre + (around(g, g.rimR + 14, deckA - 1.1, g.groundY) - g.centre))
	ladder(g, deckA + 2.4)
	for _, a in ipairs({deckA - 2.2, deckA + 1.1}) do
		local postPos = around(g, g.rimR + 3.0, a, g.groundY)
		part("LightPost", Vector3.new(0.16, 7.5, 0.16), CFrame.new(postPos + Vector3.new(0, 3.75, 0)), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
		stringLights(g, postPos + Vector3.new(0, 7.4, 0), g.spout + Vector3.new(0, 1.2, 0), 12)
	end
	-- life: the swim ring bobs, the pads sway, now and then a frog hops and croaks
	local my = gen
	task.spawn(function()
		local nextHop = os.clock() + 2
		local hopping = nil
		while gen == my do
			local t = os.clock()
			for _, e in ipairs(pads) do if e.p.Parent then e.p:PivotTo(e.cf + Vector3.new(0, 0.05 * math.sin(t * 1.1 + e.ph), 0)) end end
			for _, f in ipairs(frogs) do
				if f.m.Parent and f ~= hopping then
					if f.kind == "swim" then f.m:PivotTo(f.home * CFrame.new(0, 0.08 * math.sin(t * 1.4 + f.ph), 0) * CFrame.Angles(0.04 * math.sin(t * 0.9 + f.ph), 0, 0.05 * math.sin(t * 1.2)))
					elseif f.kind == "pad" then f.m:PivotTo(f.home + Vector3.new(0, 0.05 * math.sin(t * 1.1 + f.ph), 0)) end
				end
			end
			if t > nextHop and #frogs > 0 then
				nextHop = t + rng:NextNumber(2.5, 6)
				local f = frogs[rng:NextInteger(1, #frogs)]
				if f.m.Parent and f.kind ~= "chair" and f.kind ~= "swim" then
					hopping = f
					-- the croak, answered by others round the pond (Shannon: "the same sound several times over so it sounds like there are more of them")
					local croak = num("FrogSoundId", 73626983091367)
					sound(croak, f.m.PrimaryPart or f.m:FindFirstChildWhichIsA("BasePart"), 0.5, rng:NextNumber(0.9, 1.1))
					for k = 1, rng:NextInteger(1, 3) do
						local other = frogs[rng:NextInteger(1, #frogs)]
						task.delay(0.15 + k * rng:NextNumber(0.2, 0.5), function() if gen == my and other.m.Parent then sound(croak, other.m.PrimaryPart or other.m:FindFirstChildWhichIsA("BasePart"), 0.35, rng:NextNumber(0.8, 1.25)) end end)
					end
					task.spawn(function()
						local t0 = os.clock()
						while os.clock() - t0 < 0.5 and gen == my and f.m.Parent do
							local k = (os.clock() - t0) / 0.5
							f.m:PivotTo(f.home + Vector3.new(0, 1.6 * k * (1 - k), 0))
							RunService.RenderStepped:Wait()
						end
						if f.m.Parent then f.m:PivotTo(f.home) end
						if hopping == f then hopping = nil end
					end)
				end
			end
			RunService.RenderStepped:Wait()
		end
	end)
	if not asset("Frog") then warn("FountainModes: no Frog in ReplicatedStorage.FountainModeAssets - the resort has no frogs yet") end
end

-- ---------- running the modes ----------
local current = nil
local function stop(g)
	gen += 1
	if scene then scene:Destroy(); scene = nil end
	if g then
		for _, d in ipairs(g.water:GetDescendants()) do if d.Name == "PetalStream" or d.Name == "NoodleStream" or d.Name == "Parmesan" then d:Destroy() end end
		setWater(g, false); untintWater(g)
	end
	current = nil
end
local function start(g, mode)
	gen += 1
	scene = Instance.new("Folder"); scene.Name = "FountainMode_" .. mode; scene.Parent = cam
	current = mode
	if mode == "petals" then startPetals(g) elseif mode == "spaghetti" then startSpaghetti(g) elseif mode == "frogs" then startFrogs(g) end
end
local lastG = nil
while true do
	local mode = str("ActiveMode", "")
	local untilT = num("ActiveUntil", 0)
	local g = geometry()
	local want = (g and mode ~= "" and untilT > workspace:GetServerTimeNow() and near(g)) and mode or nil
	if want ~= current then
		if current then stop(lastG or g) end
		if want then start(g, want); lastG = g end
	end
	task.wait(0.5)
end
