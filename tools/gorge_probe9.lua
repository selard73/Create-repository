-- gorge_probe9: READ-ONLY (the t10 pass's functions + a dump of a few terrain columns to see what is really there).
-- original header: the land SOUTH of the ridge for the falls (made by italy/gorge_real/make_south_lua.py).
-- DRY = true prints what it WOULD write (changes nothing). DRY = false CHANGES THE PLACE: backs up every chunk it
-- touches into ServerStorage.GorgeBackup (TerrainRegion copies, restore with Terrain:PasteRegion), then writes:
-- the hollow + plateau behind the cliff arms, the plain / cove / plunge pool / sea in front, the ridge's slope beyond
-- the arms (matching their end faces), and nothing north of the corners' line except right behind the arms.
local DRY = true
local T = workspace.Terrain
local ZC, CXE, XCW, XCE = -547.5000, 183.8438, 169.4583, 201.2856
local T0, RR = 40.7189, 1.40
local SEA_Y, PLAIN_Y, Y_FOOT = -52.90, -48.00, -64.00
local ARM_L, COVE_A, COVE_L, COAST = 130.0, 40.0, 110.0, 210.0
local HX_MIN, HX_MAX = -520.0, 1020.0                -- the hills' extent (their tapers), as in the first pass
local X_LO, X_HI = -1400, 1400                       -- the sea runs this wide
local Z_TOP, Z_BOT = -532, -1556                     -- rows -548..-532 only behind the arms
local Y_LO = -72
local Grass, Sand, Sandstone, Rock, Mud = Enum.Material.Grass, Enum.Material.Sand, Enum.Material.Sandstone, Enum.Material.Rock, Enum.Material.Mud

local function ss(e0, e1, x) local t = math.clamp((x - e0) / (e1 - e0), 0, 1) return t * t * (3 - 2 * t) end
local function wall_z(x)
	local z = -215 + 10 * ss(135, 185, x)
	z = z - 45 * ss(302, 352, x)
	z = z - 23 * ss(416, 466, x)
	z = z + 23 * ss(568, 618, x)
	return z
end
local function ridge(dz)
	local h = 42 * ss(14, 84, dz)
	h = h + 7 * math.sin((dz - 84) / 70) * ss(84, 150, dz)
	h = h + 40 * ss(300, 780, dz)
	return h
end
local function noise(x, z)
	return 6 * math.sin(x / 97 + 1.3) * math.cos(z / 83 - 0.7) + 3.5 * math.sin(x / 41 + z / 57 + 2.1)
		+ 2 * math.sin(x / 23 - z / 31 + 0.4) + 0.9 * math.sin(x / 9.7 + z / 13.3 + 1.1)
end
local function hill(x, z)
	local dz = wall_z(x) - z
	if dz < 10 then return 0 end
	local taper = ss(HX_MIN, HX_MIN + 140, x) * (1 - ss(HX_MAX - 90, HX_MAX, x))
	return math.max(ridge(dz) + noise(x, z) * ss(14, 60, dz), 0) * taper
end
local function cove(a)
	local sc = 4 * math.sin(a / 6.4 + 1.1) * ss(6, 30, a) * (1 - ss(ARM_L - 40, ARM_L - 10, a))
	return COVE_A * ss(0, COVE_L, a) + sc
end
local function arm_lean(a, y)
	local e = 0.44 * ss(ARM_L - 30, ARM_L, a)
	return 0.16 * ss(0, 45, a) * math.max(y, 0) + e * math.max(y - PLAIN_Y, 0)
end
local function cliff_T(a) return T0 + 2.6 * math.sin(a / 23) + 1.1 * math.sin(a / 9.5) + 2 * ss(20, 110, a) end
local function south_height(x, z)
	local zd = ZC - z
	local plain = PLAIN_Y + 1.2 * math.sin(x / 31) * math.cos(z / 27) + 0.6 * math.sin(x / 11 + z / 13)
	local ax = CXE + 14 * math.sin(zd / 60) * ss(20, 120, zd)
	local hw = 24 + 0.13 * zd
	local r = math.abs(x - ax) / hw
	local pool = 9 * math.exp(-(((x - CXE) / 22) ^ 2 + ((zd - 12) / 18) ^ 2)) * ss(0, 10, zd)
	local bed = SEA_Y - 3 - 3 * (1 - math.min(r, 1) ^ 2) - pool
	local beach = ss(30, 60, zd) * (1 - ss(90, 120, zd)) * ((x > ax) and 1 or 0)
	local shore = ss(0.85, 1.25 + 0.5 * beach, r)
	local h = bed * (1 - shore) + plain * shore
	local coast = COAST + 45 * math.sin(x / 90 + 0.6) + 18 * math.sin(x / 31 - 1)
	local sea = ss(coast - 30, coast + 30, zd)
	return h * (1 - sea) + (SEA_Y - 9) * sea, pool
end
-- what to do with the column at (x, z): kind, height, material, extra
--   "skip"                      leave it alone
--   "south", h, mat             ground at h; water above it up to SEA_Y where h < SEA_Y
--   "slope", h, mat             the ridge's side beyond the arms / the plateau behind it: ground at h, no water
--   "arm", hp, a                behind a cliff arm: ground at hp except the hollow right behind the face (per cell)
local function plan(x, z)
	if x < X_LO or x > X_HI or z < Z_BOT then return "skip" end
	local a = math.max(0, XCW - x, x - XCE)
	local river = (x > XCW and x < XCE)
	local zc = ZC - cove(a)
	local dn = z - zc
	local low, pool = south_height(x, z)
	if math.abs(x) > 1024 then                                     -- off the plate's width: the plain and the sea only
		if z > ZC - 40 then return "skip" end
		local m = (low < SEA_Y + 2.5) and Sand or Grass
		return "south", low, m
	end
	if z >= -548 then                                              -- the rows just north of the corners' line
		if river or a <= 8 or a > ARM_L then return "skip" end     -- the gorge's own rim and beaches stay; so do the hills
		local rim = arm_lean(a, cliff_T(a) - RR) + RR
		if dn > rim + 30 then return "skip" end                    -- beyond that the plateau has blended into the hills already there
	end
	if river and z < -548 then
		local m = (pool > 2.5) and Rock or ((low < SEA_Y + 2.5) and Sand or Grass)
		return "south", low, m
	end
	if a <= ARM_L then
		if dn < 0 then
			local m = (pool > 2.5) and Rock or ((low < SEA_Y + 2.5) and Sand or Grass)
			return "south", low, m
		end
		local Tc = cliff_T(a)
		local rim = arm_lean(a, Tc - RR) + RR
		local blend = ss(rim + 5, rim + 25, dn)
		local hp = (Tc + 0.1) * (1 - blend) + hill(x, z) * blend
		return "arm", hp, a
	end
	-- beyond the arms
	if dn <= 0 then
		local m = (low < SEA_Y + 2.5) and Sand or Grass
		return "south", low, m
	end
	local w = ss(ARM_L, ARM_L + 20, a)
	local Tc = cliff_T(ARM_L) * (1 - w) + math.max(hill(x, zc), 0) * w
	local ease = ss(ARM_L, ARM_L + 80, a)
	local wander = 1 + 0.22 * math.sin(x / 41 + 1) * ss(ARM_L, ARM_L + 40, a)
	local stretch = (1 + 0.8 * ease) * wander
	local d = dn / stretch
	local d0 = 0.44 * (0 - PLAIN_Y)
	local prof = (d <= d0) and (PLAIN_Y + d / 0.44) or ((d - d0) / 0.60)
	if prof < Tc then
		local steep = stretch < 1.4
		return "slope", math.max(low, prof), steep and Sandstone or Grass
	end
	local top = (d0 + 0.6 * Tc) * stretch
	local blend = ss(top, top + 25, dn)
	return "slope", Tc * (1 - blend) + hill(x, z) * blend, Grass
end
local function solid_cell(h, yb)
	if yb + 6 <= h then return 1 end
	if yb + 2 > h then return 0 end
	return (h - (yb + 2)) / 4
end
local function liquid_cell(yb)
	return math.clamp((SEA_Y - yb) / 4, 0, 1)
end


-- dump: what plan() says for a column, and what the terrain holds there (solid cells' y ranges, the top surface)
local pts = {{60, -575}, {320, -575}, {90, -560}, {183.8, -550}, {165, -546}, {205, -546}, {46, -575}, {330, -570}, {100, -570}}
for _, p in ipairs(pts) do
	local x, z = p[1], p[2]
	local kind, v, extra = plan(x, z)
	local a = math.max(0, XCW - x, x - XCE)
	local zc = ZC - cove(a)
	local cx, cz = math.floor(x / 4) * 4, math.floor(z / 4) * 4
	local region = Region3.new(Vector3.new(cx, Y_LO, cz), Vector3.new(cx + 4, 112, cz + 4))
	local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
	local so, lo, ma = ch.SolidOccupancy, ch.LiquidOccupancy, ch.Material
	local runs, cur = {}, nil
	for iy = 1, ch.Size.Y do
		local yb = Y_LO + (iy - 1) * 4
		local s = so[1][iy][1]
		if s > 0.01 then
			if cur and cur.last == yb - 4 then cur.last = yb; cur.top = yb + 4 * s; cur.n += 1 else
				if cur then runs[#runs + 1] = cur end
				cur = {first = yb, last = yb, top = yb + 4 * s, n = 1, mat = ma[1][iy][1].Name}
			end
		end
	end
	if cur then runs[#runs + 1] = cur end
	local rs = {}
	for _, r in ipairs(runs) do rs[#rs + 1] = string.format("[%d..%.1f %s]", r.first, r.top, r.mat) end
	local hollowTop = nil
	if kind == "arm" then
		for yc = -50, 60, 4 do
			if (z - zc) < arm_lean(extra, yc + 2) + 7.0 then hollowTop = hollowTop or yc end
		end
	end
	print(string.format("QQ P9 (%.0f,%.0f) a %.1f zc %.1f dn %.1f -> %s v %.1f extra %s | hollow from yc %s | solid runs: %s", x, z, a, zc, z - zc, kind, v or -999, tostring(extra), tostring(hollowTop), table.concat(rs, " ")))
end
print("QQ P9 DONE")
