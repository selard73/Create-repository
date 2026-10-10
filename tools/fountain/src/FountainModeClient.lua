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
	if not waterLook then waterLook = {wc = g.water.Color, wt = g.water.Transparency, rc = g.ring.Color, rt = g.ring.Transparency, rm = g.ring.Material, wm = g.water.Material, wr = g.water.Reflectance, rr = g.ring.Reflectance} end
	g.water.Color = colour; g.water.Transparency = transparency; g.ring.Color = colour; g.ring.Transparency = transparency
end
local function untintWater(g)
	if not waterLook then return end
	g.water.Color = waterLook.wc; g.water.Transparency = waterLook.wt; g.water.Material = waterLook.wm; g.water.Reflectance = waterLook.wr
	g.ring.Color = waterLook.rc; g.ring.Transparency = waterLook.rt; g.ring.Material = waterLook.rm; g.ring.Reflectance = waterLook.rr
	waterLook = nil
end

-- ---------- petals ----------
-- Shannon (Oct 10, twice): the particle petals were "a blurry mess ... not individual petals falling down". So the petals are
-- real little shapes now: flat ovals that fly out of the jets and over the bowl's rim, tumble and sway as they drift down
-- against the air, land on the water, the stone or the paving, rest a moment and fade. A carpet of them lies on the water.
local PETALS = {Color3.fromRGB(255, 110, 150), Color3.fromRGB(228, 52, 78), Color3.fromRGB(255, 242, 236), Color3.fromRGB(250, 190, 70), Color3.fromRGB(242, 140, 190)}
local assetsFolder = RS:FindFirstChild("FountainModeAssets")
local petalMeshes = nil   -- the real petal shapes (Petal_A/B/C, modelled in Blender), once imported
local function petalPart(size)
	if petalMeshes == nil then
		petalMeshes = {}
		assetsFolder = assetsFolder or RS:FindFirstChild("FountainModeAssets")
		if assetsFolder then for _, n in ipairs({"Petal_A", "Petal_B", "Petal_C"}) do local m = assetsFolder:FindFirstChild(n, true); if m and m:IsA("BasePart") then table.insert(petalMeshes, m) end end end
	end
	local p
	if #petalMeshes > 0 then
		p = petalMeshes[rng:NextInteger(1, #petalMeshes)]:Clone()
		p.Name = "Petal"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Size = p.Size * (size / 0.5)
	else
		p = Instance.new("Part"); p.Name = "Petal"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Shape = Enum.PartType.Cylinder; p.Size = Vector3.new(0.04, size, size * 0.68); p.Material = Enum.Material.SmoothPlastic
	end
	p.Color = PETALS[rng:NextInteger(1, #PETALS)]
	p.Parent = scene
	return p
end
-- a flat oval Part has its axis along X and is rolled flat; a petal mesh already lies flat
local FLAT_PART = CFrame.Angles(0, 0, math.rad(90))
local function flat(p) return (p:IsA("MeshPart")) and CFrame.identity or FLAT_PART end
local function carpet(g, n, r0, r1, y, size)
	local list = {}
	for i = 1, n do
		local a, r = rng:NextNumber(0, 2 * math.pi), math.sqrt(rng:NextNumber(r0 * r0, r1 * r1))
		local p = petalPart(size)
		p.CFrame = CFrame.new(around(g, r, a, y + 0.03)) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0) * flat(p)
		list[i] = {p = p, cf = p.CFrame, ph = rng:NextNumber(0, 6)}
	end
	return list
end
-- where a falling petal comes to rest under a point: the bowl, the basin water, the stone rim, or the paving
local function restY(g, pos)
	local r = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(g.centre.X, 0, g.centre.Z)).Magnitude
	if r < g.bowlR then return g.bowlY
	elseif r < g.basinR1 + 0.3 then return g.basinY
	elseif r < g.rimR + 0.7 then return g.rimY
	else return g.groundY end
end
local function startPetals(g)
	setWater(g, true)
	local floating = carpet(g, num("CarpetCount", 90), g.basinR0, g.basinR1, g.basinY, 0.5)
	for _, e in ipairs(carpet(g, 22, 0.6, g.bowlR - 0.3, g.bowlY, 0.42)) do table.insert(floating, e) end
	for _, e in ipairs(carpet(g, 30, g.rimR + 0.6, g.rimR + 3.2, g.groundY, 0.45)) do table.insert(floating, e) end
	-- the rim stream points: where the water pours over the bowl's edge
	local rimPts = {}
	for _, d in ipairs(g.water:GetChildren()) do if d:IsA("Attachment") and d.Name == "RimStream" then table.insert(rimPts, d.WorldPosition) end end
	if #rimPts == 0 then for i = 1, 12 do table.insert(rimPts, around(g, g.bowlR + 0.1, i / 12 * 2 * math.pi, g.bowlY + 0.1)) end end
	local live = {}
	local function launch(fromTop)
		local p = petalPart(rng:NextNumber(0.42, 0.6))
		local pos, v
		if fromTop then
			local th, ph = math.rad(rng:NextNumber(0, num("PetalSpread", 38))), rng:NextNumber(0, 2 * math.pi)
			local sp = rng:NextNumber(num("PetalSpeedMin", 5), num("PetalSpeedMax", 8.5))
			pos = g.spout + Vector3.new(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))
			v = Vector3.new(math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)) * sp
		else
			pos = rimPts[rng:NextInteger(1, #rimPts)]
			local out = Vector3.new(pos.X - g.centre.X, 0, pos.Z - g.centre.Z); out = out.Magnitude > 0.01 and out.Unit or Vector3.xAxis
			v = out * rng:NextNumber(1.0, 2.2) + Vector3.new(0, rng:NextNumber(0.2, 0.9), 0)
		end
		table.insert(live, {p = p, pos = pos, v = v, t = 0, axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit, spin = rng:NextNumber(2, 6), yaw = rng:NextNumber(0, 6), ph = rng:NextNumber(0, 6), sway = rng:NextNumber(0.25, 0.6)})
	end
	local my = gen
	task.spawn(function()
		local acc = 0
		while gen == my do
			local dt = RunService.RenderStepped:Wait()
			dt = math.min(dt, 0.05)
			local t = os.clock()
			for _, e in ipairs(floating) do if e.p.Parent then e.p.CFrame = e.cf + Vector3.new(0, 0.04 * math.sin(t * 1.3 + e.ph), 0) end end
			-- new petals: a shower from the spout, a trickle over the rim, up to a ceiling
			acc += dt * num("PetalsPerSecond", 34)
			while acc >= 1 and #live < num("PetalMax", 240) do acc -= 1; launch(rng:NextNumber() < 0.72) end
			local pull, drag = num("PetalFall", 5), num("PetalDrag", 1.2)
			for i = #live, 1, -1 do
				local e = live[i]
				if not e.p.Parent then table.remove(live, i)
				elseif e.rest then
					e.t += dt
					if e.t > num("PetalRest", 2.6) then
						TweenService:Create(e.p, TweenInfo.new(0.8), {Transparency = 1}):Play(); Debris:AddItem(e.p, 0.9); table.remove(live, i)
					end
				else
					e.t += dt
					e.v = e.v + Vector3.new(0, -pull, 0) * dt - e.v * drag * dt
					e.pos = e.pos + e.v * dt
					local sway = Vector3.new(math.sin(e.t * 3 + e.ph), 0, math.cos(e.t * 2.3 + e.ph)) * e.sway * dt * 2
					e.pos = e.pos + sway
					local floor = restY(g, e.pos)
					if e.pos.Y <= floor + 0.03 and e.v.Y < 0 then
						e.rest = true; e.t = 0
						e.p.CFrame = CFrame.new(Vector3.new(e.pos.X, floor + 0.03, e.pos.Z)) * CFrame.Angles(0, e.yaw, 0) * flat(e.p)
					elseif e.t > 7 then
						e.p:Destroy(); table.remove(live, i)
					else
						e.p.CFrame = CFrame.new(e.pos) * CFrame.fromAxisAngle(e.axis, e.spin * e.t) * CFrame.Angles(0, e.yaw, 0) * flat(e.p)
					end
				end
			end
		end
	end)
end

-- ---------- spaghetti ----------
-- Shannon (Oct 10, fourth look): "spaghetti is long strands" (not short pieces in a row), the meatballs "textured, and
-- sinking into the sauce", the sauce "thick liquid", not a slab. So: each strand is one long continuous tube - overlapping
-- pieces that merge - running from the spout over the bowl's edge and down into the basin (and some over the outer rim onto
-- the paving), sliding down at a stud a second with a slow wobble travelling along it, emerging at the top and melting into
-- the sauce at the bottom. The sauce is glossy, a little see-through, with mince and herb in it, slow bubbles rising and
-- popping, and steam. Meatballs are rough-textured and sit sunk into the sauce; now and then one rolls slowly down a strand.
local NOODLE = Color3.fromRGB(242, 216, 140)
local SAUCE = Color3.fromRGB(150, 48, 26)
local MINCE = Color3.fromRGB(92, 44, 26)
local MEAT = Color3.fromRGB(112, 62, 36)
local function curve(p0, p1, p2) return function(u) local x = p0:Lerp(p1, u); local y = p1:Lerp(p2, u); return x:Lerp(y, u) end end
local function joined(c1, c2, split) return function(u) if u < split then return c1(u / split) else return c2((u - split) / (1 - split)) end end end
-- a strand's way down. "long": spout -> up and over -> the bowl's edge -> drooping into the basin. "over": the basin's rim -> the paving. "bowl": spout -> the bowl.
local function strandPath(g, kind, a)
	if kind == "long" then
		local edge = around(g, g.bowlR + 0.15, a, g.bowlY + 0.05)
		local c1 = curve(g.spout + Vector3.new(0, 0.1, 0), g.spout + Vector3.new(math.cos(a) * 1.2, 1.6 + rng:NextNumber(0, 1.0), math.sin(a) * 1.2), edge)
		local c2 = curve(edge, around(g, g.bowlR + 0.9, a, g.bowlY - 0.6), around(g, rng:NextNumber(g.basinR0 + 0.4, g.basinR1 - 0.3), a + rng:NextNumber(-0.25, 0.25), g.basinY + 0.05))
		return joined(c1, c2, 0.55)
	elseif kind == "bowl" then
		local r = rng:NextNumber(1.2, g.bowlR - 0.5)
		return curve(g.spout + Vector3.new(0, 0.1, 0), g.spout + Vector3.new(math.cos(a) * r * 0.6, 1.4 + rng:NextNumber(0, 0.8), math.sin(a) * r * 0.6), around(g, r, a, g.bowlY + 0.05))
	else   -- "over"
		return curve(around(g, g.rimR - 0.8, a, g.rimY + 0.05), around(g, g.rimR + 0.4, a, g.rimY - 0.1), around(g, g.rimR + rng:NextNumber(1.3, 2.4), a + rng:NextNumber(-0.15, 0.15), g.groundY + 0.05))
	end
end
local SEG = CFrame.Angles(0, math.rad(90), 0)   -- a Cylinder's axis is X; turned to lie along the way (-Z of a lookAt)
local PIECE, STEP = 0.6, 0.32   -- pieces 0.6 long every 0.32 studs: they overlap into one continuous tube
local function makeStrand(g, kind, a, radius)
	local path = strandPath(g, kind, a)
	local len, last = 0, path(0)
	for i = 1, 40 do local q = path(i / 40); len += (q - last).Magnitude; last = q end
	len = math.max(len, 1)
	local n = math.max(6, math.floor(len / STEP))
	local colour = NOODLE:Lerp(Color3.fromRGB(255, 236, 170), rng:NextNumber(0, 0.6))
	local st = {path = path, len = len, segs = {}, wob = rng:NextNumber(0, 6), amp = rng:NextNumber(0.04, 0.09), radius = radius}
	for i = 1, n do
		local seg = Instance.new("Part"); seg.Name = "Noodle"; seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false; seg.CastShadow = false
		seg.Shape = Enum.PartType.Cylinder; seg.Size = Vector3.new(PIECE, radius * 2, radius * 2); seg.Color = colour; seg.Material = Enum.Material.SmoothPlastic; seg.Parent = scene
		st.segs[i] = {p = seg, u = (i - 1) / n}
	end
	return st
end
local function strandStep(st, dt, speed, t)
	local path = st.path
	local du = PIECE * 0.5 / st.len
	for _, e in ipairs(st.segs) do
		e.u = (e.u + speed * dt / st.len) % 1
		local p, q = path(math.max(e.u - du, 0)), path(math.min(e.u + du, 1))
		if (q - p).Magnitude < 0.001 then q = p + Vector3.new(0, -0.1, 0) end
		local side = (q - p):Cross(Vector3.yAxis); side = side.Magnitude > 0.001 and side.Unit or Vector3.xAxis
		local wob = side * st.amp * math.sin(e.u * 16 - t * 2.2 + st.wob)   -- the wobble travels down the strand
		e.p.CFrame = CFrame.lookAt(p + wob, q + wob) * SEG
		-- emerging at the top, melting into the sauce at the bottom
		e.p.Transparency = (e.u < 0.03) and (1 - e.u / 0.03) or ((e.u > 0.95) and (e.u - 0.95) / 0.05 or 0)
	end
end
local function meatballPart(g, pos)
	local m = part("Meatball", Vector3.new(0.95, 0.95, 0.95), facing(pos, g.centre) * CFrame.Angles(0, math.pi, 0), MEAT, Enum.Material.Ground, Enum.PartType.Ball)
	local face = Instance.new("Decal"); face.Name = "Smile"; face.Texture = "rbxasset://textures/face.png"; face.Face = Enum.NormalId.Front; face.Parent = m
	return m, face
end
-- a coil: spaghetti heaped in a flat spiral on the water (Shannon's picture: piles of it in the basin and the bowl)
local function coil(g, centre, rMax, turns, radius)
	local n = math.floor(turns * 22)
	local colour = NOODLE:Lerp(Color3.fromRGB(255, 236, 170), rng:NextNumber(0, 0.6))
	local ph = rng:NextNumber(0, 6)
	local last = nil
	for i = 0, n do
		local k = i / n
		local ang = k * turns * 2 * math.pi + ph
		local r = 0.15 + (rMax - 0.15) * k
		local p = centre + Vector3.new(math.cos(ang) * r, 0.1 + 0.06 * math.sin(i * 1.7), math.sin(ang) * r)
		if last then
			local seg = Instance.new("Part"); seg.Name = "Coil"; seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false; seg.CastShadow = false
			seg.Shape = Enum.PartType.Cylinder; seg.Size = Vector3.new((p - last).Magnitude + 0.12, radius * 2, radius * 2); seg.Color = colour; seg.Material = Enum.Material.SmoothPlastic
			seg.CFrame = CFrame.lookAt((p + last) / 2, p) * SEG; seg.Parent = scene
		end
		last = p
	end
end
local function startSpaghetti(g)
	setWater(g, true)
	local sauce = F:GetAttribute("Sauce") == true   -- off by default: in Shannon's picture the basin is still water, heaped with spaghetti
	if sauce then
		tintWater(g, SAUCE, 0.1)
		g.water.Material = Enum.Material.Glass; g.water.Reflectance = 0.06
		g.ring.Material = Enum.Material.Glass; g.ring.Reflectance = 0.06
		local function bits(n, r0, r1, y)
			for i = 1, n do
				local a, r = rng:NextNumber(0, 2 * math.pi), math.sqrt(rng:NextNumber(r0 * r0, r1 * r1))
				local pos = around(g, r, a, y)
				if rng:NextNumber() < 0.7 then part("Mince", Vector3.new(rng:NextNumber(0.2, 0.4), 0.14, rng:NextNumber(0.2, 0.34)), CFrame.new(pos + Vector3.new(0, 0.02, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), MINCE:Lerp(Color3.fromRGB(130, 62, 36), rng:NextNumber(0, 1)), Enum.Material.Ground)
				else part("Herb", Vector3.new(0.14, 0.04, 0.1), CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color3.fromRGB(72, 112, 40)) end
			end
		end
		bits(num("SauceBits", 60), g.basinR0 + 0.2, g.basinR1 - 0.1, g.basinY)
		bits(12, 0.5, g.bowlR - 0.3, g.bowlY)
	end
	-- steam off the hot pasta
	local steamPart = part("Steam", Vector3.new(0.2, g.bowlR * 2, g.bowlR * 2), CFrame.new(g.centre.X, g.bowlY + 0.4, g.centre.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	steamPart.Transparency = 1
	local steam = Instance.new("ParticleEmitter"); steam.Name = "Steam"; steam.Texture = "rbxasset://textures/particles/smoke_main.dds"; steam.Color = ColorSequence.new(Color3.fromRGB(255, 250, 245))
	steam.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.0), NumberSequenceKeypoint.new(1, 2.4)}); steam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 1)})
	steam.Lifetime = NumberRange.new(2.2, 3.2); steam.Rate = num("SteamRate", 4); steam.Speed = NumberRange.new(0.5, 0.9); steam.SpreadAngle = Vector2.new(15, 15); steam.LightEmission = 0.1; steam.Parent = steamPart
	-- the strands, close together like curtains (her picture): long ones from the spout over the bowl's edge into the basin,
	-- some into the bowl, some over the outer rim onto the paving. Every third one slides and wobbles; the rest hang still.
	local strands, moving = {}, {}
	local function family(kind, n, radius, jitter)
		for i = 1, n do
			local st = makeStrand(g, kind, i / n * 2 * math.pi + rng:NextNumber(-jitter, jitter), radius)
			table.insert(strands, st)
			if i % 3 == 1 then table.insert(moving, st) else strandStep(st, 0, 0, rng:NextNumber(0, 6)) end
		end
	end
	family("long", num("NoodleLong", 36), 0.1, 0.06)
	family("bowl", num("NoodleBowl", 14), 0.09, 0.1)
	family("over", num("NoodleOver", 18), 0.1, 0.08)
	-- heaps of it: coils on the basin water and in the bowl
	for i = 1, num("CoilsBasin", 10) do
		local a, r = i / num("CoilsBasin", 10) * 2 * math.pi + rng:NextNumber(-0.2, 0.2), rng:NextNumber(g.basinR0 + 0.5, g.basinR1 - 0.6)
		coil(g, around(g, r, a, g.basinY), rng:NextNumber(0.55, 0.9), rng:NextNumber(1.8, 2.6), 0.1)
	end
	for i = 1, num("CoilsBowl", 4) do coil(g, around(g, rng:NextNumber(0.9, g.bowlR - 0.9), i / 4 * 2 * math.pi + rng:NextNumber(-0.3, 0.3), g.bowlY), rng:NextNumber(0.4, 0.7), 2, 0.09) end
	-- meatballs: on the rim, on the bowl's edge and on the heaps, looking out; now and then one rolls slowly down a long strand
	local balls = {}
	local function ball(pos, lookOut)
		local m = meatballPart(g, pos)
		if lookOut then m.CFrame = facing(pos, g.centre) * CFrame.Angles(0, math.pi, 0) else m.CFrame = facing(pos, g.centre) end
		table.insert(balls, {m = m, cf = m.CFrame, ph = rng:NextNumber(0, 6)})
	end
	for i = 1, num("MeatballsRim", 7) do ball(around(g, g.rimR - 0.3, i / 7 * 2 * math.pi + rng:NextNumber(-0.2, 0.2), g.rimY + 0.47), true) end
	for i = 1, 3 do ball(around(g, g.bowlR - 0.5, i / 3 * 2 * math.pi + 0.7, g.bowlY + 0.5), true) end
	for i = 1, 3 do ball(around(g, rng:NextNumber(g.basinR0 + 0.6, g.basinR1 - 0.6), i / 3 * 2 * math.pi + 1.9, g.basinY + (sauce and 0.12 or 0.42)), true) end
	local rolling = {}
	local my = gen
	task.spawn(function()
		local nextRoll, nextBubble = os.clock() + 2, os.clock() + 1
		local bubbles = {}
		while gen == my do
			local dt = math.min(RunService.RenderStepped:Wait(), 0.05)
			local t = os.clock()
			local speed = num("NoodleSpeed", 1.0)
			for _, st in ipairs(moving) do strandStep(st, dt, speed, t) end
			for _, bl in ipairs(balls) do if bl.m.Parent then bl.m.CFrame = bl.cf + Vector3.new(0, 0.02 * math.sin(t * 1.2 + bl.ph), 0) end end
			if sauce then   -- the sauce simmers: a bubble swells up through the surface and pops
				if t > nextBubble then
					nextBubble = t + rng:NextNumber(0.3, 0.9)
					local a, r = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(g.basinR0 + 0.3, g.basinR1 - 0.3)
					local bub = part("SauceBubble", Vector3.new(0.1, 0.1, 0.1), CFrame.new(around(g, r, a, g.basinY - 0.1)), SAUCE:Lerp(Color3.fromRGB(190, 80, 50), 0.4), Enum.Material.Glass, Enum.PartType.Ball)
					bub.Transparency = 0.15
					table.insert(bubbles, {p = bub, t0 = t, size = rng:NextNumber(0.3, 0.55), pos = bub.Position})
				end
				for i = #bubbles, 1, -1 do
					local bu = bubbles[i]
					local k = (t - bu.t0) / 1.1
					if k >= 1 or not bu.p.Parent then if bu.p.Parent then bu.p:Destroy() end; table.remove(bubbles, i)
					else local sz = bu.size * math.sin(k * math.pi); bu.p.Size = Vector3.new(sz, sz, sz); bu.p.CFrame = CFrame.new(bu.pos + Vector3.new(0, 0.08 + k * 0.1, 0)) end
				end
			end
			if t > nextRoll and #rolling < 3 and #moving > 0 then
				nextRoll = t + num("MeatballEvery", 5)
				local st = moving[rng:NextInteger(1, math.min(#moving, math.ceil(num("NoodleLong", 36) / 3)))]
				local m, face = meatballPart(g, st.path(0))
				table.insert(rolling, {m = m, face = face, path = st.path, len = st.len, u = 0, rest = nil})
			end
			for i = #rolling, 1, -1 do
				local rb = rolling[i]
				if not rb.m.Parent then table.remove(rolling, i)
				elseif rb.rest then
					if t - rb.rest > num("MeatballRest", 7) then
						TweenService:Create(rb.m, TweenInfo.new(0.8), {Transparency = 1}):Play(); TweenService:Create(rb.face, TweenInfo.new(0.8), {Transparency = 1}):Play(); Debris:AddItem(rb.m, 0.9); table.remove(rolling, i)
					end
				else
					rb.u = rb.u + speed * 0.8 * dt / rb.len
					if rb.u >= 1 then
						rb.rest = t; rb.m.CFrame = facing(rb.path(1) + Vector3.new(0, sauce and 0.12 or 0.42, 0), g.centre) * CFrame.Angles(0, math.pi, 0)
					else
						local p = rb.path(rb.u)
						rb.m.CFrame = CFrame.new(p + Vector3.new(0, 0.42, 0)) * CFrame.Angles(0, 0, -rb.u * 9) * facing(p, g.centre).Rotation
					end
				end
			end
		end
		for _, bu in ipairs(bubbles) do if bu.p.Parent then bu.p:Destroy() end end
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
	local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextScaled = true; l.TextColor3 = Color3.fromRGB(255, 246, 220); l.TextStrokeTransparency = 0.6; l.Text = str("SignText", "CLUB RANA"); l.Parent = sg
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
