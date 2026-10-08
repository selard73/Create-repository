"""make_terrain_lua.py - writes tools/gorge_terrain_t1.lua: the south hills and the gorge's beaches as Roblox terrain,
from gorge_shape.py (the same rules the approved preview used). The Lua has a DRY switch: DRY = true computes
everything and prints samples and counts without writing; DRY = false backs up the terrain (TerrainRegion copies in
ServerStorage.GorgeBackup) and writes it.

Rules (game coordinates):
  * nothing within 10 studs of the play area's south walls is touched (smooth wall line, always on or south of the
    real walls), nor the river between the village wall and the gorge mouth
  * hills: ridge profile by distance south of the wall line + gentle noise, tapering off at the far west and east ends;
    written as a max with what is there, grass; they fill the old river channel past the gorge's end
  * beside the gorge: the grass starts 1.5 studs back from the rock's lip at the rim height + 0.1, blending into the
    hills 5..25 studs back
  * inside the gorge, the strip between the water and the rock face: a beach (mud at the water, sand behind) where the
    rock stands back, or water right up to the rock where it doesn't; the river's own water body is left alone
  * terrain surface height trap (measured on the river): a solid surface draws at cell centre + 4 x occupancy, so the
    top cell gets occ = (h - (yb + 2)) / 4; liquid is linear: (WATER_Y - yb) / 4
"""
import math, os
import numpy as np
import gorge_shape as G

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "tools", "gorge_terrain_t1.lua")
X_MIN, X_MAX = -520.0, 1020.0
Z0S = -204.0                      # the samples start at the village wall (the mouth rule needs the river there)
DZS = 1.0

zs = np.arange(Z0S, G.Z_END - 2.0 - 1e-6, -DZS)
cx = [float(G.centre_x(z)) for z in zs]
hw = [float(G.half_width(z)) for z in zs]
data = {"CX": cx, "HW": hw}
for s, tag in ((-1, "W"), (1, "E")):
    data["FOOT" + tag] = [float(G.foot(z, s)) for z in zs]
    data["RIM" + tag] = [G.rim_d(z, s) if z <= G.Z_START else 0.0 for z in zs]
    data["TOP" + tag] = [float(G.top_at(z, s)) for z in zs]
    data["FACE" + tag] = [float(G.face_d(z, np.array([0.3]), s)[0]) if z <= G.Z_START else 0.0 for z in zs]


def arr(name, vals):
    return "local %s = {%s}" % (name, ",".join("%.2f" % v for v in vals))


# Python reference values for the dry run (hills only, the same formula the Lua uses)
def hill_ref(x, z):
    wz = float(G.wall_z(x))
    if z > wz - 10.0:
        return None
    dz = wz - z
    taper = float(G.smoothstep(X_MIN, X_MIN + 140.0, x) * (1 - G.smoothstep(X_MAX - 90.0, X_MAX, x)))
    return max(float(G.ridge_profile(dz) + G.hill_noise(x, z) * G.smoothstep(14.0, 60.0, dz)), 0.0) * taper


REF = [(-400.0, -600.0), (0.0, -300.0), (300.0, -700.0), (520.0, -330.0), (900.0, -900.0), (650.0, -500.0)]
ref_lines = []
for x, z in REF:
    h = hill_ref(x, z)
    ref_lines.append("%.0f,%.0f -> %s" % (x, z, "nil" if h is None else "%.2f" % h))

lua = r'''-- gorge_terrain_t1: the south hills and the gorge's beaches (made by italy/gorge_real/make_terrain_lua.py)
-- DRY = true: computes everything and prints what it WOULD write (changes nothing).
-- DRY = false: CHANGES THE PLACE: backs up the south terrain into ServerStorage.GorgeBackup, then writes it.
local DRY = true
local T = workspace.Terrain
local WATER_Y, Z0S, DZS = %(water_y).2f, %(z0s).1f, %(dzs).1f
local Z_START, Z_END = %(z_start).1f, %(z_end).1f
local X_MIN, X_MAX, Z_FAR = %(x_min).1f, %(x_max).1f, -1020
local Y_LO, Y_HI = -16, 112
%(arrays)s
local N = #CX
local function ss(e0, e1, x) local t = math.clamp((x - e0) / (e1 - e0), 0, 1) return t * t * (3 - 2 * t) end
local function samp(a, z)
	local f = (Z0S - z) / DZS + 1
	if f <= 1 then return a[1] end
	if f >= N then return a[N] end
	local i = math.floor(f); local t = f - i
	return a[i] * (1 - t) + a[i + 1] * t
end
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
	local wz = wall_z(x)
	if z > wz - 10 then return nil end
	local dz = wz - z
	local taper = ss(X_MIN, X_MIN + 140, x) * (1 - ss(X_MAX - 90, X_MAX, x))
	return math.max(ridge(dz) + noise(x, z) * ss(14, 60, dz), 0) * taper
end
-- what to do with the column at (x, z): returns kind, value, material
--   "skip"            leave it alone
--   "hill", h          solid up to h (max with what is there), grass
--   "beach", h, mat    solid exactly up to h (sand / mud), no water above
--   "water"            an underwater shelf and water up to WATER_Y (the river right up to the rock)
local function plan(x, z)
	if x < X_MIN or x > X_MAX or z < Z_FAR then return "skip" end
	local h = hill(x, z)
	if h == nil then return "skip" end
	if z > Z_START - 1 then                                        -- between the village wall and the gorge: the river stays
		if math.abs(x - samp(CX, z)) < samp(HW, z) + 6 then return "skip" end
		return "hill", h
	end
	if z >= Z_END - 2 then
		local c = samp(CX, z)
		local east = x >= c
		local d = math.abs(x - c)
		local rim = samp(east and RIME or RIMW, z)
		local top = samp(east and TOPE or TOPW, z)
		if d < rim + 1.5 then
			local hwz = samp(HW, z)
			local face0 = samp(east and FACEE or FACEW, z)
			if d > hwz - 0.5 and d < face0 + 1.0 then
				local gap = samp(east and FOOTE or FOOTW, z) - hwz
				if gap >= 1.2 then
					local ramp = ss(1.2, 3.0, gap)
					local e = d - hwz
					local hh, mat
					if e < 0 then hh, mat = WATER_Y - 1.1, Enum.Material.Mud
					elseif e < 1.3 then hh, mat = 0.1, Enum.Material.Mud
					else hh, mat = 0.25 + 0.08 * math.sin(z / 3.7 + d), Enum.Material.Sand end
					hh = (WATER_Y - 0.5) + (hh - (WATER_Y - 0.5)) * ramp
					return "beach", hh, mat
				end
				return "water"
			end
			return "skip"                                          -- the river itself, or inside the rock
		end
		local blend = ss(rim + 5, rim + 25, d)
		return "hill", (top + 0.1) * (1 - blend) + h * blend
	end
	return "hill", h                                               -- past the gorge's end: the hills close over the old channel
end
local function solid_cell(h, yb)
	-- full below the surface cell, occ in the surface cell (surface = centre + 4 * occ), empty above
	if yb + 6 <= h then return 1 end
	if yb + 2 > h then return 0 end
	return (h - (yb + 2)) / 4
end
local function liquid_cell(yb)
	return math.clamp((WATER_Y - yb) / 4, 0, 1)
end

-- reference heights from the Python model (the dry run prints the Lua's values beside them)
print("QQ T1 REF python: %(refs)s")
local refs = {%(ref_pts)s}
local lv = {}
for _, p in ipairs(refs) do local h = hill(p[1], p[2]); lv[#lv + 1] = string.format("%%.0f,%%.0f -> %%s", p[1], p[2], h and string.format("%%.2f", h) or "nil") end
print("QQ T1 REF lua:    " .. table.concat(lv, " | "))

-- the chunks
local CH = 256
local counts = {skip = 0, hill = 0, beach = 0, water = 0}
local chunks = {}
for x0 = math.floor(X_MIN / 4) * 4, X_MAX, CH do
	for z1 = -200, Z_FAR, -CH do
		chunks[#chunks + 1] = {x0, z1}
	end
end
if not DRY then
	local ss_ = game:GetService("ServerStorage")
	local bk = ss_:FindFirstChild("GorgeBackup") or Instance.new("Folder")
	bk.Name = "GorgeBackup"; bk.Parent = ss_
	-- whole-region copies of the south terrain before any change (restore with Terrain:PasteRegion)
	for i, c in ipairs(chunks) do
		local name = string.format("TerrainSouth_%%02d", i)
		if not bk:FindFirstChild(name) then
			local lo = Vector3int16.new(c[1] / 4, Y_LO / 4, (c[2] - CH) / 4)
			local hi = Vector3int16.new((c[1] + CH) / 4 - 1, Y_HI / 4 - 1, c[2] / 4 - 1)
			local tr = T:CopyRegion(Region3int16.new(lo, hi))
			tr.Name = name; tr:SetAttribute("Corner", Vector3.new(c[1], Y_LO, c[2] - CH)); tr.Parent = bk
		end
	end
	print("QQ T1 backup", #bk:GetChildren(), "regions in ServerStorage.GorgeBackup")
end
local t0 = os.clock()
for i, c in ipairs(chunks) do
	local x0, z1 = c[1], c[2]
	local region = Region3.new(Vector3.new(x0, Y_LO, z1 - CH), Vector3.new(x0 + CH, Y_HI, z1))
	local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
	local so, lo, ma = ch.SolidOccupancy, ch.LiquidOccupancy, ch.Material
	local sx, sy, sz = ch.Size.X, ch.Size.Y, ch.Size.Z
	local changed = false
	for ix = 1, sx do
		local x = x0 + (ix - 0.5) * 4
		for iz = 1, sz do
			local z = (z1 - CH) + (iz - 0.5) * 4
			local kind, v, mat = plan(x, z)
			counts[kind] = counts[kind] + 1
			if kind ~= "skip" and not DRY then
				changed = true
				for iy = 1, sy do
					local yb = Y_LO + (iy - 1) * 4
					if kind == "hill" then
						local ns = solid_cell(v, yb)
						if ns > so[ix][iy][iz] then
							so[ix][iy][iz] = ns
							ma[ix][iy][iz] = Enum.Material.Grass
						end
						if so[ix][iy][iz] > 0.99 then lo[ix][iy][iz] = 0 end
					elseif kind == "beach" then
						local ns = solid_cell(v, yb)
						so[ix][iy][iz] = ns
						if ns > 0 and yb >= v - 8 then ma[ix][iy][iz] = mat end
						lo[ix][iy][iz] = (ns > 0.99) and 0 or math.min(liquid_cell(yb), lo[ix][iy][iz])
						if yb + 2 > WATER_Y then lo[ix][iy][iz] = 0 end
					elseif kind == "water" then
						local ns = solid_cell(WATER_Y - 2.5, yb)
						so[ix][iy][iz] = ns
						if ns > 0 then ma[ix][iy][iz] = Enum.Material.Mud end
						lo[ix][iy][iz] = liquid_cell(yb)
					end
				end
			end
		end
	end
	if changed then
		T:WriteVoxelChannels(region, 4, {SolidOccupancy = so, LiquidOccupancy = lo, Material = ma})
	end
	if i %% 4 == 0 then task.wait() end
end
print(string.format("QQ T1 %%s chunks %%d columns: skip %%d hill %%d beach %%d water %%d (%%.1fs)", DRY and "DRY" or "WROTE", #chunks,
	counts.skip, counts.hill, counts.beach, counts.water, os.clock() - t0))
print("QQ T1 DONE")
''' % dict(
    water_y=G.WATER_Y, z0s=Z0S, dzs=DZS, z_start=G.Z_START, z_end=G.Z_END, x_min=X_MIN, x_max=X_MAX,
    arrays="\n".join(arr(k, v) for k, v in data.items()),
    refs=" | ".join(ref_lines),
    ref_pts=", ".join("{%.1f, %.1f}" % p for p in REF),
)
with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(lua)
print("wrote", OUT, len(lua) // 1024, "KB;", len(zs), "samples")
print("refs:", " | ".join(ref_lines))
