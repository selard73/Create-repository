-- Whale lane (Oct 7 2026): deepen the flat sea bed along the whale's loop so a 60-stud whale can cruise and dive.
-- 1) backs the terrain strip up to ServerStorage.WhaleLaneBackup (TerrainRegion; restore with
--    workspace.Terrain:PasteRegion(ServerStorage.WhaleLaneBackup, Vector3int16.new(-10,-22,-315), true))
-- 2) WriteVoxels: within FLAT of the spline the floor goes to FLOOR_Y; from FLAT to EDGE it slopes back up to the old bed.
--    Only columns that are open sea today (water above, bed at about -62 or lower) are touched; beaches and the spit stay.
--    Dry run Oct 7: the bed is a 2-voxel sand shell over AIR, so every dug column also gets solid sand from -84 up to its new floor.
local ROUTE = "200,-840;90,-940;40,-1110;210,-1215;340,-1165;362,-1102;215,-985"
local FLOOR_Y, FLAT, EDGE, BED_Y = -80, 25, 45, -64   -- slope ends at the old bed cell boundary (-64) so there is no seam at the band edge
local T = workspace.Terrain
local SS = game:GetService('ServerStorage')
-- voxel-space region (4 studs per voxel): x -40..420, z -1260..-780
local X0, X1, Z0, Z1 = -10, 105, -315, -195
local Y0, Y1 = -21, -14            -- cells -21..-15 = y -84..-56 (read); cells -21..-16 are the ones rewritten
-- ---- backup (bigger in y, cheap) ----
if SS:FindFirstChild('WhaleLaneBackup') then
	warn('QW@LANE backup already exists; not overwriting it (restore it first if you want a fresh dig)')
else
	local reg = T:CopyRegion(Region3int16.new(Vector3int16.new(X0, -22, Z0), Vector3int16.new(X1, -12, Z1)))
	reg.Name = 'WhaleLaneBackup'
	reg:SetAttribute('Corner', string.format('%d,%d,%d', X0, -22, Z0))
	reg:SetAttribute('Note', 'Terrain:PasteRegion(this, Vector3int16.new(' .. X0 .. ',-22,' .. Z0 .. '), true) puts the sea bed back')
	reg.Parent = SS
	warn('QW@LANE backup saved: ServerStorage.WhaleLaneBackup corner ' .. X0 .. ',-22,' .. Z0)
end
-- ---- spline samples (same Catmull-Rom as WhaleClient) ----
local route = {}
for x, z in string.gmatch(ROUTE, "([-%d%.]+),([-%d%.]+)") do table.insert(route, Vector2.new(tonumber(x), tonumber(z))) end
local n = #route
local function P(i) return route[((i - 1) % n) + 1] end
local function cr(i, u)
	local p0, p1, p2, p3 = P(i - 1), P(i), P(i + 1), P(i + 2)
	local u2, u3 = u * u, u * u * u
	return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3)
end
local pts = {}
for i = 1, n do for k = 0, 23 do table.insert(pts, cr(i, k / 24)) end end
local function distTo(x, z)
	local best = math.huge
	for _, p in ipairs(pts) do
		local dx, dz = p.X - x, p.Y - z
		local d = dx * dx + dz * dz
		if d < best then best = d end
	end
	return math.sqrt(best)
end
-- ---- read, modify, write ----
local region = Region3.new(Vector3.new(X0 * 4, Y0 * 4, Z0 * 4), Vector3.new(X1 * 4, Y1 * 4, Z1 * 4))
local mats, occs = T:ReadVoxels(region, 4)
local nx, ny, nz = X1 - X0, Y1 - Y0, Z1 - Z0
local dug, skippedShallow, cells = 0, 0, 0
local TOPJ = ny            -- cell -15 (y -60..-56): must be water
local BEDJ = ny - 1        -- cell -16 (y -64..-60): the old bed cell
for ix = 1, nx do
	local wx = (X0 + ix - 1) * 4 + 2
	for iz = 1, nz do
		local wz = (Z0 + iz - 1) * 4 + 2
		local d = distTo(wx, wz)
		if d <= EDGE then
			local col, colOcc = mats[ix], occs[ix]
			local openSea = col[TOPJ][iz] == Enum.Material.Water and col[BEDJ][iz] == Enum.Material.Sand and colOcc[BEDJ][iz] <= 0.75
			if not openSea then
				skippedShallow += 1
			else
				local f = d <= FLAT and FLOOR_Y or FLOOR_Y + (d - FLAT) / (EDGE - FLAT) * (BED_Y - FLOOR_Y)
				for j = 1, BEDJ do                       -- cells -21..-16 (y -84..-60)
					local bottom = (Y0 + j - 1) * 4
					local top = bottom + 4
					if bottom >= f then
						col[j][iz] = Enum.Material.Water colOcc[j][iz] = 1 cells += 1
					elseif top > f then
						col[j][iz] = Enum.Material.Sand colOcc[j][iz] = math.clamp((f - bottom) / 4, 0.05, 1) cells += 1
					elseif col[j][iz] ~= Enum.Material.Sand or colOcc[j][iz] < 1 then
						-- the old bed is a thin sand shell (y -72..-64) over AIR (the void under the world): fill under the new floor
						col[j][iz] = Enum.Material.Sand colOcc[j][iz] = 1 cells += 1
					end
				end
				dug += 1
			end
		end
	end
end
T:WriteVoxels(region, 4, mats, occs)
-- DELID (Oct 7 finding): the engine IGNORES a Water/1 write over the old Sand/0.02 sliver cell at y -64..-60, which then
-- renders as a solid lid at -61.9 over the lane. Writing Air/0 first and then Water/1 clears it.
do
	local layer = Region3.new(Vector3.new(X0 * 4, -64, Z0 * 4), Vector3.new(X1 * 4, -60, Z1 * 4))
	local lm, lo = T:ReadVoxels(layer, 4)
	local targets = {}
	for ix = 1, nx do
		local wx = (X0 + ix - 1) * 4 + 2
		for iz = 1, nz do
			local wz = (Z0 + iz - 1) * 4 + 2
			if distTo(wx, wz) <= EDGE and lm[ix][1][iz] == Enum.Material.Sand and lo[ix][1][iz] <= 0.75 then table.insert(targets, {ix, iz}) end
		end
	end
	for _, t in ipairs(targets) do lm[t[1]][1][t[2]] = Enum.Material.Air lo[t[1]][1][t[2]] = 0 end
	T:WriteVoxels(layer, 4, lm, lo)
	task.wait(0.1)
	for _, t in ipairs(targets) do lm[t[1]][1][t[2]] = Enum.Material.Water lo[t[1]][1][t[2]] = 1 end
	T:WriteVoxels(layer, 4, lm, lo)
	warn('QW@LANE delid: ' .. #targets .. ' lid cells cleared (Air then Water)')
end
game:GetService('ChangeHistoryService'):SetWaypoint('Whale lane dug')
warn(string.format('QW@LANE dug %d columns (%d cells), skipped %d shallow/land columns inside the band, floor %d, flat %d, edge %d', dug, cells, skippedShallow, FLOOR_Y, FLAT, EDGE))
-- verify: depth at the stations and a few points
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = {T} rp.IgnoreWater = true
for _, p in ipairs({route[1], route[6], route[3], Vector2.new(200, -1000)}) do
	task.wait(0.2)
	local b = workspace:Raycast(Vector3.new(p.X, 0, p.Y), Vector3.new(0, -150, 0), rp)
	warn(string.format('QW@LANE bed at %.0f,%.0f = %s', p.X, p.Y, b and string.format('%.1f', b.Position.Y) or 'none'))
end
warn('QW@LANE_DONE')
