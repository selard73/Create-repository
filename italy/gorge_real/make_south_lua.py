"""make_south_lua.py - the terrain pass for the land SOUTH of the ridge (Sep 30 2026, the falls): writes
tools/gorge_terrain_t10_dry.lua and tools/gorge_terrain_t10_write.lua from gorge_shape.py's falls design.

What the pass does, column by column (4-stud cells), for z south of the gorge's corners (plus a few rows north of
them behind the cliff arms):
  * behind the cliff arms (within ARM_L of a corner, north of the cliff's base line): a hollow 7 studs thick right
    behind the rock face (the face leans back, so the hollow follows it), then the plateau at the crest height blending
    into the hills - the same idea as along the gorge walls
  * in front of the arms and the lip: the plain at PLAIN_Y, the cove and the plunge pool, the sea (water up to SEA_Y
    wherever the ground is below it)
  * beyond the arms: the ridge's south side as a slope with exactly the profile of the arms' end faces (so it meets
    them), eased and wandering further out, sandstone where steep
  * the first rows north of the corners' line are touched only behind the arms, more than 26 studs out from a corner
    (closer in, the gorge wall's own hollow is there: refilling it put a dark terrain slab through the east wall, Sep 30 21:10)
Everything the pass changes is first copied, chunk by chunk, into ServerStorage.GorgeBackup (TerrainRegion objects).
"""
import os
import numpy as np
import gorge_shape as G

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(os.path.dirname(os.path.dirname(HERE)), "tools")
XCW, XCE = G.corner_x(-1), G.corner_x(1)
CXE = float(G.centre_x(G.ZC))
T0 = float(G.top_at(G.ZC, 1))
assert abs(T0 - float(G.top_at(G.ZC, -1))) < 1e-6

# reference heights from the Python model for the dry run to print beside the Lua's
REF = [(183.8, -560.0), (183.8, -600.0), (120.0, -620.0), (260.0, -640.0), (183.8, -760.0), (183.8, -900.0), (400.0, -700.0), (-300.0, -650.0), (600.0, -1200.0), (240.0, -600.0)]
ref_s = " | ".join("%.0f,%.0f -> %.2f" % (x, z, float(G.south_height(x, z))) for x, z in REF)

LUA = r'''-- gorge_terrain_t10 %(MODE)s: the land SOUTH of the ridge for the falls (made by italy/gorge_real/make_south_lua.py).
-- DRY = true prints what it WOULD write (changes nothing). DRY = false CHANGES THE PLACE: backs up every chunk it
-- touches into ServerStorage.GorgeBackup (TerrainRegion copies, restore with Terrain:PasteRegion), then writes:
-- the hollow + plateau behind the cliff arms, the plain / cove / plunge pool / sea in front, the ridge's slope beyond
-- the arms (matching their end faces), and nothing north of the corners' line except right behind the arms.
local DRY = %(DRY)s
local T = workspace.Terrain
local ZC, CXE, XCW, XCE = %(ZC).4f, %(CXE).4f, %(XCW).4f, %(XCE).4f
local T0, RR = %(T0).4f, %(RR).2f
local SEA_Y, PLAIN_Y, Y_FOOT = %(SEA_Y).2f, %(PLAIN_Y).2f, %(Y_FOOT).2f
local ARM_L, COVE_A, COVE_L, COAST = %(ARM_L).1f, %(COVE_A).1f, %(COVE_L).1f, %(COAST).1f
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
		if river or a <= 26 or a > ARM_L then return "skip" end    -- the gorge's own rim, beaches and the hollow behind its
		                                                           -- leaning top (face + 5.5 reaches a ~24 at the corners) stay; so do the hills
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

print("QQ T10 REF python: %(REF)s")
local refs = {%(REFPTS)s}
local lv = {}
for _, p in ipairs(refs) do local h = south_height(p[1], p[2]); lv[#lv + 1] = string.format("%%.0f,%%.0f -> %%.2f", p[1], p[2], h) end
print("QQ T10 REF lua:    " .. table.concat(lv, " | "))

-- the chunks: full height where the old hills stand (x -524..1024, z down to -1044), low elsewhere (plain and sea)
local CH = 256
local chunks = {}
for x0 = X_LO, X_HI - 1, CH do
	for z1 = Z_TOP, Z_BOT + 1, -CH do
		local tall = (x0 + CH > -524 and x0 < 1024 and z1 > -1044)
		chunks[#chunks + 1] = {x0, z1, tall and 112 or 12}
	end
end
local counts = {skip = 0, south = 0, slope = 0, arm = 0}
local t0 = os.clock()
if not DRY then
	local ss_ = game:GetService("ServerStorage")
	local bk = ss_:FindFirstChild("GorgeBackup") or Instance.new("Folder")
	bk.Name = "GorgeBackup"; bk.Parent = ss_
	for i, c in ipairs(chunks) do
		local name = string.format("TerrainSouthB_%%02d", i)
		if not bk:FindFirstChild(name) then
			local lo = Vector3int16.new(c[1] / 4, Y_LO / 4, (c[2] - CH) / 4)
			local hi = Vector3int16.new((c[1] + CH) / 4 - 1, c[3] / 4 - 1, c[2] / 4 - 1)
			local tr = T:CopyRegion(Region3int16.new(lo, hi))
			tr.Name = name; tr:SetAttribute("Corner", Vector3.new(c[1], Y_LO, c[2] - CH)); tr:SetAttribute("Top", c[3]); tr.Parent = bk
		end
	end
	print(string.format("QQ T10 backup: %%d chunks copied into ServerStorage.GorgeBackup (TerrainSouthB_*) in %%.1fs", #chunks, os.clock() - t0))
end
local hollow, carved = 0, 0
for i, c in ipairs(chunks) do
	local x0, z1, yhi = c[1], c[2], c[3]
	local region = Region3.new(Vector3.new(x0, Y_LO, z1 - CH), Vector3.new(x0 + CH, yhi, z1))
	local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
	local so, lo, ma = ch.SolidOccupancy, ch.LiquidOccupancy, ch.Material
	local sx, sy, sz = ch.Size.X, ch.Size.Y, ch.Size.Z
	local changed = false
	for ix = 1, sx do
		local x = x0 + (ix - 0.5) * 4
		for iz = 1, sz do
			local z = (z1 - CH) + (iz - 0.5) * 4
			local kind, v, extra = plan(x, z)
			counts[kind] = counts[kind] + 1
			if kind ~= "skip" and not DRY then
				changed = true
				local col = so[ix]
				for iy = 1, sy do
					local yb = Y_LO + (iy - 1) * 4
					local yc = yb + 2
					if kind == "south" then
						local ns = solid_cell(v, yb)
						so[ix][iy][iz] = ns
						if ns > 0 then ma[ix][iy][iz] = extra end
						if v < SEA_Y then
							lo[ix][iy][iz] = (ns > 0.99) and 0 or liquid_cell(yb)
						else
							lo[ix][iy][iz] = 0
						end
					elseif kind == "slope" then
						local ns = solid_cell(v, yb)
						so[ix][iy][iz] = ns
						if ns > 0 then ma[ix][iy][iz] = extra end
						lo[ix][iy][iz] = 0
					else -- "arm": the hollow follows the leaning face; ground elsewhere up to the plateau height
						local a = extra
						local zc = ZC - cove(a)
						local dn = z - zc
						if yc >= PLAIN_Y - 3 and dn < arm_lean(a, yc + 2) + 7.0 then
							if so[ix][iy][iz] > 0 then carved += 1 end
							so[ix][iy][iz] = 0; lo[ix][iy][iz] = 0; hollow += 1
						else
							local ns = solid_cell(v, yb)
							so[ix][iy][iz] = ns
							if ns > 0 then ma[ix][iy][iz] = Grass end
							lo[ix][iy][iz] = 0
						end
					end
				end
			end
		end
	end
	if changed then
		T:WriteVoxelChannels(region, 4, {SolidOccupancy = so, LiquidOccupancy = lo, Material = ma})
	end
	if i %% 2 == 0 then task.wait() end
end
print(string.format("QQ T10 %%s chunks %%d columns: skip %%d south %%d slope %%d arm %%d | hollow cells %%d (carved %%d) (%%.1fs)", DRY and "DRY" or "WROTE", #chunks,
	counts.skip, counts.south, counts.slope, counts.arm, hollow, carved, os.clock() - t0))
print("QQ T10 DONE")
'''

for mode, dry in (("DRY", "true"), ("WRITE", "false")):
    txt = LUA % dict(MODE=mode, DRY=dry, ZC=G.ZC, CXE=CXE, XCW=XCW, XCE=XCE, T0=T0, RR=G.RR, SEA_Y=G.SEA_Y, PLAIN_Y=G.PLAIN_Y, Y_FOOT=G.Y_FOOT,
                     ARM_L=G.ARM_L, COVE_A=G.COVE_A, COVE_L=G.COVE_L, COAST=G.COAST, REF=ref_s,
                     REFPTS=", ".join("{%.1f, %.1f}" % p for p in REF))
    path = os.path.join(TOOLS, "gorge_terrain_t10_%s.lua" % mode.lower())
    with open(path, "w", newline="\n") as fh:
        fh.write(txt)
    print("wrote", path, len(txt), "chars")
print("python refs:", ref_s)
