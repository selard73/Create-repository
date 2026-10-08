-- v14 terrain calibration, far outside the map (x -720..-560, z 700..720), then erased: where does the surface draw for
-- a given top-cell occupancy? Patch i: cells y -8..-4 full, y -4..0 occupancy o[i], y 0..4 empty. 5x5 cells each.
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local T = workspace.Terrain
local occs = {0.1, 0.3, 0.5, 0.7, 0.9, 1.0}
local x0, z0 = -720, 700
local region = Region3.new(Vector3.new(x0, -8, z0), Vector3.new(x0 + 24 * #occs, 4, z0 + 20))
local old = T:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
local nx, ny, nz = 6 * #occs, 3, 5
local sm, so, lq = {}, {}, {}
for ix = 1, nx do
	sm[ix], so[ix], lq[ix] = {}, {}, {}
	local pi = math.floor((ix - 1) / 6) + 1
	local inPatch = ((ix - 1) % 6) < 5
	for iy = 1, ny do
		sm[ix][iy], so[ix][iy], lq[ix][iy] = {}, {}, {}
		for iz = 1, nz do
			local o = 0
			if inPatch then o = (iy == 1) and 1 or ((iy == 2) and occs[pi] or 0) end
			sm[ix][iy][iz] = o > 0 and Enum.Material.Grass or Enum.Material.Air
			so[ix][iy][iz] = o; lq[ix][iy][iz] = 0
		end
	end
end
T:WriteVoxelChannels(region, 4, {SolidMaterial = sm, SolidOccupancy = so, LiquidOccupancy = lq})
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {T}
for i, o in ipairs(occs) do
	local cx = x0 + (i - 1) * 24 + 10
	local h = workspace:Raycast(Vector3.new(cx, 20, z0 + 10), Vector3.new(0, -40, 0), rp)
	P("calib", o, h and string.format("%.2f", h.Position.Y) or "none")
end
T:WriteVoxelChannels(region, 4, old)
P("DONE14 erased")
