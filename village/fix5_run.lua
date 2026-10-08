return function()
	local C = Color3.fromRGB
	local out = {}
	local props = workspace.Village.Props
	local nb = 0
	for _, m in ipairs(props:GetChildren()) do
		if m.Name == "bicycle" then nb += 1; for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Locked = false end end end
	end
	table.insert(out, "bikes unlocked " .. nb)
	local function addSeats(model)
		if not model then return model end
		for _, c in ipairs(model:GetChildren()) do if c:IsA("Seat") then c:Destroy() end end
		local sc = model:GetScale()
		-- the imported templates' pivots sit far from their geometry, so build the frame from the mesh's bounding box
		-- (its centre is the kit origin) and only take the yaw from the pivot
		local bb, size = model:GetBoundingBox()
		local gy = bb.Position.Y - size.Y / 2
		local pv = CFrame.new(bb.Position.X, gy, bb.Position.Z) * model:GetPivot().Rotation
		local spots
		if model.Name == "bench" then spots = {{-1.2, 1.625, 0, 2.6, Vector3.new(2.2, 0.3, 1.5)}, {1.2, 1.625, 0, 2.6, Vector3.new(2.2, 0.3, 1.5)}}
		else spots = {{0, 1.475, -2.1, 2.4, Vector3.new(1.5, 0.3, 1.5)}, {0, 1.475, 2.1, 2.4, Vector3.new(1.5, 0.3, 1.5)}} end
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = {model}
		for _, sp in ipairs(spots) do
			local centre = pv * Vector3.new(sp[1] * sc, 0, sp[3] * sc)
			local pos = Vector3.new(centre.X, gy + (sp[2] + 0.15) * sc - 0.15, centre.Z)
			local probe = Vector3.new(centre.X, gy + sp[4] * sc, centre.Z)
			local fwd = -pv.LookVector                                          -- the back (if any) is on one side of the cushion
			local hitF = workspace:Raycast(probe, fwd * 1.4 * sc, params)
			local hitB = workspace:Raycast(probe, -fwd * 1.4 * sc, params)
			if hitF and not hitB then fwd = -fwd end
			if model.Name ~= "bench" then fwd = (Vector3.new(pv.Position.X, pos.Y, pv.Position.Z) - pos).Unit end   -- chairs face the table
			local seat = Instance.new("Seat"); seat.Name = "ChairSeat"; seat.Anchored = true; seat.CanCollide = true; seat.CanQuery = false
			seat.Transparency = 1; seat.Locked = true; seat.Size = sp[5] * sc
			seat.CFrame = CFrame.lookAt(pos, pos + fwd)
			seat.Parent = model
		end
		return model
	end
	local ns, nm = 0, 0
	for _, m in ipairs(props:GetChildren()) do
		if m.Name == "bench" or m.Name == "cafe_table" then addSeats(m); nm += 1; for _, c in ipairs(m:GetChildren()) do if c:IsA("Seat") then ns += 1 end end end
	end
	table.insert(out, "seats " .. ns .. " on " .. nm)
	local function fountainSpray(model)
	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	if not base then return model end
	for _, n in ipairs({"Jet", "JetTop", "Spout", "Mist", "Splash", "RimStream", "RimRing", "Stem", "Cap", "CapRim"}) do
		local old = model:FindFirstChild(n, true)
		while old do old:Destroy() old = model:FindFirstChild(n, true) end
	end
	local bb, size = model:GetBoundingBox()
	local s = model:GetScale()
	local bottom = bb.Position.Y - size.Y / 2
	local cx, cz = bb.Position.X, bb.Position.Z
	local function streaks(parent, name, rate, speedLo, speedHi, spread, life, size0, size1, accel)
		local pe = Instance.new("ParticleEmitter"); pe.Name = name
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(C(205, 232, 255), C(240, 248, 255))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size0), NumberSequenceKeypoint.new(1, size1)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1)})
		pe.Squash = NumberSequence.new(-2.5)                           -- NEGATIVE = taller: long thin drops along their motion
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
		pe.Lifetime = NumberRange.new(life * 0.9, life * 1.1); pe.Rate = rate; pe.Speed = NumberRange.new(speedLo, speedHi)
		pe.SpreadAngle = Vector2.new(spread, spread); pe.Acceleration = Vector3.new(0, accel or -30, 0); pe.Drag = 0.1
		pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.05; pe.LightInfluence = 0.6
		pe.Parent = parent
		return pe
	end
	local function glass(name, shape, sz, cf, tr)
		local w = Instance.new("Part"); w.Name = name; w.Shape = shape; w.Anchored = true; w.CanCollide = false; w.CanQuery = false; w.Locked = true
		w.Material = Enum.Material.Glass; w.Color = C(175, 218, 242); w.Transparency = tr; w.CastShadow = false
		w.Size = sz; w.CFrame = cf; w.Parent = model
		return w
	end
	-- the top: a slim column shoots straight up from the finial and opens into an umbrella, whose edge slips off and
	-- falls gently into the upper bowl
	local spoutY = bottom + 6.4 * s
	local rise = 1.6 * s
	local apexY = spoutY + rise
	local capR, capY = 1.15 * s, spoutY + rise - 0.2 * s
	glass("Stem", Enum.PartType.Cylinder, Vector3.new(rise, 0.34 * s, 0.34 * s), CFrame.new(cx, spoutY + rise / 2, cz) * CFrame.Angles(0, 0, math.rad(90)), 0.35)
	local cap = glass("Cap", Enum.PartType.Block, Vector3.new(2 * capR, 0.7 * s, 2 * capR), CFrame.new(cx, capY, cz), 0.45)
	local capMesh = Instance.new("SpecialMesh"); capMesh.MeshType = Enum.MeshType.Sphere; capMesh.Parent = cap   -- a Ball part stays round; the mesh stretches into the umbrella
	local spout = Instance.new("Attachment"); spout.Name = "Spout"; spout.Parent = base
	spout.WorldCFrame = CFrame.new(cx, spoutY, cz)
	local v = math.sqrt(2 * 30 * rise)                                     -- just reaches the cap, then vanishes into it
	local col = streaks(spout, "Column", 70, v * 0.97, v * 1.03, 2, v / 30, 0.16 * s, 0.22 * s, -30)
	col.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1)})
	local nCap = 18
	for i = 1, nCap do
		local ang = (i - 0.5) / nCap * 2 * math.pi
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local pos = Vector3.new(cx, capY, cz) + out * capR
		local dir = (out * 0.995 - Vector3.yAxis * 0.09).Unit              -- just below level: it slips off the edge, arcs out, then drops
		local a = Instance.new("Attachment"); a.Name = "CapRim"; a.Parent = base
		a.WorldCFrame = CFrame.fromMatrix(pos, dir:Cross(Vector3.yAxis).Unit, dir)
		streaks(a, "Drip", 34, 1.2 * s, 1.5 * s, 3, 0.72, 0.14 * s, 0.2 * s, -22)
	end
	-- the curtain: thin streams spilling over the upper bowl's rim, thrown a little outward, falling into the basin
	local rimR, rimY = 2.2 * s, bottom + 4.7 * s
	local n = 20
	for i = 1, n do
		local ang = (i - 1) / n * 2 * math.pi
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local pos = Vector3.new(cx, rimY, cz) + out * rimR
		local dir = (out * 0.94 + Vector3.yAxis * 0.34).Unit                  -- outward, 20 degrees above level
		local a = Instance.new("Attachment"); a.Name = "RimStream"; a.Parent = base
		a.WorldCFrame = CFrame.fromMatrix(pos, dir:Cross(Vector3.yAxis).Unit, dir)
		streaks(a, "Stream", 42, 2.0 * s, 2.6 * s, 4, 0.9, 0.14 * s, 0.19 * s, -30)
	end
	-- a thin glassy sheet just over the rim so the spill reads as water even at a distance
	local ring = Instance.new("Part"); ring.Name = "RimRing"; ring.Shape = Enum.PartType.Cylinder; ring.Anchored = true; ring.CanCollide = false; ring.CanQuery = false; ring.Locked = true
	ring.Material = Enum.Material.Glass; ring.Color = C(170, 215, 240); ring.Transparency = 0.55; ring.CastShadow = false
	ring.Size = Vector3.new(0.06, 2 * rimR + 0.16 * s, 2 * rimR + 0.16 * s)
	ring.CFrame = CFrame.new(cx, rimY + 0.03, cz) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = model
	return model
	end
	local fm
	for _, m in ipairs(props:GetChildren()) do if m.Name == "fountain" then fm = m break end end
	fountainSpray(fm)
	table.insert(out, "fountain v5 " .. tostring(fm ~= nil) .. " cap " .. tostring(fm and fm:FindFirstChild("Cap") ~= nil))
	local function firefighter()
	local ff
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and (m:GetAttribute("SquirrelId") == "firefighter_squirrel" or m.Name:lower():find("firefighter")) then ff = m break end
	end
	if not ff then return "firefighter: not found" end
	-- stand him upright first (same heading, same feet point) so the feet offset is measured from a known pose
	local pv = ff:GetPivot()
	local look = pv.LookVector
	local f = Vector3.new(look.X, 0, look.Z)
	if f.Magnitude < 0.05 then f = Vector3.new(pv.RightVector.Z, 0, -pv.RightVector.X) end
	f = f.Unit
	ff:PivotTo(CFrame.lookAt(pv.Position, pv.Position + f))
	local bb, sz = ff:GetBoundingBox()
	pv = ff:GetPivot()
	local feetLocal = pv:PointToObjectSpace(Vector3.new(bb.Position.X, bb.Position.Y - sz.Y / 2, bb.Position.Z))
	-- the roof under his feet: only Roof pieces count, cast from high above so nothing he overlaps gets skipped
	local roofs = {}
	for _, p in ipairs(workspace.Village.Props:GetDescendants()) do if p:IsA("BasePart") and p.Name == "Roof" then table.insert(roofs, p) end end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = roofs
	local P = pv.Position
	local hit = workspace:Raycast(Vector3.new(P.X, P.Y + 60, P.Z), Vector3.new(0, -120, 0), params)
	if not hit then return "firefighter: no roof under him at " .. tostring(P) .. " (left upright)" end
	local n = hit.Normal
	local g = (f - n * f:Dot(n)).Unit
	ff:PivotTo(CFrame.fromMatrix(hit.Position, g:Cross(n), n) * CFrame.new(-feetLocal))
	return string.format("firefighter: on the roof of %s, slope %.0f deg, feet offset %.2f %.2f %.2f, was %.2f above it",
		hit.Instance.Parent and hit.Instance.Parent.Name or "?", math.deg(math.acos(math.clamp(n.Y, -1, 1))),
		feetLocal.X, feetLocal.Y, feetLocal.Z, P.Y - hit.Position.Y)
	end
	table.insert(out, firefighter())
	print("FIX5: " .. table.concat(out, " | "))
end
