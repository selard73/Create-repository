-- v18 natural river banks, terrain heights corrected (Roblox draws a solid surface at cell centre + 4*occupancy,
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
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsDescendantOf(river) and d.Name ~= "Baseplate" and d.Size.Y < 60 and not d:IsDescendantOf(T) then
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
				pads[#pads + 1] = {xa = xa, xb = xb, za = za, zb = zb, h = math.min(bottom - 0.05, -0.05),
					stone = d:IsDescendantOf(workspace.Village.Ground) or d.Name == "Walkway"}
			end
		end
	end
end
-- bucket pads by 16-stud z bands
local bucket = {}
for _, pd in ipairs(pads) do
	for b = math.floor((pd.za - 3) / 16), math.floor((pd.zb + 3) / 16) do bucket[b] = bucket[b] or {}; table.insert(bucket[b], pd) end
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
		h = -0.1; mat = Enum.Material.Rock
	elseif e < width then
		local t = e / width
		local pw = (kind == "steep") and 0.45 or ((kind == "beach") and 1.5 or 0.85)
		h = lerp(WATER_Y - 0.35, -0.08, t ^ pw)
		if h < WATER_Y + 0.3 then mat = (kind == "beach") and Enum.Material.Pebble or Enum.Material.Mud
		elseif kind == "beach" and t < 0.75 then mat = Enum.Material.Pebble
		elseif kind == "steep" and h < -0.3 then mat = Enum.Material.Ground
		else mat = Enum.Material.Grass end
	else
		h = -0.08; mat = Enum.Material.Grass
	end
	for _, i in ipairs(islets) do
		local dd = math.sqrt((x - i.x) ^ 2 + (z - i.z) ^ 2)
		if dd < i.r + 3 then
			local hi = (dd < i.r) and -0.25 or lerp(-0.25, DEEP, ease((dd - i.r) / 3))
			if hi > h then h = hi; if dd < i.r + 1 then mat = Enum.Material.Rock end end
		end
	end
	for _, pd in ipairs(bucket[math.floor(z / 16)] or {}) do
		local dx = math.max(pd.xa - x, 0, x - pd.xb)
		local dz = math.max(pd.za - z, 0, z - pd.zb)
		local dd = math.sqrt(dx * dx + dz * dz)
		if dd < 2.6 then
			local hp = (dd <= 0.6) and pd.h or lerp(pd.h, DEEP, ease((dd - 0.6) / 2))
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

if cur:GetAttribute("RiverChannel") ~= "v10 banks" then P("STOP: v10 channel not found") return end
-- 6. terrain
local x0, x1, z0, z1, y0, y1 = 84, 228, -920, 680, -12, 0
local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
local nx, ny, nz = (x1 - x0) / 4, (y1 - y0) / 4, (z1 - z0) / 4
local old = T:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
local sm, so, lq = old.SolidMaterial, old.SolidOccupancy, old.LiquidOccupancy
local cols = 0
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
			if n == 4 and eMin < 11 then
				cols += 1
				local h = hs / 4
				local best, bv = Enum.Material.Grass, -1
				for m, v in pairs(votes) do if v > bv or (v == bv and m ~= Enum.Material.Grass) then best, bv = m, v end end
				for iy = 1, ny do
					local yb = y0 + (iy - 1) * 4
					sm[ix][iy][iz] = best
					so[ix][iy][iz] = math.clamp((h - (yb + 2)) / 4, 0, 1)
					lq[ix][iy][iz] = (h < WATER_Y) and math.clamp((WATER_Y - yb) / 4, 0, 1) or 0
				end
			end
		end
	end
end
T:WriteVoxelChannels(region, 4, {SolidMaterial = sm, SolidOccupancy = so, LiquidOccupancy = lq})
P("terrain", cols, "columns")

-- 7. hide the even sand strips (kept, so they can come back)
for _, b in ipairs({river.BankL, river.BankR}) do
	if b:GetAttribute("OldTransparency") == nil then b:SetAttribute("OldTransparency", b.Transparency) end
	b.Transparency = 1; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
end
workspace.River:SetAttribute("Banks", "v18 " .. os.date("!%Y-%m-%d %H:%M"))
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
block("Kerb", QX - 0.2, 165.6, 0.2, 0.75, QZ0, BZ0, Enum.Material.Limestone, kerbCol)
block("Kerb", QX - 0.2, 165.6, 0.2, 0.75, BZ1, QZ1, Enum.Material.Limestone, kerbCol)
block("WallEndS", QX - 0.4, 165.6, -3.6, 0.75, QZ0 - 0.8, QZ0, Enum.Material.Limestone, kerbCol)
block("WallEndN", QX - 0.4, 165.6, -3.6, 0.75, QZ1, QZ1 + 0.8, Enum.Material.Limestone, kerbCol)
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("BANKS DONE")
