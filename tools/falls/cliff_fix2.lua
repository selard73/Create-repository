-- cliff_fix2.lua (Studio EDIT mode; re-runnable). Job 84: the cliff's openings closed with the cliff's own rock.
-- Shannon on job 83 (sandstone behind the openings): "I can still see bald spots" - the openings between the slabs read
-- as patches of something else whatever colour the ground behind them is. So, behind the top band of every cliff piece:
--   (1) the terrain is carved back to 3.2 studs behind the face (rows y 26..38 only; the rows under the grass top and
--       the limestone outcrops untouched; the region is backed up once as HudBackup.CliffTop_pre1, job 83's backup);
--   (2) a BACK COPY of each cliff piece (SouthCliff_W01..W04, E01..E04) stands 1.5 studs behind the original, 0.8 lower
--       and 0.3 further from the notch, so each gap between slabs looks onto a solid slab of the same banded rock;
--   (3) a STRATA PLATE (a flat part wearing the cliff's own texture) stands 2.6 studs behind the face of each 8-stud
--       segment, its top under whatever covers it, for whatever the copy still leaves open;
--   (4) job 83's pieces stay: the sandstone terrain behind, the shaved pokes, the 8 small blocks, the LipPlate at 36.
-- Nothing collides or answers rays. Undo: delete SouthGorge.Rock.CliffBacking2; terrain:
-- workspace.Terrain:PasteRegion(ServerStorage.HudBackup.CliffTop_pre1, Vector3int16.new(9, 5, -148), true). No publish.
local SS = game:GetService("ServerStorage")
local Terrain = workspace.Terrain
local SG = workspace:FindFirstChild("SouthGorge"); local Rock = SG and SG:FindFirstChild("Rock")
if not Rock then print("QQ CLIFF2 ABORT: workspace.SouthGorge.Rock not found") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local regionMin, regionMax = Vector3int16.new(9, 5, -148), Vector3int16.new(84, 13, -130)   -- studs x 36..336, y 20..52, z -592..-520
if not hb:FindFirstChild("CliffTop_pre1") then
	local reg = Terrain:CopyRegion(Region3int16.new(regionMin, regionMax)); reg.Name = "CliffTop_pre1"; reg.Parent = hb
end
local DEPTH, Y0, YCARVE, Y1, YTOP, PAD = 3.2, 24, 38, 42, 43.4, 0.25
local COPY_BACK, COPY_DOWN, COPY_SIDE = 1.5, 0.8, 0.3
local PLATE_BACK, PLATE_THICK = 2.6, 0.4
local TEX = "rbxassetid://131222358558225"
local BANDS = {{name = "W", x0 = 42, x1 = 164, prefix = "SouthCliff_W0", side = -1}, {name = "E", x0 = 204, x1 = 328, prefix = "SouthCliff_E0", side = 1}}
local SOFT = {[Enum.Material.Grass] = true, [Enum.Material.LeafyGrass] = true, [Enum.Material.Ground] = true, [Enum.Material.Sandstone] = true, [Enum.Material.Mud] = true}

local folder = Rock:FindFirstChild("CliffBacking2"); if folder then folder:Destroy() end
folder = Instance.new("Folder"); folder.Name = "CliffBacking2"; folder.Parent = Rock
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Include; tparams.FilterDescendantsInstances = {Terrain}
local report = {}
for _, band in ipairs(BANDS) do
	local cliffs = {}
	for _, c in ipairs(Rock:GetChildren()) do if c:IsA("BasePart") and c.Name:sub(1, #band.prefix) == band.prefix and not c.Name:find("_Lo") and not c.Name:find("_Back") then table.insert(cliffs, c) end end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = cliffs
	local both = RaycastParams.new(); both.FilterType = Enum.RaycastFilterType.Include
	local inc = {Terrain}; for _, c in ipairs(cliffs) do table.insert(inc, c) end; both.FilterDescendantsInstances = inc
	-- (2) the back copies
	local copies = 0
	for _, src in ipairs(cliffs) do
		local c = src:Clone(); c.Name = src.Name .. "_Back"
		for _, d in ipairs(c:GetDescendants()) do if not (d:IsA("Texture") or d:IsA("Decal") or d:IsA("SurfaceAppearance")) then d:Destroy() end end
		c.CFrame = src.CFrame + Vector3.new(COPY_SIDE * band.side, -COPY_DOWN, COPY_BACK)
		c.Anchored = true; c.CanCollide = false; c.CanQuery = false; c.CanTouch = false; c.CastShadow = false; c.DoubleSided = true
		c:SetAttribute("BackingOf", src.Name); c.Parent = folder; copies += 1
	end
	-- the face, column by column (the originals only: the copies answer no rays)
	local faceZ, hits = {}, 0
	for x = band.x0, band.x1, 2 do
		local fz
		for y = Y0 + 2, Y1, 2 do
			local m = workspace:Raycast(Vector3.new(x, y, -600), Vector3.new(0, 0, 90), params)
			if m then hits += 1; fz = math.max(fz or m.Position.Z, m.Position.Z) end
		end
		faceZ[x] = fz
	end
	if hits == 0 then table.insert(report, band.name .. ": no cliff mesh hit - nothing carved or built") continue end
	-- (1) the carve: rows y 26..38, soft terrain only, from where it begins to DEPTH behind the face
	local carved = 0
	for x = band.x0, band.x1, 2 do
		for y = Y0 + 2, YCARVE, 2 do
			local origin = Vector3.new(x, y, -600)
			local m = workspace:Raycast(origin, Vector3.new(0, 0, 90), params)
			local t = m and workspace:Raycast(origin, Vector3.new(0, 0, 90), tparams)
			if m and t and SOFT[t.Material] and t.Position.Z < m.Position.Z + DEPTH and t.Position.Z > m.Position.Z - 2.5 then
				local z0, z1 = math.min(t.Position.Z, m.Position.Z) - 0.3, m.Position.Z + DEPTH
				Terrain:FillBlock(CFrame.new(Vector3.new(x, y, (z0 + z1) / 2)), Vector3.new(2.2, 2.2, z1 - z0), Enum.Material.Air)
				carved += 1
			end
		end
	end
	-- (3) the strata plates, one per 8-stud segment, under their cover
	local plates, skipped = 0, {}
	for x = band.x0, band.x1 - 8, 8 do
		local zs = {}
		for xx = x, x + 8, 2 do if faceZ[xx] then table.insert(zs, faceZ[xx]) end end
		if #zs == 0 then table.insert(skipped, x .. ":no face") continue end
		local zp = math.max(table.unpack(zs)) + PLATE_BACK
		local cover, open = math.huge, false
		for _, dx in ipairs({-3.5, 0, 3.5}) do
			for _, dz in ipairs({0.05, PLATE_THICK - 0.05}) do
				local h = workspace:Raycast(Vector3.new(x + 4 + dx, 70, zp + dz), Vector3.new(0, -(70 - Y0), 0), both)
				if h then cover = math.min(cover, h.Position.Y) else open = true end
			end
		end
		if open then table.insert(skipped, x .. ":open sky") continue end
		local yTop = math.min(YTOP, cover - PAD)
		if yTop - Y0 < 3 then table.insert(skipped, string.format("%d:cover %.1f", x, cover)) continue end
		local p = Instance.new("Part"); p.Name = string.format("StrataPlate_%s_%d", band.name, x)
		p.Size = Vector3.new(8.4, yTop - Y0, PLATE_THICK); p.CFrame = CFrame.new(x + 4, (Y0 + yTop) / 2, zp + PLATE_THICK / 2)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic; p.Color = Color3.fromRGB(235, 225, 205)
		local tx = Instance.new("Texture"); tx.Texture = TEX; tx.Face = Enum.NormalId.Front; tx.StudsPerTileU = 50; tx.StudsPerTileV = 50; tx.OffsetStudsV = Y0 - 18; tx.Parent = p
		local tt = Instance.new("Texture"); tt.Texture = TEX; tt.Face = Enum.NormalId.Top; tt.StudsPerTileU = 50; tt.StudsPerTileV = 50; tt.Parent = p
		p.Parent = folder; plates += 1
	end
	table.insert(report, string.format("%s: %d back copies; %d carves (rows 26..38, to %.1f behind the face); %d strata plates (skipped %s)",
		band.name, copies, carved, DEPTH, plates, #skipped > 0 and table.concat(skipped, ",") or "none"))
end
-- the hill beyond the west outcrop (Shannon: a dark bare patch there too): what material is its surface?
do
	local counts = {}
	for x = 8, 44, 4 do for z = -600, -540, 4 do
		local h = workspace:Raycast(Vector3.new(x, 90, z), Vector3.new(0, -80, 0), tparams)
		if h then counts[h.Material.Name] = (counts[h.Material.Name] or 0) + 1 end
	end end
	local s = {} for k, v in pairs(counts) do table.insert(s, k .. " " .. v) end
	table.insert(report, "hill x 8..44 surface: " .. (#s > 0 and table.concat(s, ", ") or "no terrain"))
end
print("QQ CLIFF2 DONE: " .. table.concat(report, " | ") .. "; backup HudBackup.CliffTop_pre1 (paste at voxel " .. tostring(regionMin) .. ")")
