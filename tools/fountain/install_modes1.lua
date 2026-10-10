-- fountain/install_modes1 (job 61): EDIT mode, re-runnable. The Fontana del Limone's bought modes (Shannon, Oct 10 2026):
-- Club Rana (the frogs) and the petal fountain. workspace.FountainModes + its client, the assets
-- Shannon imported -> ReplicatedStorage.FountainModeAssets, the Acorn Store rows (ShopServer / ShopClient patched, backups
-- ServerStorage.HudBackup.ShopServer_pre_modes1 / ShopClient_pre_modes1). Output lines "QQ FMODE".
if game:GetService("RunService"):IsRunning() then warn("QQ FMODE ABORT - Play mode") return end
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local Shop = workspace:FindFirstChild("Shop")
local sv = Shop and Shop:FindFirstChild("ShopServer"); local cl = Shop and Shop:FindFirstChild("ShopClient")
if not (sv and cl) then warn("QQ FMODE ABORT - workspace.Shop.ShopServer / ShopClient missing") return end
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
-- the store: the job 59 texts are the base. A store already carrying these modes (three rows from the first version, or this
-- one) is put back to the base from the backups first, then patched afresh, so a re-run always gives the current rows.
local shopDone = cl.Source:find('id = "fountainmode"', 1, true) ~= nil and sv.Source:find("item.modes", 1, true) ~= nil
local restored = false
local baseS, baseC = sv.Source, cl.Source   -- the texts the patch starts from; written back only at the end, after every abort point
if sv.Source:find("modeTaken", 1, true) then
	local b1, b2 = backup:FindFirstChild("ShopServer_pre_modes1"), backup:FindFirstChild("ShopClient_pre_modes1")
	if not (b1 and b2 and #b1.Source == 9261 and #b2.Source == 35014) then warn("QQ FMODE ABORT - the store carries an earlier modes patch and HudBackup has no clean ShopServer_pre_modes1 / ShopClient_pre_modes1 to go back to; nothing changed") return end
	baseS, baseC = b1.Source, b2.Source; restored = true; shopDone = false
end
if #baseS ~= 9261 then warn(string.format("QQ FMODE ABORT - ShopServer is %d chars, expected 9261 (not the job 59 export); nothing changed", #baseS)) return end
if #baseC ~= 35014 then warn(string.format("QQ FMODE ABORT - ShopClient is %d chars, expected 35014 (not the job 59 export); nothing changed", #baseC)) return end
-- the fountain, and its rim and the paving, measured
local fm = workspace
for seg in string.gmatch("PortoNocciola/13 Hillside town/Fontana del Limone", "[^/]+") do fm = fm and fm:FindFirstChild(seg) end
local water = fm and fm:FindFirstChild("Water", true)
if not water then warn("QQ FMODE ABORT - workspace.PortoNocciola['13 Hillside town']['Fontana del Limone'].Water not found") return end
local c = water.Position
local rimY, rimR = nil, 6.2
for _, r in ipairs({5.6, 6.0, 6.4, 6.8}) do
	for _, a in ipairs({0, 1.57, 3.14, 4.71}) do
		local hit = workspace:Raycast(c + Vector3.new(math.cos(a) * r, 8, math.sin(a) * r), Vector3.new(0, -14, 0))
		if hit and hit.Instance.Name == "Stone" and (not rimY or hit.Position.Y > rimY) then rimY, rimR = hit.Position.Y, r end
	end
end
local gHit = workspace:Raycast(c + Vector3.new(10, 8, 0), Vector3.new(0, -24, 0))
local groundY = gHit and gHit.Position.Y or (c.Y - 4)
-- the folder and the client
local old = workspace:FindFirstChild("FountainModes"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "FountainModes"
F:SetAttribute("FountainPath", "PortoNocciola/13 Hillside town/Fontana del Limone")
F:SetAttribute("Minutes", 2); F:SetAttribute("Reach", 150)   -- two minutes (Shannon: "different from the French one")
F:SetAttribute("FrogSoundId", 73626983091367); F:SetAttribute("BounceSoundId", 0)
F:SetAttribute("PetalsPerSecond", 60); F:SetAttribute("PetalMax", 420); F:SetAttribute("PetalSpread", 55); F:SetAttribute("PetalSpeedMin", 6); F:SetAttribute("PetalSpeedMax", 10); F:SetAttribute("PetalFall", 5); F:SetAttribute("PetalDrag", 1.2); F:SetAttribute("PetalRest", 2.6); F:SetAttribute("CarpetCount", 90)

F:SetAttribute("SignText", "CLUB RANA"); F:SetAttribute("DeckAngle", 0.9)
F:SetAttribute("RimY", rimY or (c.Y - 2.15 + 1.3)); F:SetAttribute("RimR", rimR); F:SetAttribute("GroundY", groundY)
F:SetAttribute("ActiveMode", ""); F:SetAttribute("ActiveUntil", 0); F:SetAttribute("ActiveBy", "")
local cs = Instance.new("Script"); cs.Name = "FountainModeClient"; cs.RunContext = Enum.RunContext.Client; cs.Source = [===[
-- FountainModeClient (workspace.FountainModes, RunContext Client): the Fontana del Limone's bought modes (Shannon, Oct 10
-- 2026). "frogs": Club Rana - frogs lounging on lily pads and the rims (sunglasses, a sun hat, a swim ring), lotus flowers,
-- a parasol, a deck chair, a pool ladder, string lights and a sign. "petals": real petal shapes fly out of the jets and over
-- the rims, tumble and drift down, land and fade, with a carpet of them on the water. (A spaghetti fountain was tried and
-- dropped.) Bought in the Acorn Store like the French fountain colour, one row with the choices: the whole server's fountain
-- for Minutes, one mode at a time; ShopServer sets ActiveMode / ActiveUntil / ActiveBy on the folder. Everything here is
-- local to this client and runs only within Reach of the fountain; the fountain itself is never changed - its emitters are
-- switched off locally while petals pour and back on after. Assets live in ReplicatedStorage.FountainModeAssets.
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
	for _, e in ipairs(carpet(g, 60, g.rimR + 0.6, g.rimR + 5.5, g.groundY, 0.45)) do table.insert(floating, e) end
	-- the rim stream points: where the water pours over the bowl's edge
	local rimPts = {}
	for _, d in ipairs(g.water:GetChildren()) do if d:IsA("Attachment") and d.Name == "RimStream" then table.insert(rimPts, d.WorldPosition) end end
	if #rimPts == 0 then for i = 1, 12 do table.insert(rimPts, around(g, g.bowlR + 0.1, i / 12 * 2 * math.pi, g.bowlY + 0.1)) end end
	local live = {}
	local function launch(fromTop)
		local p = petalPart(rng:NextNumber(0.42, 0.6))
		local pos, v
		if fromTop == "top" then
			local th, ph = math.rad(rng:NextNumber(0, num("PetalSpread", 55))), rng:NextNumber(0, 2 * math.pi)
			local sp = rng:NextNumber(num("PetalSpeedMin", 6), num("PetalSpeedMax", 10))
			pos = g.spout + Vector3.new(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))
			v = Vector3.new(math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)) * sp
		elseif fromTop == "edge" then   -- off the basin's rim, drifting out and down to the paving (Shannon: "a wider radius ... to the bottom")
			local a = rng:NextNumber(0, 2 * math.pi)
			pos = around(g, g.rimR - 0.2, a, g.rimY + 0.6)
			v = Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(1.2, 3.0) + Vector3.new(0, rng:NextNumber(0.3, 1.2), 0)
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
			acc += dt * num("PetalsPerSecond", 60)
			while acc >= 1 and #live < num("PetalMax", 420) do acc -= 1; local k = rng:NextNumber(); launch(k < 0.6 and "top" or (k < 0.8 and "rim" or "edge")) end
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

-- ---------- the frog resort ----------
local assets = RS:FindFirstChild("FountainModeAssets")
local function asset(name) return assets and assets:FindFirstChild(name, true) end
local function frog(cf, scale, accessory)
	-- a frog from the imported model: Body, EyeL, EyeR, and one of Sunglasses / SunHat / SwimRing (the others go).
	-- Import 3D left a 90-degree PivotOffset on every part of the frog, so PivotTo(level) laid it on its face with its
	-- backside in the air (Shannon, Oct 10, VR); the pivots are flattened first, so the pivot is the Body itself, upright.
	local src = asset("Frog"); if not src then return nil end
	local m = src:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.PivotOffset = CFrame.identity
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
	if pad then p = pad:Clone(); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.PivotOffset = CFrame.identity; sitOn(p, cf); p.Parent = scene
	else p = part("LilyPad", Vector3.new(0.08, 1.6, 1.6), cf * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 150, 70), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder) end
	if withLotus then
		local l = asset("Lotus")
		if l then local c = l:Clone(); for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.PivotOffset = CFrame.identity end end; sitOn(c, cf * CFrame.new(0, 0.1, 0)); c.Parent = scene end
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
-- A SOLID FOOTING on the stone (Shannon, Oct 10: the top-tier frog "floating in mid air", the far rim frog "half suspended on
-- water"): from the spot asked for, then step by step along its own line from the centre (first inward or first outward),
-- the first place where the frog's whole footprint rests on the fountain's own stone at one height - a ray that meets the
-- water, the upper bowl, our own parts or anything that is not the fountain does not count. Nothing within reach -> nil.
local footParams = RaycastParams.new(); footParams.FilterType = Enum.RaycastFilterType.Exclude; footParams.IgnoreWater = true
local function footing(g, pos, scale, maxDrop, inFirst)
	local ex = {}
	if scene then table.insert(ex, scene) end
	if player.Character then table.insert(ex, player.Character) end
	footParams.FilterDescendantsInstances = ex
	local flat = Vector3.new(pos.X - g.centre.X, 0, pos.Z - g.centre.Z)
	local out = flat.Magnitude > 0.05 and flat.Unit or Vector3.new(1, 0, 0)
	local side = Vector3.new(-out.Z, 0, out.X)
	local hx, hz = 0.4 * (scale or 1), 0.3 * (scale or 1)         -- the toes may hang over an edge (the rim's flat top is 0.6-0.8 wide)
	local function test(p)
		local lo, hi
		for _, o in ipairs({Vector3.zero, out * hz, -out * hz, side * hx, -side * hx}) do
			local hit = workspace:Raycast(p + o + Vector3.new(0, 1.5, 0), Vector3.new(0, -(1.5 + maxDrop), 0), footParams)
			if not hit or hit.Instance == g.water or hit.Instance == g.ring or not hit.Instance:IsDescendantOf(g.fm) then return nil end
			lo = math.min(lo or hit.Position.Y, hit.Position.Y); hi = math.max(hi or hit.Position.Y, hit.Position.Y)
		end
		if hi - lo > 0.12 then return nil end                   -- (the rim's inner slope is 0.18 lower a step in: refused)
		return hi
	end
	local sign = inFirst and -1 or 1
	for _, k in ipairs({0, 0.15, 0.3, 0.5, 0.7, 0.9, 1.2, 1.5}) do
		for _, d in ipairs(k == 0 and {0} or {k * sign, -k * sign}) do
			local q = pos + out * d
			local y = test(q)
			if y then return Vector3.new(q.X, y, q.Z) end
		end
	end
	return nil
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
		if spec.frog then
			add(frog(facing(pos + Vector3.new(0, 0.1, 0), g.centre) * CFrame.Angles(0, math.pi + rng:NextNumber(-0.6, 0.6), 0), spec.scale, spec.frog), "pad")
			if frogs[#frogs] and frogs[#frogs].kind == "pad" then frogs[#frogs].ph = pads[#pads].ph end   -- it bobs with its own pad (review)
		end
	end
	-- in the water, in a swim ring; two on the rim, one in a sun hat
	add(frog(facing(around(g, 4.4, 3.1, g.basinY - 0.25), g.centre), 1.0, "SwimRing"), "swim")   -- feet under, the ring on the water (review)
	-- (the stone may not have streamed in yet when the mode starts 150 studs out: these two keep trying for half a minute)
	local footed = {
		{name = "rim frog (sun hat)", at = around(g, g.rimR + 0.3, 1.2, g.rimY), scale = 1.0, drop = 1.0, inFirst = false, yaw = math.pi, acc = "SunHat", kind = "rim"},   -- (RimR is the flat top's inner edge; its middle is 0.3-0.4 out)
		{name = "rim frog", at = around(g, g.rimR + 0.3, 4.9, g.rimY), scale = 0.9, drop = 1.0, inFirst = false, yaw = 0, acc = "", kind = "rim"},
	}
	local function tryFooted()
		local left = 0
		for _, f in ipairs(footed) do
			if not f.done then
				local spot = footing(g, f.at, f.scale, f.drop, f.inFirst)
				if spot then f.done = true; add(frog(facing(spot, g.centre) * CFrame.Angles(0, f.yaw, 0), f.scale, f.acc), f.kind)
				else left += 1 end
			end
		end
		return left
	end
	-- one up top: on a lily pad afloat in the upper bowl, looking out over the deck (Shannon, Oct 10: on the bowl's floor it
	-- "floated on water with its face stuck in the spout"; the column top is too narrow for it)
	do
		local a = num("DeckAngle", 0.9)
		local pos = around(g, math.max(1.0, g.bowlR - 1.1), a, g.bowlY)
		local pad = lilyPad(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), false)
		local ph = rng:NextNumber(0, 6)
		table.insert(pads, {p = pad, cf = pad:GetPivot(), ph = ph})
		add(frog(facing(pos + Vector3.new(0, 0.1, 0), g.centre) * CFrame.Angles(0, math.pi, 0), 0.7, ""), "pad")
		if frogs[#frogs] and frogs[#frogs].kind == "pad" then frogs[#frogs].ph = ph end
	end
	-- the deck: a parasol, a deck chair with a frog in it and a drink, the sign, a ladder, string lights
	local deckA = num("DeckAngle", 0.9)
	local deckPos = around(g, g.rimR + 3.6, deckA, g.groundY)
	parasol(g, deckPos + Vector3.new(math.cos(deckA + 1.5) * 1.4, 0, math.sin(deckA + 1.5) * 1.4))
	local chairCF = facing(deckPos, g.centre) * CFrame.Angles(0, math.pi, 0)
	deckChair(g, chairCF)
	add(frog(chairCF * CFrame.new(0, 0.62, 0.1) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.rad(20), 0, 0), 1.0, "SunHat"), "chair")   -- facing out of the chair (the frog's face is its -Z), reclined 20 degrees
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
	if tryFooted() > 0 then
		task.spawn(function()
			local t0 = os.clock()
			while gen == my and os.clock() - t0 < 30 do
				task.wait(0.5)
				if gen == my and tryFooted() == 0 then return end
			end
			if gen == my then for _, f in ipairs(footed) do if not f.done then warn(string.format("FountainModes: no stone footing for the %s near %s", f.name, tostring(f.at))) end end end
		end)
	end
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
	if mode == "petals" then startPetals(g) elseif mode == "frogs" then startFrogs(g) end   -- (the spaghetti fountain was tried and dropped, Oct 10: "too hard to pull off")
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
]===]; cs.Parent = F
do local f, err = loadstring(cs.Source); if not f then warn("QQ FMODE ABORT - FountainModeClient does not compile: " .. tostring(err)); F:Destroy(); return end end
F.Parent = workspace
-- the assets Shannon imported (File > Import 3D): a Model "frog" with MeshParts Body/EyeL/EyeR (+ Sunglasses, SunHat, SwimRing)
-- and a Model "flowers" with LilyPad, Lotus_Petals/Lotus_Centre, Flower_*_Petals/_Centre, Leaf
local assets = RS:FindFirstChild("FountainModeAssets") or Instance.new("Folder"); assets.Name = "FountainModeAssets"; assets.Parent = RS
local function tidy(m) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end end end
local got = {}
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") and (m.Name:lower() == "frog" or m.Name:lower() == "flowers" or m.Name:lower() == "petals" or m:FindFirstChild("EyeL", true) or m:FindFirstChild("Lotus_Petals", true) or m:FindFirstChild("Petal_A", true)) then
		if m:FindFirstChild("Body", true) and m:FindFirstChild("EyeL", true) and not assets:FindFirstChild("Frog") then
			tidy(m); m.Name = "Frog"; m.PrimaryPart = m:FindFirstChild("Body", true); m.Parent = assets; table.insert(got, "Frog")
		elseif m:FindFirstChild("Petal_A", true) and not assets:FindFirstChild("Petal_A", true) then
			tidy(m); m.Name = "Petals"; m.Parent = assets; table.insert(got, "Petals")
		elseif m:FindFirstChild("LilyPad", true) then
			tidy(m)
			local pad = m:FindFirstChild("LilyPad", true); if pad and not assets:FindFirstChild("LilyPad") then pad.Parent = assets; table.insert(got, "LilyPad") end
			local lp, lc = m:FindFirstChild("Lotus_Petals", true), m:FindFirstChild("Lotus_Centre", true)
			if lp and not assets:FindFirstChild("Lotus") then local lot = Instance.new("Model"); lot.Name = "Lotus"; lp.Parent = lot; if lc then lc.Parent = lot end; lot.PrimaryPart = lp; lot.Parent = assets; table.insert(got, "Lotus") end
			if not assets:FindFirstChild("Flowers") then m.Name = "Flowers"; m.Parent = assets; table.insert(got, "Flowers (the rest)") else m:Destroy() end
		end
	end
end
-- the flowers' flat Blender colours do not survive Import 3D (they come in grey): set by name, every run
local COLOURS = {LilyPad = Color3.fromRGB(48, 120, 48), Leaf = Color3.fromRGB(66, 153, 56), Lotus_Petals = Color3.fromRGB(250, 148, 189), Lotus_Centre = Color3.fromRGB(255, 204, 38),
	Flower_A_Petals = Color3.fromRGB(242, 102, 158), Flower_A_Centre = Color3.fromRGB(255, 204, 38), Flower_B_Petals = Color3.fromRGB(224, 41, 66), Flower_B_Centre = Color3.fromRGB(255, 204, 38),
	Flower_C_Petals = Color3.fromRGB(158, 87, 219), Flower_C_Centre = Color3.fromRGB(255, 204, 38), Petal_A = Color3.fromRGB(255, 110, 150), Petal_B = Color3.fromRGB(255, 110, 150), Petal_C = Color3.fromRGB(255, 110, 150)}
local coloured = 0
for _, d in ipairs(assets:GetDescendants()) do if d:IsA("BasePart") and COLOURS[d.Name] and d.TextureID == "" then d.Color = COLOURS[d.Name]; d.Material = Enum.Material.SmoothPlastic; coloured += 1 end end
local have = {}
for _, n in ipairs({"Frog", "LilyPad", "Lotus", "Flowers", "Petals"}) do if assets:FindFirstChild(n) then table.insert(have, n) end end
-- the store
Shop:SetAttribute("Price_fountainmode", Shop:GetAttribute("Price_fountainmode") or 25); Shop:SetAttribute("Sell_fountainmode", true)
for _, w in ipairs({"spaghetti", "frogs", "petals"}) do Shop:SetAttribute("Price_" .. w, nil); Shop:SetAttribute("Sell_" .. w, nil) end   -- (the first version's three rows)
local shopNote = "store already patched (kept)"
if not shopDone then
	local function patch(src, pairs_, what)
		for i, p in ipairs(pairs_) do
			local a, b = src:find(p[1], 1, true)
			if not a then warn("QQ FMODE ABORT - " .. what .. " find " .. i .. " not found; the store is unchanged") return nil end
			if src:find(p[1], b + 1, true) then warn("QQ FMODE ABORT - " .. what .. " find " .. i .. " matches more than once; the store is unchanged") return nil end
			src = src:sub(1, a - 1) .. p[2] .. src:sub(b + 1)
		end
		local f, err = loadstring(src)
		if not f then warn("QQ FMODE ABORT - patched " .. what .. " does not compile: " .. tostring(err)) return nil end
		return src
	end
	local newS = patch(baseS, {{[===[
	zoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it
}
]===], [===[
	zoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it
	-- Oct 10 2026: the Fontana del Limone's modes (workspace.FountainModes), one row with two choices; the whole server's fountain for Minutes, one mode at a time
	fountainmode = {repeatable = true, modes = {"frogs", "petals"}},
}
]===]}, {[===[
	if item.palette then
		variant = tonumber(variant)
		if not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end
	end
]===], [===[
	if item.palette then
		variant = tonumber(variant)
		if not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end
	end
	-- a fountain mode has to be one of the three (whether the fountain is free is checked again just before paying)
	if item.modes then
		variant = tonumber(variant)
		if not variant or variant < 1 or variant > #item.modes or variant % 1 ~= 0 then return false, "pick one" end
	end
]===]}, {[===[
	if item.palette and fountainTaken() then return false, fountainTaken() end

	-- Enforced HERE]===], [===[
	if item.palette and fountainTaken() then return false, fountainTaken() end
	-- the Fontana del Limone likewise runs one bought mode at a time (workspace.FountainModes)
	local function modeTaken()
		local FM = workspace:FindFirstChild("FountainModes")
		local untilT = FM and FM:GetAttribute("ActiveUntil") or 0
		local left = untilT - workspace:GetServerTimeNow()
		if FM and (FM:GetAttribute("ActiveMode") or "") ~= "" and left > 0 then
			left = math.ceil(left)
			return string.format("the fountain is busy - free in %d:%02d", math.floor(left / 60), left % 60)
		end
		return nil
	end
	if item.modes and modeTaken() then return false, modeTaken() end

	-- Enforced HERE]===]}, {[===[
		if item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)
]===], [===[
		if item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)
		if item.modes and modeTaken() then return false, modeTaken() end
]===]}, {[===[
			end
		end
		return true, price
]===], [===[
			end
		end
		if item.modes then
			-- the Fontana del Limone runs the chosen mode for Minutes (workspace.FountainModes): ActiveMode, ActiveUntil (server time), ActiveBy
			local FM = workspace:FindFirstChild("FountainModes")
			local minutes = (FM and FM:GetAttribute("Minutes")) or 2
			if FM then FM:SetAttribute("ActiveBy", player.DisplayName); FM:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60)); FM:SetAttribute("ActiveMode", item.modes[variant]) end
		end
		return true, price
]===]}}, "ShopServer")
	local newC = newS and patch(baseC, {{[===[
	{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},
}
]===], [===[
	{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},
	-- the Fontana del Limone's modes (Oct 10 2026): one row, two choices; the whole server's fountain for two minutes, one at a time
	{id = "fountainmode", name = "Fountain magic", blurb = "Pick one and the fountain in the square does it for two minutes - for everyone here: Club Rana for the frogs, or a shower of petals.",
		modes = {{id = "frogs", name = "Club Rana"}, {id = "petals", name = "Petals"}}},
}
]===]}, {[===[
	crabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true},
}
]===], [===[
	crabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true}, fountainmode = {italy = true},
}
]===]}, {[===[
local function mmss(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end
]===], [===[
-- the Fontana del Limone's modes are the server's too (workspace.FountainModes): one at a time, with a countdown
local MODE_NAMES = {frogs = "Club Rana", petals = "petal fountain"}
local function modeNow()
	local FM = workspace:FindFirstChild("FountainModes")
	local m = FM and FM:GetAttribute("ActiveMode") or ""
	local untilT = FM and FM:GetAttribute("ActiveUntil") or 0
	local left = untilT - workspace:GetServerTimeNow()
	if m ~= "" and left > 0 then return m, math.ceil(left), (FM:GetAttribute("ActiveBy") or "someone") end
	return nil, 0, nil
end
local function mmss(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end
]===]}, {[===[
	else
	local btn = Instance.new("TextButton")
]===], [===[
	elseif item.modes then
		-- THE CHOICES on one row (Shannon: "one line item with different choices"), each the buy button for its mode
		rec.choices = {}
		local n = #item.modes
		for i, mode in ipairs(item.modes) do
			local cb = Instance.new("TextButton"); cb.Name = "Choice" .. i; cb.Text = mode.name
			cb.AnchorPoint = Vector2.new(1, 0); cb.Position = UDim2.new(1, -12 - (n - i) * 106, 0, 106)   -- two of 100 px, within the colour row's swatch span (fits a phone)
			cb.Size = UDim2.fromOffset(100, 36); cb.BackgroundColor3 = GOLD; cb.BorderSizePixel = 0; cb.AutoButtonColor = false; cb.ZIndex = 4
			cb.FontFace = FONT; cb.TextSize = 14; cb.TextColor3 = BTN_INK; cb.TextScaled = false; cb.Parent = row
			corner(cb, UDim.new(0, 10)); stroke(cb, RGB(150, 98, 36), 2, 0.2)
			cb.MouseButton1Click:Connect(function()
				if not onSale(item) then say(rec, "not in the shop yet", false) return end
				local m, left = modeNow()
				if m then say(rec, "the fountain is busy - free in " .. mmss(left), false) return end
				attempt(item, rec, i)
			end)
			rec.choices[i] = cb
		end
		local pl = Instance.new("TextLabel"); pl.Name = "PriceLabel"; pl.Position = UDim2.new(0, 10, 0, 110)
		pl.Size = UDim2.fromOffset(110, 26); pl.BackgroundTransparency = 1; pl.FontFace = FONT; pl.TextSize = 14
		pl.TextColor3 = INK_DIM; pl.TextXAlignment = Enum.TextXAlignment.Left; pl.Text = ""; pl.ZIndex = 4; pl.Parent = row
		rec.priceLabel = pl
	else
	local btn = Instance.new("TextButton")
]===]}, {[===[
		elseif rec and rec.btn then
			local price = priceOf(item)
]===], [===[
		elseif rec and rec.choices then                                -- the fountain's modes: whose is running, and until when
			local price = priceOf(item)
			local selling = onSale(item)
			local m, left, by = modeNow()
			local runIdx = 0
			for i, c in ipairs(item.modes) do if c.id == m then runIdx = i end end
			if m then
				rec.priceLabel.Text = "free in " .. mmss(left)
				if rec.blurb then rec.blurb.Text = string.format("In use: %s's %s. Free again in %s.", tostring(by), MODE_NAMES[m] or m, mmss(left)) end
			else
				rec.priceLabel.Text = selling and (type(price) == "number" and (tostring(price) .. " acorns") or "-") or "soon"
				if rec.blurb then rec.blurb.Text = item.blurb end
			end
			local can = selling and type(price) == "number" and have >= price and not m
			for i, b in ipairs(rec.choices) do
				b.BackgroundColor3 = (i == runIdx) and RGB(112, 160, 84) or (can and GOLD or RGB(214, 202, 176))
				b.TextColor3 = (i == runIdx) and RGB(255, 255, 255) or (can and BTN_INK or INK_DIM)
			end
		elseif rec and rec.btn then
			local price = priceOf(item)
]===]}, {[===[
	if FCw then for _, a in ipairs({"ActiveColour", "ActiveUntil", "ActiveBy"}) do FCw:GetAttributeChangedSignal(a):Connect(refresh) end end
]===], [===[
	if FCw then for _, a in ipairs({"ActiveColour", "ActiveUntil", "ActiveBy"}) do FCw:GetAttributeChangedSignal(a):Connect(refresh) end end
	local FMw = workspace:FindFirstChild("FountainModes")
	if FMw then for _, a in ipairs({"ActiveMode", "ActiveUntil", "ActiveBy"}) do FMw:GetAttributeChangedSignal(a):Connect(refresh) end end
]===]}, {[===[
			local running = fountainNow() > 0
]===], [===[
			local running = fountainNow() > 0 or modeNow() ~= nil
]===]}}, "ShopClient")
	if not (newS and newC) then return end
	if not backup:FindFirstChild("ShopServer_pre_modes1") then local b1 = sv:Clone(); b1.Name = "ShopServer_pre_modes1"; b1.Enabled = false; b1.Parent = backup end
	if not backup:FindFirstChild("ShopClient_pre_modes1") then local b2 = cl:Clone(); b2.Name = "ShopClient_pre_modes1"; b2.Enabled = false; b2.Parent = backup end
	sv.Source = newS; cl.Source = newC
	shopNote = string.format("ShopServer %d -> %d, ShopClient %d -> %d chars%s; backups HudBackup.ShopServer_pre_modes1 / ShopClient_pre_modes1 (the job 59 texts)", 9261, #newS, 35014, #newC, restored and " (the earlier three-row patch undone first)" or "")
end
game:GetService("ChangeHistoryService"):SetWaypoint("Fountain modes installed")
print(string.format("QQ FMODE DONE: workspace.FountainModes (client %d chars; rim y %s at r %.1f, paving y %.1f); assets in ReplicatedStorage.FountainModeAssets: %s (moved in now: %s; %d flower parts coloured); %s", #cs.Source, tostring(rimY and string.format("%.2f", rimY) or "not measured, default"), rimR, groundY, #have > 0 and table.concat(have, ", ") or "NONE - import frog.fbx and flowers.fbx and run again", #got > 0 and table.concat(got, ", ") or "none", coloured, shopNote))
