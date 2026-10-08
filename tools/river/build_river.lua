-- v7 river -> real terrain water. MODE "dry" = measure + report only; "build" = cut the Baseplate + write terrain.
-- The river mesh (Village.Props.river: Water, BankL, BankR) lies ON the Baseplate (top y 0). The sand banks stay.
-- The Water mesh is hidden (kept in place, Transparency 1, no collision) and the Baseplate union gets a channel cut
-- along the water's outline (+1.5 studs under each sand bank). Terrain fills the channel: sand bed ~8 deep in the
-- middle, sloping up to the banks, water to WATER_Y. Old terrain outside the channel is kept exactly as it was.
local MODE = "build"
local WATER_Y, DEEP, UNDER = -0.9, -8, 1.5
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local function r1(v) return math.floor(v * 10 + 0.5) / 10 end
local T = workspace.Terrain
local river = workspace.Village.Props.river
local W = river.Water
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {W}
local wasCQ = W.CanQuery; W.CanQuery = true
local function hit(x, z) return workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), rp) ~= nil end

-- 1. the water's outline, one row every 2 studs of z: left edge L, right edge R
local Z0, Z1, DZ = -918, 678, 2
local rows = {}
local nRows = 0
for z = Z0, Z1, DZ do
	local first, last
	for x = 88, 226 do if hit(x, z) then first = first or x; last = x end end
	if first then
		local a, b = first - 1, first            -- refine the left edge: a miss, b hit
		for _ = 1, 6 do local m = (a + b) / 2; if hit(m, z) then b = m else a = m end end
		local c, d = last, last + 1              -- right edge: c hit, d miss
		for _ = 1, 6 do local m = (c + d) / 2; if hit(m, z) then c = m else d = m end end
		rows[z] = {L = b, R = c, c = (b + c) / 2, w = (c - b) / 2}
		nRows += 1
	end
end
W.CanQuery = wasCQ
local function row(z)
	local zz = math.clamp(Z0 + math.floor((z - Z0) / DZ + 0.5) * DZ, Z0, Z1)
	return rows[zz]
end
-- perpendicular factor per row (the river crosses rows at a slant on the bends)
for z, r in pairs(rows) do
	local a, b = rows[z - 2 * DZ] or r, rows[z + 2 * DZ] or r
	local s = (b.c - a.c) / (4 * DZ)
	r.k = 1 / math.sqrt(1 + s * s)
end
P("rows", nRows)
for _, z in ipairs({-206, -186, -120, -56, -26, -6, 4, 14}) do local r = rows[z] if r then P("row", z, r1(r.L), r1(r.R), "k", r1(r.k)) end end

-- 2. anything standing in the water (bottom below y 1.2, centre over the water)
local skip = {[river] = true}
local seen = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsDescendantOf(river) and d.Name ~= "Baseplate" and d.Size.Y < 60 and d.Transparency < 1 then
		local p = d.Position
		local bottom = p.Y - d.Size.Y / 2
		local r = row(p.Z)
		if r and bottom < 1.2 and math.abs(p.X - r.c) < r.w + 0.5 then
			local m = d:FindFirstAncestorOfClass("Model") or d
			if not seen[m] then seen[m] = true; P("inwater", d:GetFullName(), r1(p.X), r1(p.Y), r1(p.Z), "bottom", r1(bottom), "u", r1(math.abs(p.X - r.c) / r.w)) end
		end
	end
end
local islets = {}
for _, d in ipairs(workspace.Village.Props:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsDescendantOf(river) and (d:FindFirstAncestor("riverside") or d:FindFirstAncestor("plane_tree")) then
		local p = d.Position
		local r = row(p.Z)
		if r and p.Y - d.Size.Y / 2 < 1.2 and math.abs(p.X - r.c) < r.w * 1.05 then
			islets[#islets + 1] = {x = p.X, z = p.Z, r = math.max(d.Size.X, d.Size.Z) / 2 + 0.8}
		end
	end
end
P("islets", #islets)
-- ground parts other than the Baseplate that the channel margin reaches
for _, g in ipairs(workspace.Village.Ground:GetChildren()) do
	if g:IsA("BasePart") then P("groundpart", g.Name, r1(g.Position.X - g.Size.X / 2), r1(g.Position.X + g.Size.X / 2), r1(g.Position.Z - g.Size.Z / 2), r1(g.Position.Z + g.Size.Z / 2), "top", r1(g.Position.Y + g.Size.Y / 2)) end
end
local bp = workspace:FindFirstChild("Baseplate")
P("baseplate", bp and bp.ClassName, bp and bp:GetAttribute("LagoonHole"), bp and bp:GetAttribute("RiverChannel"))

-- 3. the cutters: a box per segment along the centre line + a round cap at every joint
local pts = {}
for z = Z0, Z1, 12 do local r = row(z) if r then pts[#pts + 1] = {x = r.c, z = z, p = r.w * r.k} end end
P("cutpoints", #pts)

-- the bed's height at a point, and how far outside the water's edge it is (studs, perpendicular)
local function lerp(a, b, t) return a + (b - a) * math.clamp(t, 0, 1) end
local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local function bed(x, z)
	local r = row(z)
	if not r then return nil end
	local off = math.abs(x - r.c)
	local u = off / r.w
	local out = (off - r.w) * r.k
	local h
	if u <= 0.4 then h = DEEP
	elseif out < 0 then h = lerp(DEEP, WATER_Y - 0.5, ease((u - 0.4) / 0.6))
	elseif out < UNDER + 1 then h = lerp(WATER_Y - 0.5, -0.15, ease(out / (UNDER + 1)))
	else h = -0.15 end
	local rock = false
	for _, i in ipairs(islets) do
		local dd = math.sqrt((x - i.x) ^ 2 + (z - i.z) ^ 2)
		if dd < i.r + 3 then
			local hi = lerp(-0.25, DEEP, ease((dd - i.r) / 3))
			if dd < i.r then hi = -0.25 end
			if hi > h then h = hi; rock = rock or (dd < i.r + 1) end
		end
	end
	return h, out, rock
end

if MODE ~= "build" then P("DRY DONE") return end

-- ================================================================ BUILD ====
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("RiverWater")
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("RiverBackup") or Instance.new("Folder"); backup.Name = "RiverBackup"; backup.Parent = SS

-- 4. cut the channel (once)
if not bp:GetAttribute("RiverChannel") then
	local cutters = {}
	local function cut(part) part.Anchored = true; part.CanCollide = false; part.Parent = workspace; cutters[#cutters + 1] = part end
	for i, a in ipairs(pts) do
		local cyl = Instance.new("Part"); cyl.Shape = Enum.PartType.Cylinder
		local dia = 2 * (a.p + UNDER)
		cyl.Size = Vector3.new(14, dia, dia)
		cyl.CFrame = CFrame.new(a.x, -5, a.z) * CFrame.Angles(0, 0, math.rad(90))
		cut(cyl)
		local b = pts[i + 1]
		if b and b.z - a.z <= 12 then
			local mid = Vector3.new((a.x + b.x) / 2, -5, (a.z + b.z) / 2)
			local len = math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
			local box = Instance.new("Part")
			box.Size = Vector3.new(2 * ((a.p + b.p) / 2 + UNDER), 14, len + 0.2)
			box.CFrame = CFrame.lookAt(mid, Vector3.new(b.x, -5, b.z))
			cut(box)
		end
	end
	local ok, u = pcall(function()
		return bp:SubtractAsync(cutters, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise)
	end)
	for _, c in ipairs(cutters) do c:Destroy() end
	if not ok or not u then P("CUT FAILED", tostring(u)); if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel) end return end
	u.Name = "Baseplate"; u.Anchored = true; u.CanCollide = true; u.Locked = bp.Locked
	u.Material = bp.Material; u.Color = bp.Color; u.UsePartColor = true
	u.CastShadow = bp.CastShadow; u.TopSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(bp:GetAttributes()) do u:SetAttribute(k, v) end
	u:SetAttribute("RiverChannel", true)
	for _, ch in ipairs(bp:GetChildren()) do ch.Parent = u end
	local keep = backup:FindFirstChild("Baseplate"); if keep then keep:Destroy() end
	bp.Parent = backup                                            -- the union as it was (with the lagoon hole)
	u.Parent = workspace
	bp = u
	P("cut", #cutters, "cutters", u.ClassName)
else
	P("cut already there")
end

-- 5. terrain: bed + water inside the channel, everything else untouched
local x0, x1, z0, z1, y0, y1 = 84, 228, -920, 680, -12, 0
local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
local nx, ny, nz = (x1 - x0) / 4, (y1 - y0) / 4, (z1 - z0) / 4
local old = T:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
local sm, so, lq = old.SolidMaterial, old.SolidOccupancy, old.LiquidOccupancy
local cols, wcells = 0, 0
for ix = 1, nx do
	for iz = 1, nz do
		local cx, cz = x0 + (ix - 0.5) * 4, z0 + (iz - 0.5) * 4
		local hs, n, outMin, rocky = 0, 0, math.huge, 0
		for _, o in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
			local h, out, rock = bed(cx + o[1], cz + o[2])
			if h then hs += h; n += 1; outMin = math.min(outMin, out); if rock then rocky += 1 end end
		end
		if n == 4 and outMin < UNDER + 3 then
			cols += 1
			local h = hs / 4
			for iy = 1, ny do
				local yb = y0 + (iy - 1) * 4
				sm[ix][iy][iz] = (rocky >= 2) and Enum.Material.Rock or ((h < -3.5) and Enum.Material.Mud or Enum.Material.Sand)
				so[ix][iy][iz] = math.clamp((h - yb) / 4, 0, 1)
				local l = 0
				if h < WATER_Y then l = math.clamp((WATER_Y - yb) / 4, 0, 1) end
				lq[ix][iy][iz] = l
				if l > 0 then wcells += 1 end
			end
		end
	end
end
T:WriteVoxelChannels(region, 4, {SolidMaterial = sm, SolidOccupancy = so, LiquidOccupancy = lq})
P("terrain", cols, "columns", wcells, "water cells")

-- 6. hide the old water sheet (kept, so it can come back)
W:SetAttribute("OldTransparency", W.Transparency)
W.Transparency = 1; W.CanCollide = false; W.CanQuery = false; W.CanTouch = false; W.CastShadow = false

-- 7. the centre line for the current (downstream = north -> south), on workspace.River
local R = workspace:FindFirstChild("River") or Instance.new("Folder"); R.Name = "River"; R.Parent = workspace
local line = {}
for z = 80, -300, -6 do local r = row(z) if r then line[#line + 1] = string.format("%.1f,%d,%.1f", r.c, z, r.w * r.k) end end
R:SetAttribute("WaterY", WATER_Y)
R:SetAttribute("Line", table.concat(line, ";"))
R:SetAttribute("Built", "v6 " .. os.date("!%Y-%m-%d %H:%M"))
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("BUILD DONE", #line, "line points")
