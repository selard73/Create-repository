-- PatchExtras: applied to the SAVED street without rebuilding it (a rebuild re-rolls the approved random colours).
-- 1. the two benches by the fountain turn sideways to face it; 2. every bike leans against its shop wall (no kickstand);
-- 3. the painter gets an easel; 4. the bird feeder gets pigeons. Run in edit mode: require(workspace.PatchExtras.PatchModule)()
return function()
	local C = Color3.fromRGB
	local village = workspace:WaitForChild("Village")
	local props = village:WaitForChild("Props")
	local kit = workspace:WaitForChild("VillageKit")
	local report = {}

	-- ---- the new kit pieces, regrouped from the import (village_extra.obj -> "<kit>__<piece>" MeshParts)
	do
		local groups = {}
		for _, p in ipairs(workspace:GetDescendants()) do
			if p:IsA("MeshPart") and not p:FindFirstAncestor("Village") and not p:FindFirstAncestor("VillageKit") and not p:FindFirstAncestor("Domaine") then
				local k, piece = p.Name:match("^(.-)__(.+)$")
				if k and piece and (k == "easel" or k == "pigeon" or k == "pigeon_b") then
					local g = groups[k]
					if not g then g = kit:FindFirstChild(k) if not g then g = Instance.new("Model"); g.Name = k; g.Parent = kit end groups[k] = g end
					p.Name = piece; p.Parent = g
				end
			end
		end
		for _, g in pairs(groups) do
			g.PrimaryPart = g:FindFirstChildWhichIsA("BasePart")
			for _, p in ipairs(g:GetDescendants()) do
				if p:IsA("BasePart") then p.Anchored = true; p.Transparency = 1; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false end
			end
		end
		for _, mdl in ipairs(workspace:GetChildren()) do
			if mdl:IsA("Model") and mdl.Name == "village_extra" and not mdl:FindFirstChildWhichIsA("BasePart", true) then mdl:Destroy() end
		end
	end

	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local function groundAt(x, z, ignore)
		rp.FilterDescendantsInstances = ignore or {}
		local r = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), rp)
		return r and r.Position.Y or 0
	end
	-- place a kit clone with its footprint centred on (x, z), resting on the ground, front (-Z) facing `yaw`
	local function place(kitName, x, z, yaw, cols)
		local t = kit:FindFirstChild(kitName)
		if not t then table.insert(report, "missing kit " .. kitName) return end
		local m = t:Clone(); m.Name = kitName
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Transparency = 0; p.CanCollide = true; p.CanQuery = true; p.CanTouch = true; p.Locked = true; p.Anchored = true
				p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
				local key
				for k in pairs(cols) do if p.Name:sub(1, #k) == k and (not key or #k > #key) then key = k end end
				if key then p.Color = cols[key] end
			end
		end
		m.Parent = props
		local gy = groundAt(x, z, {m})
		m:PivotTo(CFrame.new(x, gy, z) * CFrame.Angles(0, yaw + math.pi, 0))          -- + pi: Import 3D turns the kit round
		local bb, size = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(x - bb.Position.X, gy - (bb.Position.Y - size.Y / 2), z - bb.Position.Z))
		return m
	end
	local function facing(from, to) local d = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Unit return math.atan2(-d.X, -d.Z) end

	-- ---- 1. benches by the fountain: sideways, facing the fountain
	do
		local fountain
		for _, m in ipairs(props:GetChildren()) do if m.Name == "fountain" then fountain = m end end
		local fx = fountain and fountain:GetPivot().Position.X or 383.6
		local n = 0
		for _, m in ipairs(props:GetChildren()) do
			if m.Name == "bench" then
				local p = m:GetPivot().Position
				if math.abs(p.X - fx) > 10 then                       -- the two flanking benches (the third sits behind the fountain)
					local turn = (p.X < fx) and math.pi / 2 or -math.pi / 2
					m:PivotTo(CFrame.new(p) * CFrame.Angles(0, turn, 0) * CFrame.new(-p) * m:GetPivot())
					n += 1
				end
			end
		end
		table.insert(report, "benches turned " .. n)
	end

	-- ---- 2. bikes: against the shop wall, leaning on it, no kickstand
	do
		local n = 0
		for _, bike in ipairs(props:GetChildren()) do
			if bike.Name == "bicycle" then
				local bb, size = bike:GetBoundingBox()
				local ks = bike:FindFirstChild("Kickstand"); if ks then ks:Destroy() end
				-- straighten first (undo the kickstand lean about the wheels' contact line)
				local P0 = Vector3.new(bb.Position.X, bb.Position.Y - size.Y / 2, bb.Position.Z)
				local rot = bike:GetPivot().Rotation
				local tilt = math.asin(math.clamp(rot.UpVector.Z, -1, 1))      -- current lean about X
				bike:PivotTo(CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, -tilt) * CFrame.new(-P0) * bike:GetPivot())
				bb, size = bike:GetBoundingBox()
				-- which way is the shop? the nearer wall along z
				rp.FilterDescendantsInstances = {bike, village.HidingSpots}
				local o = Vector3.new(bb.Position.X, bb.Position.Y, bb.Position.Z)
				local hN = workspace:Raycast(o, Vector3.new(0, 0, -20), rp)
				local hS = workspace:Raycast(o, Vector3.new(0, 0, 20), rp)
				local dN = hN and (o.Z - hN.Position.Z) or 99
				local dS = hS and (hS.Position.Z - o.Z) or 99
				local wallZ, dz
				if dN < dS then wallZ = hN.Position.Z; dz = 1 else wallZ = hS.Position.Z; dz = -1 end   -- dz points from the wall toward the street
				if math.min(dN, dS) < 15 then
					local targetZ = wallZ + dz * 1.45
					bike:PivotTo(bike:GetPivot() + Vector3.new(0, 0, targetZ - bb.Position.Z))
					bb, size = bike:GetBoundingBox()
					P0 = Vector3.new(bb.Position.X, bb.Position.Y - size.Y / 2, bb.Position.Z)
					bike:PivotTo(CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, -math.rad(13) * dz) * CFrame.new(-P0) * bike:GetPivot())
					n += 1
				end
			end
		end
		table.insert(report, "bikes leaned " .. n)
		-- the dress shop's bike goes round the back of its house (Shannon), leaning on the back wall beside the back door
		local house
		for _, h in ipairs(props:GetChildren()) do
			if h.Name:find("townhouse") then local t = h:FindFirstChildWhichIsA("TextLabel", true) if t and t.Text == "MODE ET STYLE" then house = h end end
		end
		if house then
			local hb, hs = house:GetBoundingBox()
			local bike, bd
			for _, b in ipairs(props:GetChildren()) do
				if b.Name == "bicycle" then local dd = math.abs(b:GetBoundingBox().Position.X - hb.Position.X) if not bd or dd < bd then bike, bd = b, dd end end
			end
			if bike and bd < 12 then
				local street = village:FindFirstChild("Ground") and 0 or 0
				local backDz = (hb.Position.Z > -120) and 1 or -1                 -- the back faces away from the street (z -120)
				local backZ = hb.Position.Z + backDz * hs.Z / 2
				rp.FilterDescendantsInstances = {bike, village.HidingSpots}
				local probe = workspace:Raycast(Vector3.new(hb.Position.X - 6, hb.Position.Y - hs.Y / 2 + 2.5, backZ + backDz * 6), Vector3.new(0, 0, -backDz * 12), rp)
				local wallZ = probe and probe.Position.Z or backZ
				local doorX = hb.Position.X
				for _, pp in ipairs(house:GetDescendants()) do
					if pp:IsA("BasePart") and pp.Name:sub(1, 4) == "Door" and (pp.Position.Z - hb.Position.Z) * backDz > hs.Z * 0.3 then doorX = pp.Position.X end
				end
				local bx, bz = doorX - 5.2, wallZ + backDz * 1.45
				local bbk, sbk = bike:GetBoundingBox()
				local P0 = Vector3.new(bbk.Position.X, bbk.Position.Y - sbk.Y / 2, bbk.Position.Z)
				local tilt = math.asin(math.clamp(bike:GetPivot().Rotation.UpVector.Z, -1, 1))
				bike:PivotTo(CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, -tilt) * CFrame.new(-P0) * bike:GetPivot())
				bbk, sbk = bike:GetBoundingBox()
				rp.FilterDescendantsInstances = {bike}
				local rr = workspace:Raycast(Vector3.new(bx, 60, bz), Vector3.new(0, -120, 0), rp)
				local gy = rr and rr.Position.Y or (bbk.Position.Y - sbk.Y / 2)
				bike:PivotTo(bike:GetPivot() + Vector3.new(bx - bbk.Position.X, gy - (bbk.Position.Y - sbk.Y / 2), bz - bbk.Position.Z))
				bbk, sbk = bike:GetBoundingBox()
				P0 = Vector3.new(bbk.Position.X, bbk.Position.Y - sbk.Y / 2, bbk.Position.Z)
				bike:PivotTo(CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, math.rad(13) * backDz) * CFrame.new(-P0) * bike:GetPivot())
				table.insert(report, "dress-shop bike moved round the back")
			end
		end
	end

	-- the chocolatier's bike parks along the east side wall of the row's end building (the Librairie), in the place of
	-- the hedge bush nearest the street corner: no gap between the bushes is long enough for a bike (Shannon)
	do
		local lib, choc
		for _, h in ipairs(props:GetChildren()) do
			if h.Name:find("townhouse") then
				local t = h:FindFirstChildWhichIsA("TextLabel", true)
				if t and t.Text == "LIBRAIRIE" then lib = h elseif t and t.Text == "CHOCOLATIER" then choc = h end
			end
		end
		if lib and choc then
			local cb = choc:GetBoundingBox()
			local bike, bd
			for _, b in ipairs(props:GetChildren()) do
				if b.Name == "bicycle" then local dd = math.abs(b:GetBoundingBox().Position.X - cb.Position.X) if not bd or dd < bd then bike, bd = b, dd end end
			end
			local wallX = -1e9
			for _, p in ipairs(lib:GetDescendants()) do if p:IsA("BasePart") and p.Name:sub(1, 4) == "Wall" then wallX = math.max(wallX, p.Position.X + p.Size.X / 2) end end
			local lb, ls = lib:GetBoundingBox()
			local hedges = {}
			for _, m in ipairs(props:GetChildren()) do
				if m.Name == "hedge" then local bb = m:GetBoundingBox() if bb.Position.X > wallX and bb.Position.X < wallX + 5 and math.abs(bb.Position.Z - lb.Position.Z) < ls.Z then table.insert(hedges, {m = m, z = bb.Position.Z}) end end
			end
			local street = (lb.Position.Z > -120) and -1 or 1                     -- which way the street lies along z
			table.sort(hedges, function(a, b) return (a.z - b.z) * street > 0 end)  -- nearest the street first
			if bike and bd < 14 and #hedges > 0 then
				local slotZ = hedges[1].z; hedges[1].m:Destroy()
				local bb, sz = bike:GetBoundingBox()
				local P0 = Vector3.new(bb.Position.X, bb.Position.Y - sz.Y / 2, bb.Position.Z)
				local tilt = math.asin(math.clamp(bike:GetPivot().Rotation.UpVector.Z, -1, 1))
				bike:PivotTo(CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, -tilt) * CFrame.new(-P0) * bike:GetPivot())
				bb, sz = bike:GetBoundingBox()
				bike:PivotTo(CFrame.new(bb.Position) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(-bb.Position) * bike:GetPivot())
				bb, sz = bike:GetBoundingBox()
				local bx, bz = wallX + 1.45, slotZ
				rp.FilterDescendantsInstances = {bike}
				local rr = workspace:Raycast(Vector3.new(bx, 60, bz), Vector3.new(0, -120, 0), rp)
				local gy = rr and rr.Position.Y or (bb.Position.Y - sz.Y / 2)
				bike:PivotTo(bike:GetPivot() + Vector3.new(bx - bb.Position.X, gy - (bb.Position.Y - sz.Y / 2), bz - bb.Position.Z))
				bb, sz = bike:GetBoundingBox()
				P0 = Vector3.new(bb.Position.X, bb.Position.Y - sz.Y / 2, bb.Position.Z)
				bike:PivotTo(CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.zAxis, math.rad(13)) * CFrame.new(-P0) * bike:GetPivot())
				table.insert(report, "chocolatier bike parked on the Librairie side wall")
			end
		end
	end
	-- ---- 3 & 4. company for the squirrels, wherever they stand
	local CX, CZ, LEN = 260, -120, 180
	local function findSquirrel(pattern)
		-- the colour model is the one players see (Shannon places it; the gray twin only lends its texture and may lie anywhere)
		local best
		for _, inst in ipairs(workspace:GetChildren()) do
			if inst:IsA("Model") and inst.Name:lower():find(pattern, 1, true) and inst:FindFirstChild("Tail2", true) then
				if not best or (inst.Name:lower():find("color") and not best.Name:lower():find("color")) then best = inst end
			end
		end
		return best
	end
	local EASEL_COL = {Easel = C(150, 112, 76), Canvas = C(246, 242, 232), Pot = C(118, 118, 124), Brush = C(206, 162, 92),
		Paint1 = C(150, 196, 236), Paint2 = C(120, 170, 90), Paint3 = C(238, 218, 160), Paint4 = C(196, 86, 66), Paint5 = C(250, 214, 80), Paint6 = C(76, 128, 70), Paint7 = C(146, 96, 214)}
	local PIGEON_COL = {Pigeon = C(152, 154, 166), Wing = C(112, 114, 126), Beak = C(64, 62, 66), Leg = C(206, 116, 116), Sheen = C(96, 150, 118)}
	for _, m in ipairs(props:GetChildren()) do if m.Name == "easel" or m.Name == "pigeon" or m.Name == "pigeon_b" then m:Destroy() end end
	local function paintRiver(easel, painterPos)
		-- the painting is what the painter is looking at: the river in the foreground, the meadow, rocks, pines and plane trees
		local canvas = easel:FindFirstChild("Canvas")
		if not canvas then return end
		for _, p in ipairs(easel:GetChildren()) do if p.Name:match("^Paint%d") then p:Destroy() end end
		local cf = canvas.CFrame
		local s = ((cf * CFrame.new(0, 0, -1)).Position - painterPos).Magnitude < ((cf * CFrame.new(0, 0, 1)).Position - painterPos).Magnitude and -1 or 1
		local function q(name, x, y, w, h, col, dz)
			local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Locked = true
			p.Material = Enum.Material.SmoothPlastic; p.Color = col; p.Size = Vector3.new(w, h, 0.02); p.CastShadow = false
			p.CFrame = cf * CFrame.new(x, y, s * (0.05 + (dz or 0))); p.Parent = easel
		end
		q("Sky", 0, 0.45, 2.14, 0.92, C(150, 196, 236))
		q("Meadow", 0, -0.27, 2.14, 0.54, C(122, 172, 92))
		q("Bank", 0, -0.55, 2.14, 0.06, C(214, 196, 156), 0.002)
		q("River", 0, -0.73, 2.14, 0.30, C(104, 164, 218))
		q("Shore", 0, -0.94, 2.14, 0.12, C(122, 172, 92))
		for _, x in ipairs({-0.78, -0.48, 0.74}) do q("Pine", x, 0.14, 0.16, 0.44, C(58, 98, 66), 0.004); q("Trunk", x, -0.1, 0.05, 0.1, C(110, 82, 56), 0.004) end
		for _, x in ipairs({-0.08, 0.42}) do q("Tree", x, 0.1, 0.3, 0.26, C(98, 152, 74), 0.004); q("Trunk", x, -0.1, 0.05, 0.12, C(110, 82, 56), 0.004) end
		q("Rock", -0.55, -0.36, 0.3, 0.12, C(146, 150, 162), 0.004); q("Rock", 0.5, -0.42, 0.24, 0.1, C(146, 150, 162), 0.004); q("Rock", 0.05, -0.32, 0.14, 0.07, C(160, 164, 176), 0.004)
		q("Sun", 0.82, 0.7, 0.22, 0.22, C(250, 214, 80), 0.004)
	end
	local painter = findSquirrel("painter")
	if painter then
		local cf = painter:GetPivot()
		local at = cf.Position + cf.LookVector * 2.7 + cf.RightVector * 1.0
		local e = place("easel", at.X, at.Z, facing(at, cf.Position), EASEL_COL)
		if e then paintRiver(e, cf.Position) end
		table.insert(report, e and "easel by " .. painter.Name or "easel failed")
	else
		table.insert(report, "no painter squirrel found")
	end
	local feeder = findSquirrel("bird_feeder")
	if feeder then
		-- out on the open paving of the square, facing the fountain (Shannon: by the tree he was too hidden)
		local target = Vector3.new(260, 0, -95)
		rp.FilterDescendantsInstances = {feeder}
		local r = workspace:Raycast(Vector3.new(target.X, 60, target.Z), Vector3.new(0, -120, 0), rp)
		local gy = r and r.Position.Y or 0
		feeder:PivotTo(CFrame.new(target.X, gy + 2, target.Z) * CFrame.Angles(0, math.pi, 0))
		local fb, fs = feeder:GetBoundingBox()
		feeder:PivotTo(feeder:GetPivot() + Vector3.new(target.X - fb.Position.X, gy - (fb.Position.Y - fs.Y / 2), target.Z - fb.Position.Z))
		local cf = feeder:GetPivot()
		local n = 0
		for _, sp in ipairs({{-0.9, 2.2, "pigeon_b"}, {0.5, 1.8, "pigeon"}, {1.9, 2.5, "pigeon"}, {-2.4, 2.3, "pigeon_b"}, {0.05, 1.15, "pigeon"}}) do
			local dir = CFrame.Angles(0, sp[1], 0):VectorToWorldSpace(Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit)
			local at = cf.Position + dir * sp[2]
			if place(sp[3], at.X, at.Z, facing(at, cf.Position), PIGEON_COL) then n += 1 end
		end
		table.insert(report, n .. " pigeons by " .. feeder.Name)
	else
		table.insert(report, "no bird feeder squirrel found")
	end
	print("PatchExtras: " .. table.concat(report, "; "))
end
