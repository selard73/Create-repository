"""make_t2_lua.py - writes tools/gorge_terrain_t2.lua: the correction pass after gorge_terrain_t1 (Shannon's OK for the
terrain step covers "measure and correct"). Only inside the gorge's opening and just behind its rims:
  (a) the strip between the water and the rock face (to 3 studs behind the face at the waterline): beach or water,
      replacing any old bank or edge-mound terrain there
  (b) behind each rim: the grass topped up (terrain rounds its edges down), rim + 1.5 .. rim + 8
  (c) any terrain cell standing in front of the rock face (above the beach level) is removed, using the rock's exact
      face position at the cell's height (a table from gorge_shape.face_d); above the lip, nothing in front of rim + 1.5
DRY = true prints what it would change.
"""
import os
import numpy as np
import gorge_shape as G

HERE = os.path.dirname(os.path.abspath(__file__))
import sys
PASS = sys.argv[1] if len(sys.argv) > 1 else "t2"
OUT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "tools", "gorge_terrain_%s.lua" % PASS)
T3 = PASS in ("t3", "t4", "t5")
T4 = PASS == "t4"
T5 = PASS == "t5"
DZS = 2.0
zs = np.arange(G.Z_START, G.Z_END - 2.0 - 1e-6, -DZS)
YK = np.arange(2.0, 52.0 + 1e-6, 2.0)                 # face table heights
cols = {"CX": [float(G.centre_x(z)) for z in zs], "HW": [float(G.half_width(z)) for z in zs]}
faces = {}
for s, tag in ((-1, "W"), (1, "E")):
    cols["FOOT" + tag] = [float(G.foot(z, s)) for z in zs]
    cols["RIM" + tag] = [G.rim_d(z, s) for z in zs]
    cols["TOP" + tag] = [float(G.top_at(z, s)) for z in zs]
    cols["FACE0" + tag] = [float(G.face_d(z, np.array([0.3]), s)[0]) for z in zs]
    tab = []
    for z in zs:
        T = float(G.top_at(z, s))
        ys = np.minimum(YK, T - G.RR)                 # above the lip the table holds the lip's own position
        tab.extend(float(v) for v in G.face_d(z, ys, s))
    faces["FT" + tag] = tab


def arr(name, vals, fmt="%.2f"):
    return "local %s = {%s}" % (name, ",".join(fmt % v for v in vals))


xs_lo = min(min(c - r for c, r in zip(cols["CX"], cols["RIMW"])), 0) - 12
xs_hi = max(c + r for c, r in zip(cols["CX"], cols["RIME"])) + 12
X0 = int(np.floor(min(c - r for c, r in zip(cols["CX"], cols["RIMW"])) - 12) // 4 * 4)
X1 = int(np.ceil((max(c + r for c, r in zip(cols["CX"], cols["RIME"])) + 12) / 4) * 4)

lua = r'''-- gorge_terrain_%(pass_)s: the correction pass inside the gorge (made by italy/gorge_real/make_t2_lua.py)
-- DRY = true prints what it would change; DRY = false CHANGES THE PLACE (terrain inside the gorge's opening and just
-- behind its rims only; the backup from t1 is in ServerStorage.GorgeBackup).
local DRY = true
local T = workspace.Terrain
local WATER_Y, RR = %(water_y).2f, %(rr).2f
local Z_START, Z_END, DZS = %(z_start).1f, %(z_end).1f, %(dzs).1f
local X0, X1 = %(x0)d, %(x1)d
local YK0, YKD, NK = %(yk0).1f, %(ykd).1f, %(nk)d
local Y_LO, Y_HI = -16, 64
local T3 = %(t3)s
local T4 = %(t4)s
local T5 = %(t5)s
local BOOST_MAX = T3 and 12 or 8
local LIP_KEEP = T3 and 2.5 or 1.5
%(arrays)s
local N = #CX
local function ss(e0, e1, x) local t = math.clamp((x - e0) / (e1 - e0), 0, 1) return t * t * (3 - 2 * t) end
local function idx(z)
	local f = (Z_START - z) / DZS + 1
	f = math.clamp(f, 1, N)
	local i = math.min(math.floor(f), N - 1); return i, f - i
end
local function samp(a, z) local i, t = idx(z) return a[i] * (1 - t) + a[i + 1] * t end
local function face(tab, z, y)
	local i, t = idx(z)
	local k = math.clamp((y - YK0) / YKD + 1, 1, NK)
	local kk = math.min(math.floor(k), NK - 1); local u = k - kk
	local function at(ii) return tab[(ii - 1) * NK + kk] * (1 - u) + tab[(ii - 1) * NK + kk + 1] * u end
	return at(i) * (1 - t) + at(i + 1) * t
end
local function solid_cell(h, yb)
	if yb + 6 <= h then return 1 end
	if yb + 2 > h then return 0 end
	return (h - (yb + 2)) / 4
end
local function liquid_cell(yb) return math.clamp((WATER_Y - yb) / 4, 0, 1) end

local counts = {beach = 0, water = 0, boosted = 0, carved = 0, cols = 0}
local CH = 128
local t0 = os.clock()
for x0 = X0, X1 - 1, CH do
	for z1 = math.ceil((Z_START + 4) / 4) * 4, Z_END - 8, -CH do
		local region = Region3.new(Vector3.new(x0, Y_LO, z1 - CH), Vector3.new(x0 + CH, Y_HI, z1))
		local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
		local so, lo, ma = ch.SolidOccupancy, ch.LiquidOccupancy, ch.Material
		local sx, sy, sz = ch.Size.X, ch.Size.Y, ch.Size.Z
		local changed = false
		for ix = 1, sx do
			local x = x0 + (ix - 0.5) * 4
			for iz = 1, sz do
				local z = (z1 - CH) + (iz - 0.5) * 4
				if z <= Z_START and z >= Z_END - 2 then
					local c = samp(CX, z)
					local east = x >= c
					local d = math.abs(x - c)
					local rim = samp(east and RIME or RIMW, z)
					local hw = samp(HW, z)
					if d < rim + BOOST_MAX and d > hw - 0.5 then
						counts.cols = counts.cols + 1
						local top = samp(east and TOPE or TOPW, z)
						local face0 = samp(east and FACE0E or FACE0W, z)
						local ft = east and FTE or FTW
						if d < face0 + 3.0 and not T3 then
							-- (a) the waterline strip: beach where the rock stands back, water right up to it where it doesn't
							local gap = samp(east and FOOTE or FOOTW, z) - hw
							if gap >= 1.2 then
								local ramp = ss(1.2, 3.0, gap)
								local e = d - hw
								local hh, mat
								if e < 0 then hh, mat = WATER_Y - 1.1, Enum.Material.Mud
								elseif e < 1.3 then hh, mat = 0.1, Enum.Material.Mud
								else hh, mat = 0.25 + 0.08 * math.sin(z / 3.7 + d), Enum.Material.Sand end
								hh = (WATER_Y - 0.5) + (hh - (WATER_Y - 0.5)) * ramp
								counts.beach = counts.beach + 1
								if not DRY then
									changed = true
									for iy = 1, sy do
										local yb = Y_LO + (iy - 1) * 4
										local ns = solid_cell(hh, yb)
										so[ix][iy][iz] = ns
										if ns > 0 and yb >= hh - 8 then ma[ix][iy][iz] = mat end
										lo[ix][iy][iz] = (ns > 0.99 or yb + 2 > WATER_Y) and 0 or math.min(liquid_cell(yb), lo[ix][iy][iz])
									end
								end
							else
								counts.water = counts.water + 1
								if not DRY then
									changed = true
									for iy = 1, sy do
										local yb = Y_LO + (iy - 1) * 4
										local ns = solid_cell(WATER_Y - 2.5, yb)
										so[ix][iy][iz] = ns
										if ns > 0 then ma[ix][iy][iz] = Enum.Material.Mud end
										lo[ix][iy][iz] = liquid_cell(yb)
									end
								end
							end
						else
							-- (b) top up the grass behind the rim
							if d >= rim + 1.5 and not T4 and not T5 then
								local e = d - rim
								local target = top + 0.1 + ((e < 3.5) and 0.9 or ((e < 5.5) and 0.5 or ((e < 8) and 0.2 or 0.0)))
								for iy = 1, sy do
									local yb = Y_LO + (iy - 1) * 4
									local ns = solid_cell(target, yb)
									if ns > so[ix][iy][iz] + 0.01 then
										counts.boosted = counts.boosted + 1
										if not DRY then so[ix][iy][iz] = ns; ma[ix][iy][iz] = Enum.Material.Grass; lo[ix][iy][iz] = 0; changed = true end
									end
								end
							end
							-- (c) nothing may stand in front of the rock face (cells above the beach level)
							for iy = 1, sy do
								local yb = Y_LO + (iy - 1) * 4
								local yc = yb + 2
								if yc >= (T5 and 1 or 2) and yc <= top + 6 and so[ix][iy][iz] > 0 then
									local cut
									local margin = 0.2
									if T3 then margin = (yc < 8) and 0.6 or ((yc > top - 8) and 0.8 or 0.3) end
									if T5 then margin = 3.5 end
									local fz = face(ft, z, yc)
									if T4 or T5 then fz = math.max(fz, face(ft, z - 2, yc), face(ft, z + 2, yc), face(ft, z, yc + 2), face(ft, z, yc - 2)) end
									local rimz = rim
									if T5 then rimz = math.max(rim, samp(east and RIME or RIMW, z - 2), samp(east and RIME or RIMW, z + 2)) end
									if T5 and yc >= top - 12 then cut = (d < rimz + 3.5) or ((d - 2.0) < fz + margin)
									elseif yc < top - RR then cut = (d - 2.0) < fz + margin
									else cut = d < rim + LIP_KEEP end
									if cut then
										counts.carved = counts.carved + 1
										if not DRY then so[ix][iy][iz] = 0; lo[ix][iy][iz] = 0; changed = true end
									end
								end
							end
						end
					end
				end
			end
		end
		if changed then T:WriteVoxelChannels(region, 4, {SolidOccupancy = so, LiquidOccupancy = lo, Material = ma}) end
		task.wait()
	end
end
print(string.format("QQ T2 %%s columns %%d: beach %%d water %%d cells boosted %%d carved %%d (%%.1fs)", DRY and "DRY" or "WROTE",
	counts.cols, counts.beach, counts.water, counts.boosted, counts.carved, os.clock() - t0))
print("QQ T2 DONE")
''' % dict(water_y=G.WATER_Y, pass_=PASS, rr=G.RR, t3=('true' if T3 else 'false'), t4=('true' if T4 else 'false'), t5=('true' if T5 else 'false'), z_start=G.Z_START, z_end=G.Z_END, dzs=DZS, x0=X0, x1=X1,
           yk0=float(YK[0]), ykd=float(YK[1] - YK[0]), nk=len(YK),
           arrays="\n".join([arr(k, v) for k, v in cols.items()] + [arr(k, v, "%.1f") for k, v in faces.items()]))
with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(lua)
print("wrote", OUT, len(lua) // 1024, "KB;", len(zs), "z samples; x", X0, "..", X1)
