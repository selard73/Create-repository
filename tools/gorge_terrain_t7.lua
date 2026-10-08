-- gorge_terrain_t7: the terrain round the HEADWALL at the gorge's end (made by hand from gorge_shape, Sep 30).
-- DRY = true prints what it would change; DRY = false CHANGES THE PLACE (only south of z -548, within 70 studs of
-- the headwall's centre): carves the cirque inside the headwall (and the cave tunnel), and fills the old slot behind it
-- with hill (grass), with a plateau at the headwall's top so the grass covers its top edge.
local DRY = true
local T = workspace.Terrain
local CXE, ZE, R, RIM, TOP, WATER_Y = 183.50, -548.0, 15.28, 25.32, 40.70, -0.9
local Z_MOUTH, Z_BACK, TUN_HW = -562.9, -569.9, 5.5
local X_MIN, X_MAX, Z_FAR = -520, 1020, -1020
local Y_LO, Y_HI = -16, 112
local function ss(e0, e1, x) local t = math.clamp((x - e0) / (e1 - e0), 0, 1) return t * t * (3 - 2 * t) end
local function wall_z(x)
	local z = -215 + 10 * ss(135, 185, x); z = z - 45 * ss(302, 352, x); z = z - 23 * ss(416, 466, x); z = z + 23 * ss(568, 618, x); return z
end
local function ridge(dz) local h = 42 * ss(14, 84, dz); h = h + 7 * math.sin((dz - 84) / 70) * ss(84, 150, dz); h = h + 40 * ss(300, 780, dz); return h end
local function noise(x, z)
	return 6 * math.sin(x / 97 + 1.3) * math.cos(z / 83 - 0.7) + 3.5 * math.sin(x / 41 + z / 57 + 2.1) + 2 * math.sin(x / 23 - z / 31 + 0.4) + 0.9 * math.sin(x / 9.7 + z / 13.3 + 1.1)
end
local function hill(x, z)
	local wz = wall_z(x); if z > wz - 10 then return nil end
	local dz = wz - z; local taper = ss(X_MIN, X_MIN + 140, x) * (1 - ss(X_MAX - 90, X_MAX, x))
	return math.max(ridge(dz) + noise(x, z) * ss(14, 60, dz), 0) * taper
end
local function solid_cell(h, yb) if yb + 6 <= h then return 1 end if yb + 2 > h then return 0 end return (h - (yb + 2)) / 4 end
local FW, FE = 14.39, 17.44
local function hwR(th) local w = math.sin(th) ^ 2; return ((th < math.pi / 2) and FW or FE) * (1 - w) + R * w end
local function lean(y) return 0.22 * math.max(y, 0) end
local counts = {carved = 0, tunnel = 0, filled = 0, cols = 0}
local x0, x1 = math.floor((CXE - 72) / 4) * 4, math.floor((CXE + 72) / 4) * 4
local zTop = math.floor((ZE + 4) / 4) * 4          -- v2: includes the two cell rows at the join (z -544..-552)
local region = Region3.new(Vector3.new(x0, Y_LO, zTop - 128), Vector3.new(x1, Y_HI, zTop))
local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
local so, lo, ma = ch.SolidOccupancy, ch.LiquidOccupancy, ch.Material
local changed = false
for ix = 1, ch.Size.X do
	local x = x0 + (ix - 0.5) * 4
	for iz = 1, ch.Size.Z do
		local z = (zTop - 128) + (iz - 0.5) * 4
		if z <= ZE + 2 then
			counts.cols += 1
			local rr = math.sqrt((x - CXE) ^ 2 + (z - ZE) ^ 2)
			local th = math.clamp(math.atan2(-(z - ZE), -(x - CXE)), 0, math.pi)
			local Rth = hwR(th)                                 -- v5: the headwall's real radius at this angle (wider at the joins)
			local inTunnel = math.abs(x - CXE) < TUN_HW and z <= Z_MOUTH + 1.5 and z >= Z_BACK - 1.5
			local h = hill(x, z) or 0
			local blend = ss(RIM + 5, RIM + 25, rr)
			local target = (TOP + 0.1) * (1 - blend) + h * blend
			-- v3: the POOL inside the headwall (and the tunnel): a mud bed 2.5 under the water, water to WATER_Y, nothing above
			-- (the old river banks in the pinched slot stood up to y 2 along the headwall's foot)
			if rr < Rth + 6.2 or inTunnel then                     -- v5: the pool reaches every cell whose surface could bulge into the foot
				for iy = 1, ch.Size.Y do
					local yb = Y_LO + (iy - 1) * 4
					local ns = solid_cell(WATER_Y - 2.5, yb)
					if math.abs(so[ix][iy][iz] - ns) > 0.01 or (ns > 0 and ma[ix][iy][iz] ~= Enum.Material.Mud) then counts.carved += 1 end
					if not DRY then
						so[ix][iy][iz] = ns; if ns > 0 then ma[ix][iy][iz] = Enum.Material.Mud end
						lo[ix][iy][iz] = math.clamp((WATER_Y - yb) / 4, 0, 1); changed = true
					end
				end
			else
			for iy = 1, ch.Size.Y do
				local yb = Y_LO + (iy - 1) * 4; local yc = yb + 2
				local face = Rth + lean(yc) - 0.5
				local cut = false
				if yc >= 1 and yc <= TOP + 6 then
					if rr < face + 5.5 then cut = true end
					if yc >= TOP - 12 and rr < RIM + 3.5 then cut = true end
				end
				if inTunnel and yc < 9 and yc >= -3 then cut = true; counts.tunnel += 1 end
				if cut then
					if so[ix][iy][iz] > 0 then counts.carved += 1 end
					if not DRY then so[ix][iy][iz] = 0; changed = true end
				elseif rr >= face + 5.5 then
					local ns = solid_cell(target, yb)
					if ns > so[ix][iy][iz] + 0.01 then
						counts.filled += 1
						if not DRY then so[ix][iy][iz] = ns; ma[ix][iy][iz] = Enum.Material.Grass; if ns > 0.99 then lo[ix][iy][iz] = 0 end; changed = true end
					end
				end
			end
			end
		end
	end
end
if changed then T:WriteVoxelChannels(region, 4, {SolidOccupancy = so, LiquidOccupancy = lo, Material = ma}) end
print(string.format("QQ T7 %s columns %d: cells carved %d (tunnel %d), filled %d", DRY and "DRY" or "WROTE", counts.cols, counts.carved, counts.tunnel, counts.filled))
print("QQ T7 DONE")
