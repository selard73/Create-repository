-- UFO + landing pad: run in the Command Bar with the imported model SELECTED (or it finds "ufo" in Workspace).
-- Matte metal body, blinking round lamps that cast light, glass dome, glowing green beam that lifts things,
-- gentle hover + spin. Blinking, hovering and lifting only run while the game runs (press Run or Play).
local model = workspace:FindFirstChild("UFO") or workspace:FindFirstChild("ufo") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the imported ufo model first")
local colors = { Pink = Color3.fromRGB(255, 40, 160), Cyan = Color3.fromRGB(0, 170, 255), Orange = Color3.fromRGB(255, 120, 0), Yellow = Color3.fromRGB(255, 215, 0), Green = Color3.fromRGB(30, 210, 60), Lime = Color3.fromRGB(150, 255, 60), Red = Color3.fromRGB(235, 30, 30), Blue = Color3.fromRGB(40, 90, 255) }
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Light") then c:Destroy() end end
		local tone = p.Name:match("^Neon(%a+)_")
		if tone and colors[tone] then
			p.Material = Enum.Material.Neon; p.Color = colors[tone]; p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
			if p.Name:find("Lamp") then
				local l = Instance.new("PointLight"); l.Color = colors[tone]; l.Range = 3; l.Brightness = 0.5; l.Shadows = false; l.Parent = p
			end
		elseif p.Name == "Dome" then
			p.Material = Enum.Material.SmoothPlastic; p.Color = Color3.fromRGB(215, 238, 245); p.TextureID = ""; p.Transparency = 0.74; p.CanCollide = false; p.CastShadow = false; p.Reflectance = 0
		elseif p.Name == "Beam" then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(200, 225, 105); p.TextureID = ""; p.Transparency = 0.72; p.CanCollide = false; p.CastShadow = false
			local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(225, 240, 140); l.Range = 12; l.Brightness = 0.9; l.Shadows = false; l.Parent = p
		elseif p.Name:match("^Alien") then
			p.Material = Enum.Material.SmoothPlastic
		else
			p.Material = Enum.Material.SmoothPlastic
		end
	end
end
-- sounds (built-in Roblox clips, no upload needed): machinery click + wind-up, generator rumble loop,
-- electronic beeping, wind-down. Swap any SoundId for a Toolbox audio id if you want a fancier clip.
do
	local beam = model:FindFirstChild("Beam")
	if beam then
		for _, n in ipairs({"BeamHum", "BeamStart", "BeamStop", "BeamBeep", "BeamClick"}) do local o = beam:FindFirstChild(n); if o then o:Destroy() end end
		local function snd(name, id, vol, speed, looped)
			local x = Instance.new("Sound"); x.Name = name; x.SoundId = id; x.Volume = vol; x.PlaybackSpeed = speed
			x.Looped = looped or false; x.RollOffMaxDistance = 110; x.Parent = beam; return x
		end
		snd("BeamClick", "rbxasset://sounds/switch3.wav", 0.8, 0.7)
		snd("BeamStart", "rbxasset://sounds/Launching rocket.wav", 0.6, 0.55)
		snd("BeamHum",   "rbxasset://sounds/Launching rocket.wav", 0.3, 0.4, true)
		snd("BeamBeep",  "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.9)
		snd("BeamStop",  "rbxasset://sounds/Rocket whoosh 01.wav", 0.5, 0.5)
	end
end
-- sparkles drifting up inside the beam: an invisible cylinder volume with two particle emitters
do
	local beam = model:FindFirstChild("Beam")
	local old = model:FindFirstChild("BeamSparkles"); if old then old:Destroy() end
	if beam then
		local vol = Instance.new("Part"); vol.Name = "BeamSparkles"; vol.Anchored = true; vol.CanCollide = false; vol.CanQuery = false
		vol.Transparency = 1; vol.CastShadow = false
		vol.Size = Vector3.new(2.6, beam.Size.Y * 0.5, 2.6)
		vol.CFrame = beam.CFrame * CFrame.new(0, -beam.Size.Y * 0.22, 0)
		vol.Parent = model
		local function emitter(name, rate, size0, size1, life0, life1, speed0, speed1, bright)
			local e = Instance.new("ParticleEmitter"); e.Name = name
			e.Shape = Enum.ParticleEmitterShape.Cylinder; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward; e.ShapePartial = 1
			e.EmissionDirection = Enum.NormalId.Top
			e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 110)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 245, 140)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 255, 130)) })
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.15, size0), NumberSequenceKeypoint.new(0.8, size1), NumberSequenceKeypoint.new(1, 0) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime = NumberRange.new(life0, life1); e.Rate = rate; e.Speed = NumberRange.new(speed0, speed1)
			e.SpreadAngle = Vector2.new(0, 0); e.Drag = 0; e.Acceleration = Vector3.new(0, 0.9, 0)
			e.RotSpeed = NumberRange.new(0, 0); e.Rotation = NumberRange.new(0, 0)
			e.LightEmission = 1; e.LightInfluence = 0; e.Brightness = bright; e.ZOffset = 0.2
			e.Parent = vol
			return e
		end
		emitter("Motes", 70, 0.07, 0.05, 4.0, 6.0, 0.35, 0.6, 3)
		emitter("Molecules", 14, 0.14, 0.1, 4.0, 6.0, 0.25, 0.45, 2)
	end
end
-- remember where every piece belongs relative to the pad, so the model can snap itself back together
do
	local padBase = model:FindFirstChild("PadBase")
	if padBase then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p ~= padBase then p:SetAttribute("HomeOffset", padBase.CFrame:ToObjectSpace(p.CFrame)) end
		end
		model.PrimaryPart = padBase
	end
end
for _, n in ipairs({"LampBlinker", "UfoHover", "TractorBeam"}) do local s = model:FindFirstChild(n); if s then s:Destroy() end end
local blinker = Instance.new("Script"); blinker.Name = "LampBlinker"
blinker.Source = [[
local model = script.Parent
local rng = Random.new()
for _, lamp in ipairs(model:GetDescendants()) do
	if lamp:IsA("BasePart") and lamp.Name:find("Lamp") then
		task.spawn(function()
			local onColor = lamp.Color
			local offColor = onColor:Lerp(Color3.new(0, 0, 0), 0.7)
			local light = lamp:FindFirstChildOfClass("PointLight")
			local period = rng:NextNumber(0.5, 2.0)
			task.wait(rng:NextNumber(0, 2))
			while lamp.Parent do
				lamp.Material = Enum.Material.SmoothPlastic; lamp.Color = offColor
				if light then light.Enabled = false end
				task.wait(period * rng:NextNumber(0.3, 0.7))
				lamp.Material = Enum.Material.Neon; lamp.Color = onColor
				if light then light.Enabled = true end
				task.wait(period * rng:NextNumber(0.6, 1.4))
			end
		end)
	end
end
]]
blinker.Parent = model
local hover = Instance.new("Script"); hover.Name = "UfoHover"
hover.Source = [[
-- Hover + slow spin, positioned RELATIVE TO THE PAD every frame, so the saucer follows the pad
-- wherever the model is moved (including worlds that reposition the model after inserting it).
-- Dips while the beam works. When a player wiggles free (Escaped attribute) the ship spins up,
-- shoots away and fades out, then returns after RETURN_DELAY seconds.
local model = script.Parent
local RunService = game:GetService("RunService")
local hull = model:FindFirstChild("UfoHull")
local padBase = model:FindFirstChild("PadBase")
if not (hull and padBase) then return end
local DIP, RETURN_DELAY = 2.2, 14
local parts, baseT = {}, {}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= padBase and not p.Name:find("Pad") then
		local off = p:GetAttribute("HomeOffset") or padBase.CFrame:ToObjectSpace(p.CFrame)
		table.insert(parts, {p, off, p.Name:find("Beam") ~= nil})
		baseT[p] = p.Transparency
	end
end
local hullOff = hull:GetAttribute("HomeOffset") or padBase.CFrame:ToObjectSpace(hull.CFrame)
local centre = hullOff.Position
local function setHidden(alpha)   -- 0 = normal, 1 = invisible
	for _, e in ipairs(parts) do if not e[3] then local p = e[1]; p.Transparency = baseT[p] + (1 - baseT[p]) * alpha end end
end
local t, dip, ang = 0, 0, 0
local state, st = "home", 0
model:SetAttribute("ShipAway", false)
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local target = (model:GetAttribute("BeamActive") and state == "home") and -DIP or 0
	dip += (target - dip) * math.min(1, dt * 1.6)
	local offset = Vector3.new(0, math.sin(t * 1.4) * 0.35 + dip, 0)
	local spinRate = 0.3
	if state == "home" and model:GetAttribute("Escaped") then
		state, st = "leaving", 0
		model:SetAttribute("ShipAway", true)
	elseif state == "leaving" then
		st += dt
		local k = math.min(1, st / 2.6)
		offset += Vector3.new(34 * k * k, 48 * k * k, 18 * k * k)
		spinRate = 0.3 + 4 * k
		setHidden(math.clamp((k - 0.45) / 0.55, 0, 1))
		if st >= 2.6 then state, st = "gone", 0; setHidden(1) end
	elseif state == "gone" then
		st += dt
		offset += Vector3.new(0, 80, 0)
		if st >= RETURN_DELAY then state, st = "returning", 0 end
	elseif state == "returning" then
		st += dt
		local k = 1 - math.min(1, st / 3.2)
		offset += Vector3.new(0, 55 * k * k, 0)
		spinRate = 0.3 + 2 * k
		setHidden(math.clamp(k * 1.4 - 0.2, 0, 1))
		if st >= 3.2 then
			state, st = "home", 0; setHidden(0)
			model:SetAttribute("Escaped", false); model:SetAttribute("ShipAway", false)
		end
	end
	ang += spinRate * dt
	local base = padBase.CFrame
	local spin = CFrame.new(centre) * CFrame.Angles(0, ang, 0) * CFrame.new(-centre)
	local lift = CFrame.new(offset)
	for _, e in ipairs(parts) do
		if e[3] then
			e[1].CFrame = base * e[2]                    -- beam + sparkles: fixed to the pad
		else
			e[1].CFrame = base * (lift * spin * e[2])    -- saucer: spin about its centre, then bob/dip/fly
		end
	end
end)
]]
hover.Parent = model
local tractor = Instance.new("Script"); tractor.Name = "TractorBeam"
tractor.Source = [[
-- The beam stays off until a player or an unanchored object is on the pad's green circle.
-- Then it powers up (sound + fade in + sparkles), lifts what is there, and powers down when empty.
local model = script.Parent
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local beam = model:FindFirstChild("Beam")
local hull = model:FindFirstChild("UfoHull")
local pad = model:FindFirstChild("NeonLime_PadDisc")
local sparkles = model:FindFirstChild("BeamSparkles")
if not (beam and hull and pad) then return end
local ON_T = beam.Transparency
local ZONE_R = 2.9
local light = beam:FindFirstChildOfClass("PointLight")
local emitters = {}
if sparkles then for _, e in ipairs(sparkles:GetChildren()) do if e:IsA("ParticleEmitter") then table.insert(emitters, e) end end end
local hum = beam:FindFirstChild("BeamHum")
local start = beam:FindFirstChild("BeamStart")
local stop = beam:FindFirstChild("BeamStop")
local beep = beam:FindFirstChild("BeamBeep")
local click = beam:FindFirstChild("BeamClick")
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {model}
local active = false
local function setActive(on)
	if on == active then return end
	active = on
	activeSince = on and os.clock() or nil
	model:SetAttribute("BeamActive", on)
	for _, e in ipairs(emitters) do e.Enabled = on end
	if light then light.Enabled = on end
	if on then
		if click then click:Play() end
		if start then start:Play() end
		task.delay(0.8, function() if active and hum then hum:Play() end end)
		task.spawn(function()
			while active do
				if beep then beep:Play() end
				task.wait(0.85)
			end
		end)
		TweenService:Create(beam, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = ON_T}):Play()
	else
		if click then click:Play() end
		if stop then stop:Play() end
		if hum then hum:Stop() end
		if start then start:Stop() end
		TweenService:Create(beam, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	end
end
-- start hidden
beam.Transparency = 1
for _, e in ipairs(emitters) do e.Enabled = false end
if light then light.Enabled = false end
local held = {}      -- humanoids currently floating: humanoid -> struggle seconds
local immune = {}    -- humanoids recently released: humanoid -> time they can be grabbed again
local HOLD_TIME = 8          -- seconds the beam holds its catch before letting go
local COOLDOWN = 7           -- seconds the beam stays off afterwards
local WIGGLE_ENABLED = false -- true = mashing movement keys also breaks a player free
local WIGGLE_TIME = 0.8
local activeSince, cooldownUntil = nil, 0
RunService.Heartbeat:Connect(function(dt)
	local belly = hull.Position.Y - hull.Size.Y / 2
	local topChar, top = belly - 2.6, belly - 1.0
	local now = os.clock()
	if model:GetAttribute("ShipAway") then setActive(false); return end
	if now < cooldownUntil then
		if active then setActive(false) end
		return
	end
	if active and activeSince and now - activeSince > HOLD_TIME then
		-- time's up: drop everything, rest, and if a player was aboard the ship takes off
		local hadPlayer = false
		for humanoid in pairs(held) do hadPlayer = true; if humanoid.Parent then humanoid.PlatformStand = false end; immune[humanoid] = now + COOLDOWN + 2 end
		held = {}
		for _, m in ipairs(workspace:GetChildren()) do
			if m:IsA("Model") and m:GetAttribute("Lifted") then m:SetAttribute("Lifted", false); m:SetAttribute("BeamIgnoreUntil", now + COOLDOWN + 4) end
		end
		cooldownUntil = now + COOLDOWN
		setActive(false)
		if hadPlayer then model:SetAttribute("Escaped", true) end
		return
	end
	local cx, cz = pad.Position.X, pad.Position.Z
	local zoneCF = CFrame.new(cx, (pad.Position.Y + belly) / 2, cz)
	local zoneSize = Vector3.new(ZONE_R * 2, math.max(1, belly - pad.Position.Y), ZONE_R * 2)
	local found = false
	local seen = {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(zoneCF, zoneSize, params)) do
		local dx, dz = part.Position.X - cx, part.Position.Z - cz
		if math.sqrt(dx * dx + dz * dz) < ZONE_R then
			local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local root = humanoid.RootPart
				if immune[humanoid] and immune[humanoid] > now then
					-- just escaped: let them walk out without re-grabbing
				elseif root and not seen[humanoid] then
					found = true
					seen[humanoid] = true
					if active then
						if held[humanoid] == nil then held[humanoid] = 0; humanoid.PlatformStand = true end
						-- struggle: pushing movement keys builds up, letting go bleeds off
						if humanoid.MoveDirection.Magnitude > 0.1 then held[humanoid] += dt else held[humanoid] = math.max(0, held[humanoid] - dt * 0.5) end
						local rdx, rdz = root.Position.X - cx, root.Position.Z - cz
						if WIGGLE_ENABLED and held[humanoid] >= WIGGLE_TIME then
							-- break free: fling outward and away, then ignore them for a moment
							held[humanoid] = nil; humanoid.PlatformStand = false
							local out = Vector3.new(rdx, 0, rdz)
							out = (out.Magnitude > 0.1) and out.Unit or Vector3.new(1, 0, 0)
							root.AssemblyLinearVelocity = out * 28 + Vector3.new(0, 14, 0)
							immune[humanoid] = now + 2.5
							seen[humanoid] = nil
							model:SetAttribute("Escaped", true)
						else
							local up = math.clamp((topChar - root.Position.Y) * 1.2, -1.5, 9)
							root.AssemblyLinearVelocity = Vector3.new(-rdx * 0.6, up, -rdz * 0.6)
							root.AssemblyAngularVelocity = Vector3.new(0, 1.2, 0)
						end
					end
				end
			elseif not part.Anchored then
				found = true
				if active then
					local up = math.clamp((top - part.Position.Y) * 1.2, -1.5, 9)
					part.AssemblyLinearVelocity = Vector3.new(-dx * 0.6, up, -dz * 0.6)
					part.AssemblyAngularVelocity = Vector3.new(0, 1.2, 0)
				end
			end
		end
	end
	for humanoid in pairs(held) do
		if not seen[humanoid] then held[humanoid] = nil; if humanoid.Parent then humanoid.PlatformStand = false end end
	end
	-- anchored critters that opted in (attribute TractorTarget), e.g. the hound: lift by moving the model,
	-- hold for a few seconds, then let go and ignore him for a while so he can wander off
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("TractorTarget") then
			local pv = m:GetPivot()
			local dx, dz = pv.Position.X - cx, pv.Position.Z - cz
			local inZone = math.sqrt(dx * dx + dz * dz) < ZONE_R and pv.Position.Y < top + 2 and pv.Position.Y > pad.Position.Y - 3
			local until_ = m:GetAttribute("BeamIgnoreUntil") or 0
			if inZone and now >= until_ then
				found = true
				if active then
					if not m:GetAttribute("Lifted") then m:SetAttribute("Lifted", true); m:SetAttribute("LiftStart", now) end
					local up = math.clamp((top - 2.5 - pv.Position.Y) * 1.2, -1.5, 6)
					local newPos = pv.Position + Vector3.new(-dx * 0.6, up, -dz * 0.6) * dt
					m:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, math.rad(60) * dt, 0) * pv.Rotation)
				end
			elseif m:GetAttribute("Lifted") then
				m:SetAttribute("Lifted", false)
			end
		end
	end
	for humanoid, t in pairs(immune) do if t <= now then immune[humanoid] = nil end end
	setActive(found)
end)
]]
tractor.Parent = model
model:SetAttribute("BeamActive", false); model:SetAttribute("Escaped", false); model:SetAttribute("ShipAway", false)
model.Name = "UFO"
print("UFO: neon, lights, hover, blink and tractor beam applied")
