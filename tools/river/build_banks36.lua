-- v36 river banks, MEASURED (v34 + level ground only under the parts that really stand on the ground: the lowest
-- parts of their model, underside below 0.7 - not canvases, seats or signs held up on legs): same banks as v31 (no re-cut), but terrain smooths each 4-stud cell with its neighbours,
-- so after writing, every column's surface is raycast and corrected, 4 rounds, until it sits where it was asked to.
-- (v31 notes:) the channel is re-cut from the ORIGINAL ground to follow the top of each bank (so the grass join sits
-- at the bank's lip), pads use each part's REAL underside and are wider, islets are bigger, the kerb runs under the
-- bridge. Run v32 (settle) a few seconds later to set floating props down onto the new ground.
-- (older notes:) v30 (v25 + ground under the street paving set low, water filled under the banks so the water
-- never shows a raised edge; the ground hides it wherever the ground is higher) (v18 + the bank tops lap 0.05 over the old ground, so its cut edge leaves no dark line), terrain heights corrected (Roblox draws a solid surface at cell centre + 4*occupancy,
-- measured by calib v16/v17) + a stone quay along the village houses. No new cut: the v10 channel stays.
-- (v10 notes:) Replaces v7's even channel: the mesh sand strips (BankL/BankR) are hidden, the Baseplate is
-- cut again from the ORIGINAL (ServerStorage.RiverBackup.Baseplate) with a wider channel, and the terrain gets banks
-- that wander and change along the river: grassy slopes, pebble beaches, short steep earth banks, mud at the
-- waterline. Things standing near the edge keep level ground under them ("pads"); under the street paving the pad is
-- stone, like a quay. The water level and depth stay as in v7. The lagoon's east rim is left alone.
local WATER_Y, DEEP = -0.9, -8
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local T = workspace.Terrain
local river = workspace.Village.Props.river
local W = river.Water
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("RiverBackup")
local orig = backup and backup:FindFirstChild("Baseplate")
local cur = workspace:FindFirstChild("Baseplate")
if not orig or orig:GetAttribute("RiverChannel") or not cur then P("STOP: backup Baseplate missing or wrong", orig, cur) return end
P("baseplate colours", cur.Color:ToHex(), cur.Material.Name, orig.Color:ToHex())

-- 1. the old water outline (same measurement as v7)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {W}
W.CanQuery = true
local function hit(x, z) return workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), rp) ~= nil end
local Z0, Z1, DZ = -918, 678, 2
local rows = {}
for z = Z0, Z1, DZ do
	local first, last
	for x = 88, 226 do if hit(x, z) then first = first or x; last = x end end
	if first then
		local a, b = first - 1, first
		for _ = 1, 6 do local m = (a + b) / 2; if hit(m, z) then b = m else a = m end end
		local c, d = last, last + 1
		for _ = 1, 6 do local m = (c + d) / 2; if hit(m, z) then c = m else d = m end end
		rows[z] = {c = (b + c) / 2, w = (c - b) / 2}
	end
end
W.CanQuery = false
for z, r in pairs(rows) do
	local a, b = rows[z - 4] or r, rows[z + 4] or r
	local s = (b.c - a.c) / 8
	r.k = 1 / math.sqrt(1 + s * s)
end
local function row(z) return rows[math.clamp(Z0 + math.floor((z - Z0) / DZ + 0.5) * DZ, Z0, Z1)] end
local function lerp(a, b, t) return a + (b - a) * math.clamp(t, 0, 1) end
local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local QX, QZ0, QZ1 = 163.9, -171, -69                -- the quay wall face (x) and its run along z
local function lagoonSide(z, side) return side < 0 and z > -224 and z < -136 end

-- 2. what each bank is like at a given z (side -1 = west/left, +1 = east/right)
local function bank(z, side)
	local wob = math.clamp(2.8 * math.noise(z / 33, side * 11.1 + 0.5, 0.3), -1.5, 1.5)
	local st = math.noise(z / 70, side * 5.3 + 2.2, 0.7)
	local width = 4 + 2 * math.clamp(st * 4, -1, 1)          -- 2 (steep) .. 6 (beach)
	local kind = (st > 0.2) and "beach" or ((st < -0.2) and "steep" or "grass")
	if lagoonSide(z, side) then width = math.min(width, 2.5); wob = math.min(wob, 0.3); kind = "grass" end
	if side > 0 and z > QZ0 and z < QZ1 then
		local r = row(z)
		return (QX - r.c) - r.w, 0.5, "quay"
	end
	return wob, width, kind
end

-- 3. pads: level ground under things that stand near the edge
local pads, islets = {}, {}
local bridge = workspace.Village.Props:FindFirstChild("bridge")
local modelMin = {}
local gpParams = RaycastParams.new(); gpParams.FilterType = Enum.RaycastFilterType.Include; gpParams.FilterDescendantsInstances = {workspace.Village.Ground}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsDescendantOf(river) and not d:IsDescendantOf(workspace.River) and d.Name ~= "Baseplate" and d.Size.Y < 60 and not d:IsDescendantOf(T) then
		local p = d.Position
		local r = row(p.Z)
		local bottom = p.Y - d.Size.Y / 2
		if r and bottom < 1.2 and math.abs(p.X - r.c) < r.w + 14 and d.Transparency < 1 then
			local over = math.abs(p.X - r.c) < r.w - 0.5
			local inRiverside = d:FindFirstAncestor("riverside") or d:FindFirstAncestor("plane_tree")
			if over and inRiverside then
				islets[#islets + 1] = {x = p.X, z = p.Z, r = math.max(d.Size.X, d.Size.Z) / 2 + 0.8}
			elseif not (over and bridge and d:IsDescendantOf(bridge)) and not d:IsDescendantOf(workspace:FindFirstChild("Lagoon") or river) then
				local cf, s = d.CFrame, d.Size / 2
				local xa, xb, za, zb = math.huge, -math.huge, math.huge, -math.huge
				for _, sx in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
					local w = cf * Vector3.new(sx * s.X, 0, sz * s.Z)
					xa = math.min(xa, w.X); xb = math.max(xb, w.X); za = math.min(za, w.Z); zb = math.max(zb, w.Z)
				end end
				local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = {d}
				local under = bottom
				local hu = workspace:Raycast(Vector3.new(p.X, bottom - 6, p.Z), Vector3.new(0, d.Size.Y + 12, 0), ip)
				if hu then under = hu.Position.Y end
				local m = d:FindFirstAncestorOfClass("Model")
				local mMin = bottom
				if m then
					mMin = modelMin[m]
					if not mMin then
						mMin = math.huge
						for _, q in ipairs(m:GetDescendants()) do if q:IsA("BasePart") and q.Transparency < 1 then mMin = math.min(mMin, q.Position.Y - q.Size.Y / 2) end end
						modelMin[m] = mMin
					end
				end
				local standing = under < 0.7 and bottom <= mMin + 0.35
				local onPaving = workspace:Raycast(Vector3.new(p.X, under + 0.1, p.Z), Vector3.new(0, -1.2, 0), gpParams)
				if standing and not onPaving then pads[#pads + 1] = {xa = xa, xb = xb, za = za, zb = zb, h = math.min(under - 0.06, 1.5),
					stone = d:IsDescendantOf(workspace.Village.Ground) or d.Name == "Walkway"} end
			end
		end
	end
end
-- bucket pads by 16-stud z bands
local bucket = {}
for _, pd in ipairs(pads) do
	for b = math.floor((pd.za - 5) / 16), math.floor((pd.zb + 5) / 16) do bucket[b] = bucket[b] or {}; table.insert(bucket[b], pd) end
end
P("pads", #pads, "islets", #islets)

-- 4. the ground's height + material at a point
local function ground(x, z)
	local r = row(z)
	if not r then return nil end
	local side = (x < r.c) and -1 or 1
	local wob, width, kind = bank(z, side)
	local we = r.w + wob
	local off = math.abs(x - r.c)
	local e = (off - we) * r.k                                   -- studs outside the water's edge
	local h, mat
	if e <= 0 then
		local u = off / we
		h = (u <= 0.4) and DEEP or lerp(DEEP, (kind == "quay") and -3 or (WATER_Y - 0.35), ease((u - 0.4) / 0.6))
		mat = (h < -3.5) and Enum.Material.Mud or ((kind == "beach") and Enum.Material.Pebble or Enum.Material.Mud)
	elseif kind == "quay" then
		h = -1.5; mat = Enum.Material.Rock
	elseif e < width then
		local t = e / width
		local pw = (kind == "steep") and 0.45 or ((kind == "beach") and 1.5 or 0.85)
		h = lerp(WATER_Y - 0.35, 0.05, t ^ pw)
		if h < WATER_Y + 0.3 then mat = (kind == "beach") and Enum.Material.Pebble or Enum.Material.Mud
		elseif kind == "beach" and t < 0.75 then mat = Enum.Material.Pebble
		elseif kind == "steep" and h < -0.3 then mat = Enum.Material.Ground
		else mat = Enum.Material.Grass end
	elseif e < width + 3.5 then
		h = 0.05; mat = Enum.Material.Grass
	else
		h = -0.5; mat = Enum.Material.Grass                           -- hidden under the old ground
	end
	for _, i in ipairs(islets) do
		local dd = math.sqrt((x - i.x) ^ 2 + (z - i.z) ^ 2)
		local IR = i.r + 1.5
		if dd < IR + 3 then
			local hi = (dd < IR) and -0.3 or lerp(-0.3, DEEP, ease((dd - IR) / 3))
			if hi > h then h = hi; if dd < IR + 1 then mat = Enum.Material.Rock end end
		end
	end
	for _, pd in ipairs(bucket[math.floor(z / 16)] or {}) do
		local dx = math.max(pd.xa - x, 0, x - pd.xb)
		local dz = math.max(pd.za - z, 0, z - pd.zb)
		local dd = math.sqrt(dx * dx + dz * dz)
		if dd < 3.5 and not (kind == "quay" and e > 0) then
			local hp = (dd <= 1.0) and pd.h or lerp(pd.h, DEEP, ease((dd - 1.0) / 2.5))
			if hp > h then
				h = hp
				if pd.stone and dd <= 1.2 then mat = Enum.Material.Rock
				elseif h > WATER_Y + 0.3 then mat = Enum.Material.Grass else mat = Enum.Material.Mud end
			end
		end
	end
	return h, e, mat, side
end

local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("RiverBanks")

if cur:GetAttribute("RiverChannel") ~= "v31 lip" then P("STOP: v31 channel not found") return end
-- 6. terrain
local x0, x1, z0, z1, y0, y1 = 84, 228, -920, 680, -12, 0
local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
local nx, ny, nz = (x1 - x0) / 4, (y1 - y0) / 4, (z1 - z0) / 4
local old = T:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
local sm, so, lq = old.SolidMaterial, old.SolidOccupancy, old.LiquidOccupancy
local cols = {}
for ix = 1, nx do
	for iz = 1, nz do
		local cx, cz = x0 + (ix - 0.5) * 4, z0 + (iz - 0.5) * 4
		local r = row(cz)
		local skip = not r or math.abs(cx - r.c) > r.w + 16 or (cx < 142 and cz > -224 and cz < -136)
		if not skip then
			local hs, n, eMin, votes = 0, 0, math.huge, {}
			for _, o in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
				local h, e, mat = ground(cx + o[1], cz + o[2])
				if h then hs += h; n += 1; eMin = math.min(eMin, e); votes[mat] = (votes[mat] or 0) + 1 end
			end
			if n == 4 and eMin < 13 then
				local best, bv = Enum.Material.Grass, -1
				for m, v in pairs(votes) do if v > bv or (v == bv and m ~= Enum.Material.Grass) then best, bv = m, v end end
				cols[#cols + 1] = {ix = ix, iz = iz, x = cx, z = cz, t = hs / 4, H = hs / 4, m = best}
			end
		end
	end
end
local function writeAll()
	for _, c in ipairs(cols) do
		for iy = 1, ny do
			local yb = y0 + (iy - 1) * 4
			sm[c.ix][iy][c.iz] = c.m
			so[c.ix][iy][c.iz] = math.clamp((c.H - (yb + 2)) / 4, 0, 1)
			lq[c.ix][iy][c.iz] = math.clamp((WATER_Y - yb) / 4, 0, 1)
		end
	end
	T:WriteVoxelChannels(region, 4, {SolidMaterial = sm, SolidOccupancy = so, LiquidOccupancy = lq})
end
writeAll()
P("terrain", #cols, "columns")
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {T}; tp.IgnoreWater = true
for it = 1, 5 do
	task.wait(5)
	local err, worst, n = 0, 0, 0
	for _, c in ipairs(cols) do
		local hit = workspace:Raycast(Vector3.new(c.x, 12, c.z), Vector3.new(0, -30, 0), tp)
		local y = hit and hit.Position.Y or -12
		local d = c.t - y
		err += math.abs(d); worst = math.max(worst, math.abs(d)); n += 1
		if it < 5 then c.H = math.clamp(c.H + 0.75 * d, c.t - 3.5, math.min(c.t + 3.5, 1.9)) end
	end
	P("round", it, string.format("mean %.2f worst %.2f", err / n, worst))
	if it < 5 then writeAll() end
end

-- 7. hide the even sand strips (kept, so they can come back)
for _, b in ipairs({river.BankL, river.BankR}) do
	if b:GetAttribute("OldTransparency") == nil then b:SetAttribute("OldTransparency", b.Transparency) end
	b.Transparency = 1; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
end
workspace.River:SetAttribute("Banks", "v36 " .. os.date("!%Y-%m-%d %H:%M"))
-- 8. the quay: a stone wall face into the water + a low kerb along the top (not under the bridge deck)
local R = workspace.River
local old = R:FindFirstChild("Quay"); if old then old:Destroy() end
local Q = Instance.new("Model"); Q.Name = "Quay"; Q.Parent = R
local function block(name, x0, x1, y0, y1, z0, z1, mat, col)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0); p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Material = mat; p.Color = col; p.Parent = Q
	return p
end
local wallCol, kerbCol = Color3.fromRGB(150, 138, 120), Color3.fromRGB(196, 186, 168)
block("Wall", QX, 165.2, -3.6, 0.25, QZ0, QZ1, Enum.Material.Cobblestone, wallCol)
local BZ0, BZ1 = -125, -115                                   -- the bridge deck's width: no kerb under it
block("Kerb", QX - 0.2, 165.6, 0.2, 0.75, QZ0, QZ1, Enum.Material.Limestone, kerbCol)
block("WallEndS", QX - 0.4, 165.6, -3.6, 0.75, QZ0 - 0.8, QZ0, Enum.Material.Limestone, kerbCol)
block("WallEndN", QX - 0.4, 165.6, -3.6, 0.75, QZ1, QZ1 + 0.8, Enum.Material.Limestone, kerbCol)
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("BANKS DONE")
