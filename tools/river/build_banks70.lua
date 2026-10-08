-- v70 (v67 + under paving the ground may never climb above slab top - 0.35 (the correction rounds overshot and
-- grass came through the walkway); forest-side kerb reaches into the ground; white capstone under the bridge deck)
-- (v67: v60 + a short stone quay on the FOREST side of the bridge: wall face x 144.3, z -132..-108, kerb beside
-- the bridge but not under its deck, grass behind where there is no walkway) (v60: v59 + ground flush under ALL paving slabs, also along the quay, so nothing shows under them; the level
-- zone round the painter/easel/gallery widened to 6 studs so the water keeps well away) (v59: v55 with the beaches in SAND: Pebble is not a terrain material, Roblox silently stored it as Grass) (v55: v52 terrain only, no re-cut; the sandy band reaches 6 studs from the water so it shows in the first dry
-- 4-stud terrain cell even on steep banks) (v52: v51 + the old ground cut back 6 studs past each bank top, so the whole band is terrain)
-- (v51: v50 + level-ground patches keep the bank's sandy band instead of painting it grass)
-- (v50: v47 with a band wide enough to show in 4-stud terrain: wet mud 1.5, sand/earth to 4 studs from the water)
-- (v47: v43 + a narrow wet-mud band at the waterline, a little sand above it, darker earth at the quay ends; nothing
-- raised under things standing on the river's own rocks) river banks + ONE GROUND: terrain grass laid over the whole map (x -136..712, z -260..40) wherever there is no
-- terrain yet, so the meadows, forest floor and banks are one surface with no seam; sandy/earthy worn band at the
-- waterline; the bank swings out to meet the quay wall at both ends; wider level ground round the painter, his easel
-- and the portrait gallery; rock islets under the water. (v39:) (v36 + the rock islets sit just above the waterline, so rocks rise out of the water), MEASURED (v34 + level ground only under the parts that really stand on the ground: the lowest
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
local COVER = 0.08                                   -- the one ground height (terrain grass, a hair over the old ground)
local QX, QZ0, QZ1 = 163.9, -171, -69                -- the quay wall face (x) and its run along z
local QXW, QWZ0, QWZ1 = 144.3, -132, -108          -- the forest-side quay by the bridge
local function lagoonSide(z, side) return side < 0 and z > -224 and z < -136 end

-- 2. what each bank is like at a given z (side -1 = west/left, +1 = east/right)
local function bank(z, side)
	local wob = math.clamp(2.8 * math.noise(z / 33, side * 11.1 + 0.5, 0.3), -1.5, 1.5)
	local st = math.noise(z / 70, side * 5.3 + 2.2, 0.7)
	local width = 4 + 2 * math.clamp(st * 4, -1, 1)          -- 2 (steep) .. 6 (beach)
	local kind = (st > 0.2) and "beach" or ((st < -0.2) and "steep" or "grass")
	if lagoonSide(z, side) then width = math.min(width, 2.5); wob = math.min(wob, 0.3); kind = "grass" end
	if side > 0 then
		local dq = (z >= QZ1) and (z - QZ1) or ((z <= QZ0) and (QZ0 - z) or nil)
		if dq and dq < 16 then
			local r = row(z)
			local t = ease(dq / 16)
			wob = lerp((QX - r.c) - r.w, wob, t); width = lerp(1.5, width, t)
			kind = "steep"                                              -- earth, not sand, where the bank meets the quay
		end
	end
	if side < 0 then
		local dq = (z >= QWZ1) and (z - QWZ1) or ((z <= QWZ0) and (QWZ0 - z) or nil)
		if dq and dq < 16 then
			local r = row(z)
			local t = ease(dq / 16)
			wob = lerp((r.c - QXW) - r.w, wob, t); width = lerp(1.5, width, t)
			kind = "steep"
		end
	end
	if side > 0 and z > QZ0 and z < QZ1 then
		local r = row(z)
		return (QX - r.c) - r.w, 0.5, "quay"
	end
	if side < 0 and z > QWZ0 and z < QWZ1 then
		local r = row(z)
		return (r.c - QXW) - r.w, 0.5, "quayW"
	end
	return wob, width, kind
end

-- 3. pads: level ground under things that stand near the edge
local pads, islets = {}, {}
local bridge = workspace.Village.Props:FindFirstChild("bridge")
local modelMin = {}
local gallery = workspace:FindFirstChild("PortraitGallery")
local painter = workspace:FindFirstChild("painter_squirrel_color")
local easel = workspace.Village.Props:FindFirstChild("easel")
local gpParams = RaycastParams.new(); gpParams.FilterType = Enum.RaycastFilterType.Include; gpParams.FilterDescendantsInstances = {workspace.Village.Ground, workspace.River}
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
				if standing and not onPaving then pads[#pads + 1] = {xa = xa, xb = xb, za = za, zb = zb, h = math.min(under - ((d:IsDescendantOf(workspace.Village.Ground) or d.Name == "Walkway") and 0.1 or 0.06), 1.5),
					stone = d:IsDescendantOf(workspace.Village.Ground) or d.Name == "Walkway",
					keep = (gallery and d:IsDescendantOf(gallery)) or (painter and d:IsDescendantOf(painter)) or (easel and d:IsDescendantOf(easel))} end
			end
		end
	end
end
-- bucket pads by 16-stud z bands
local bucket = {}
for _, pd in ipairs(pads) do
	for b = math.floor((pd.za - 7) / 16), math.floor((pd.zb + 7) / 16) do bucket[b] = bucket[b] or {}; table.insert(bucket[b], pd) end
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
		h = (u <= 0.4) and DEEP or lerp(DEEP, (kind == "quay" or kind == "quayW") and -3 or (WATER_Y - 0.35), ease((u - 0.4) / 0.6))
		mat = (h < -3.5) and Enum.Material.Mud or ((kind == "beach") and Enum.Material.Sand or Enum.Material.Mud)
	elseif kind == "quayW" then
		h = COVER; mat = Enum.Material.Grass                         -- grass behind the forest-side wall
	elseif kind == "quay" then
		h = -1.5; mat = Enum.Material.Rock
	elseif e < width then
		local t = e / width
		local pw = (kind == "steep") and 0.45 or ((kind == "beach") and 1.5 or 0.85)
		h = lerp(WATER_Y - 0.35, COVER, t ^ pw)
		-- the worn band along the water: sand (earth on the steep banks, pebbles on the beaches), then grass
		if kind == "beach" and t < 0.85 then mat = (e < 1.5) and Enum.Material.Mud or Enum.Material.Sand
		elseif e < 1.5 then mat = Enum.Material.Mud                         -- wet, dark, where the water laps
		elseif e < 6.0 then mat = (kind == "steep" and e < 3.5) and Enum.Material.Ground or Enum.Material.Sand
		else mat = Enum.Material.Grass end
	else
		h = COVER; mat = (e < 6.0) and Enum.Material.Sand or Enum.Material.Grass   -- a narrow bank still gets its sandy band
	end
	for _, i in ipairs(islets) do
		local dd = math.sqrt((x - i.x) ^ 2 + (z - i.z) ^ 2)
		local IR = i.r + 1.5
		if dd < IR + 3 then
			local hi = (dd < IR) and (WATER_Y - 0.35) or lerp(WATER_Y - 0.35, DEEP, ease((dd - IR) / 3))
			if hi > h then h = hi; if dd < IR + 1 then mat = Enum.Material.Rock end end
		end
	end
	for _, pd in ipairs(bucket[math.floor(z / 16)] or {}) do
		local dx = math.max(pd.xa - x, 0, x - pd.xb)
		local dz = math.max(pd.za - z, 0, z - pd.zb)
		local dd = math.sqrt(dx * dx + dz * dz)
		local FL = pd.keep and 6.0 or 1.0
		if dd < FL + 2.5 and not ((kind == "quay" and ((e > 0 and not pd.stone) or (e <= 0 and pd.stone))) or (kind == "quayW" and e <= 0)) then
			local hp = (dd <= FL) and pd.h or lerp(pd.h, DEEP, ease((dd - FL) / 2.5))
			if hp > h then
				h = hp
				if pd.stone and dd <= 1.2 then mat = Enum.Material.Ground             -- earth right up under the paving
				elseif mat == Enum.Material.Mud and h > WATER_Y + 0.3 then mat = Enum.Material.Sand end
			end
		end
	end
	return h, e, mat, side
end

local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("RiverBanks")

if cur:GetAttribute("RiverChannel") ~= "v52 wide" then P("STOP: v52 channel not found") return end
-- 6. terrain
local x0, x1, z0, z1, y0, y1 = 84, 228, -920, 680, -12, 0
local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
local nx, ny, nz = (x1 - x0) / 4, (y1 - y0) / 4, (z1 - z0) / 4
local old = T:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
local sm, so, lq = old.SolidMaterial, old.SolidOccupancy, old.LiquidOccupancy
local cols = {}
local paveParams = RaycastParams.new(); paveParams.FilterType = Enum.RaycastFilterType.Include
paveParams.FilterDescendantsInstances = {workspace.Village.Ground}
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
				local tt = hs / 4
				local pv = workspace:Raycast(Vector3.new(cx, 5, cz), Vector3.new(0, -6, 0), paveParams)
				local cap = pv and (pv.Position.Y - 0.35) or nil
				if cap then tt = math.min(tt, cap) end
				cols[#cols + 1] = {ix = ix, iz = iz, x = cx, z = cz, t = tt, H = tt, m = best, cap = cap}
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
local function cover()
	local cx0, cx1, cz0, cz1 = -136, 712, -260, 40
	local reg = Region3.new(Vector3.new(cx0, -8, cz0), Vector3.new(cx1, 8, cz1))
	local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
	local a, b, l = c.SolidMaterial, c.SolidOccupancy, c.LiquidOccupancy
	local count = 0
	for ix = 1, (cx1 - cx0) / 4 do
		for iz = 1, (cz1 - cz0) / 4 do
			local empty = true
			for iy = 1, 4 do if b[ix][iy][iz] > 0 or l[ix][iy][iz] > 0 then empty = false; break end end
			if empty then
				count += 1
				a[ix][1][iz] = Enum.Material.Grass; b[ix][1][iz] = 1
				a[ix][2][iz] = Enum.Material.Grass; b[ix][2][iz] = (COVER + 2) / 4
			end
		end
	end
	T:WriteVoxelChannels(reg, 4, {SolidMaterial = a, SolidOccupancy = b, LiquidOccupancy = l})
	P("cover", count, "columns")
end
local function reread()
	local o = T:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
	sm, so, lq = o.SolidMaterial, o.SolidOccupancy, o.LiquidOccupancy
end
for it = 1, 6 do
	task.wait(5)
	local err, worst, n = 0, 0, 0
	for _, c in ipairs(cols) do
		local hit = workspace:Raycast(Vector3.new(c.x, 12, c.z), Vector3.new(0, -30, 0), tp)
		local y = hit and hit.Position.Y or -12
		local d = c.t - y
		err += math.abs(d); worst = math.max(worst, math.abs(d)); n += 1
		if it < 6 then c.H = math.clamp(c.H + 0.75 * d, c.t - 3.5, math.min(c.cap and (c.t + 0.1) or (c.t + 3.5), 1.9)) end
	end
	P("round", it, string.format("mean %.2f worst %.2f", err / n, worst))
	if it == 2 then cover(); reread() end
	if it < 6 then writeAll() end
end

-- 7. hide the even sand strips (kept, so they can come back)
for _, b in ipairs({river.BankL, river.BankR}) do
	if b:GetAttribute("OldTransparency") == nil then b:SetAttribute("OldTransparency", b.Transparency) end
	b.Transparency = 1; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
end
workspace.River:SetAttribute("Banks", "v70 " .. os.date("!%Y-%m-%d %H:%M"))
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
-- the forest side: wall face at QXW facing the water (+x), kerb beside the bridge only
block("WallW", 143.0, QXW, -3.6, 0.25, QWZ0, QWZ1, Enum.Material.Cobblestone, wallCol)
block("KerbW", 142.6, QXW + 0.2, -1.0, 0.75, QWZ0, BZ0, Enum.Material.Limestone, kerbCol)   -- reaches into the ground
block("KerbW", 142.6, QXW + 0.2, -1.0, 0.75, BZ1, QWZ1, Enum.Material.Limestone, kerbCol)
do -- white capstone under the bridge deck, just below the planks
	local bps = {}
	for _, d in ipairs(bridge:GetDescendants()) do if d:IsA("BasePart") then bps[#bps + 1] = d end end
	local bpp = RaycastParams.new(); bpp.FilterType = Enum.RaycastFilterType.Include; bpp.FilterDescendantsInstances = bps
	local low = math.huge
	for x = 142.6, 144.6, 0.25 do for z = BZ0 + 0.5, BZ1 - 0.5, 0.75 do
		local h = workspace:Raycast(Vector3.new(x, -2, z), Vector3.new(0, 8, 0), bpp)
		if h then low = math.min(low, h.Position.Y) end
	end end
	local capTop = math.clamp(low - 0.04, 0.32, 0.75)
	block("CapW", 143.95, QXW + 0.2, -1.0, capTop, BZ0, BZ1, Enum.Material.Limestone, kerbCol)
	P("cap top", string.format("%.2f", capTop))
end
block("WallEndWS", 142.6, QXW + 0.4, -3.6, 0.75, QWZ0 - 0.8, QWZ0, Enum.Material.Limestone, kerbCol)
block("WallEndWN", 142.6, QXW + 0.4, -3.6, 0.75, QWZ1, QWZ1 + 0.8, Enum.Material.Limestone, kerbCol)
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("BANKS DONE")
