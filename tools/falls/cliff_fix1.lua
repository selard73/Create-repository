-- cliff_fix1.lua (Studio EDIT mode; re-runnable). Job 83, round two. The waterfall cliff's bald spots and the lip's right edge.
-- Shannon (Oct 10): dark "bald spots or holes with something else showing through" on the right-hand side of the face
-- toward the top; "the right side of where the waterfall starts shows through (you can see the water behind it)".
-- Job 82 found: the dark spots are the grass plateau's shaded side, 0.6-8 studs behind the cliff's top slabs, seen through
-- openings between the slabs (at two spots the terrain stands 0.4-0.8 studs IN FRONT of the mesh); the water sheet (Body,
-- 36 wide) is 2.2 studs wider than the LipPlate behind it (31.5) on each side.
-- Does: (1) a BACKING WALL of sandstone blocks behind the top band of the whole face (west cliff x 42..160, east 208..328),
-- measured here segment by segment: each block starts half a stud behind the furthest-back face point of its segment,
-- is as thick as the room to the terrain allows (up to 1.6), and its top stays under whatever covers it from above - the
-- slabs in front, the grass behind - so nothing shows from above or from the plateau; a segment open to the sky (the
-- notch) gets no block; (2) the terrain's exposed side in the band becomes Sandstone (material only, the shape untouched,
-- the grass top row kept), so where the terrain itself backs an opening it reads as rock; the two places where it stands
-- in front of the face are shaved with a thin Air box (well under the top row); the region is backed up first to
-- ServerStorage.HudBackup.CliffTop_pre1; (3) FallsB.LipPlate widened to the sheet's width at the crest (SizeWas kept).
-- Undo: delete SouthGorge.Rock.CliffBacking; LipPlate.Size from its SizeWas attribute; terrain:
-- workspace.Terrain:PasteRegion(ServerStorage.HudBackup.CliffTop_pre1, Vector3int16.new(9, 5, -145), true). No publish.
local SS = game:GetService("ServerStorage")
local Terrain = workspace.Terrain
local SG = workspace:FindFirstChild("SouthGorge"); local Rock = SG and SG:FindFirstChild("Rock")
if not Rock then print("QQ CLIFFFIX ABORT: workspace.SouthGorge.Rock not found") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS

local GAP, THICK_MAX, THICK_MIN = 0.5, 1.6, 0.3   -- the block starts GAP behind the segment's furthest-back face point
local Y0, Y1, YTOP = 24, 42, 43.4                 -- probes at y 26..42; blocks from Y0 up, never above YTOP
local COVER_PAD = 0.25                            -- the block's top stays this far under the lowest cover over its footprint
local BANDS = {{name = "W", x0 = 42, x1 = 160, prefix = "SouthCliff_W0"}, {name = "E", x0 = 208, x1 = 328, prefix = "SouthCliff_E0"}}   -- the whole face (Shannon: "do the whole cliff"), the notch corners left out
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Include; tparams.FilterDescendantsInstances = {Terrain}

local folder = Rock:FindFirstChild("CliffBacking")
if folder then folder:Destroy() end                -- (a re-run rebuilds the wall from fresh measurements)
folder = Instance.new("Folder"); folder.Name = "CliffBacking"; folder.Parent = Rock
local regionMin, regionMax = Vector3int16.new(9, 5, -145), Vector3int16.new(84, 13, -130)   -- studs x 36..336, y 20..52, z -580..-520
if not hb:FindFirstChild("CliffTop_pre1") then
	local reg = Terrain:CopyRegion(Region3int16.new(regionMin, regionMax)); reg.Name = "CliffTop_pre1"; reg.Parent = hb
end

local report = {}
for _, band in ipairs(BANDS) do
	local cliffs = {}
	for _, c in ipairs(Rock:GetChildren()) do if c:IsA("BasePart") and c.Name:sub(1, #band.prefix) == band.prefix and not c.Name:find("_Lo") then table.insert(cliffs, c) end end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = cliffs
	local both = RaycastParams.new(); both.FilterType = Enum.RaycastFilterType.Include
	local inc = {Terrain}; for _, c in ipairs(cliffs) do table.insert(inc, c) end; both.FilterDescendantsInstances = inc
	-- the face column by column: its furthest-back z over the band, the nearest terrain behind it, the pokes in front
	local faceZ, terrZ, hits, pokes = {}, {}, 0, {}
	for x = band.x0, band.x1, 2 do
		local fz, tz = nil, nil
		for y = Y0 + 2, Y1, 2 do
			local origin = Vector3.new(x, y, -600)
			local m = workspace:Raycast(origin, Vector3.new(0, 0, 90), params)
			if m then
				hits += 1
				fz = math.max(fz or m.Position.Z, m.Position.Z)
				local t = workspace:Raycast(origin, Vector3.new(0, 0, 90), tparams)
				if t then
					if t.Position.Z < m.Position.Z - 0.05 then table.insert(pokes, {x = x, y = y, tz = t.Position.Z, mz = m.Position.Z})
					elseif t.Position.Z - m.Position.Z < 12 then tz = math.min(tz or t.Position.Z, t.Position.Z) end
				end
			end
		end
		faceZ[x] = fz; terrZ[x] = tz
	end
	if hits == 0 then table.insert(report, band.name .. ": no cliff mesh hit in the band (CanQuery?) - nothing built") continue end
	-- the wall
	local built, skipped = 0, {}
	for x = band.x0, band.x1 - 4, 4 do
		local zs, ts = {}, {}
		for _, xx in ipairs({x, x + 2, x + 4}) do if faceZ[xx] then table.insert(zs, faceZ[xx]) end; if terrZ[xx] then table.insert(ts, terrZ[xx]) end end
		if #zs == 0 then table.insert(skipped, x .. ":no face") continue end
		local zFront = math.max(table.unpack(zs)) + GAP
		local room = (#ts > 0 and (math.min(table.unpack(ts)) - 0.2 - zFront)) or THICK_MAX
		local thick = math.min(THICK_MAX, room)
		if thick < THICK_MIN then table.insert(skipped, x .. ":no room") continue end
		-- the cover over the block's footprint: the lowest top (mesh or terrain) over nine points; open sky anywhere -> no block
		local cover, open = math.huge, false
		for _, dx in ipairs({-1.8, 0, 1.8}) do
			for _, dz in ipairs({0.1, thick / 2, thick - 0.1}) do
				local p = Vector3.new(x + 2 + dx, 70, zFront + dz)
				local h = workspace:Raycast(p, Vector3.new(0, -(70 - Y0), 0), both)
				if h then cover = math.min(cover, h.Position.Y) else open = true end
			end
		end
		if open then table.insert(skipped, x .. ":open sky") continue end
		local yTop = math.min(YTOP, cover - COVER_PAD)
		if yTop - Y0 < 3 then table.insert(skipped, string.format("%d:cover %.1f", x, cover)) continue end
		local b = Instance.new("Part"); b.Name = string.format("CliffBack_%s_%d", band.name, x)
		b.Size = Vector3.new(4.4, yTop - Y0, thick); b.CFrame = CFrame.new(x + 2, (Y0 + yTop) / 2, zFront + thick / 2)
		b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = true
		b.Material = Enum.Material.Sandstone; b.Color = Color3.fromRGB(214, 198, 168); b.Parent = folder
		built += 1
	end
	-- the terrain: sandstone where its side is exposed behind the band (not the grass top row), the pokes in front shaved
	local zMin, zMax = math.huge, -math.huge
	for x = band.x0, band.x1, 2 do if faceZ[x] then zMin = math.min(zMin, faceZ[x]); zMax = math.max(zMax, faceZ[x]) end end
	local region = Region3.new(Vector3.new(band.x0 - 2, Y0, zMin - 2), Vector3.new(band.x1 + 2, Y1 + 2, zMax + 8)):ExpandToGrid(4)
	for _, mat in ipairs({Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground}) do Terrain:ReplaceMaterial(region, 4, mat, Enum.Material.Sandstone) end
	local shaved = 0
	for _, p in ipairs(pokes) do
		if p.y <= 40 then
			local z0, z1 = p.tz - 0.3, p.mz + 0.4
			Terrain:FillBlock(CFrame.new(Vector3.new(p.x, p.y, (z0 + z1) / 2)), Vector3.new(2.2, 2.2, z1 - z0), Enum.Material.Air)
			shaved += 1
		end
	end
	table.insert(report, string.format("%s: %d blocks (skipped %s); terrain pokes in front %d, shaved %d; sandstone region %s..%s",
		band.name, built, #skipped > 0 and table.concat(skipped, ",") or "none", #pokes, shaved, tostring(region.CFrame.Position - region.Size / 2), tostring(region.CFrame.Position + region.Size / 2)))
end

-- (3) the lip plate as wide as the sheet at the crest
local FB = SG:FindFirstChild("FallsB"); local plate = FB and FB:FindFirstChild("LipPlate")
local plateNote = "no FallsB.LipPlate"
if plate then
	if plate:GetAttribute("SizeWas") == nil then plate:SetAttribute("SizeWas", plate.Size) end
	local w = 36
	local Falls = SG:FindFirstChild("Falls")
	if Falls then for _, d in ipairs(Falls:GetDescendants()) do if d:IsA("Beam") and d.Name == "Body" then w = d.Width0 end end end
	plate.Size = Vector3.new(w, plate.Size.Y, plate.Size.Z)
	plateNote = string.format("LipPlate %.1f wide (was %s)", plate.Size.X, tostring(plate:GetAttribute("SizeWas")))
end
print(string.format("QQ CLIFFFIX DONE: %s; backup HudBackup.CliffTop_pre1 (paste at voxel %s); %s", table.concat(report, " | "), tostring(regionMin), plateNote))
