-- cliff_fix1.lua (Studio EDIT mode; re-runnable). Job 83. The waterfall cliff's bald spots and the lip's right edge.
-- Shannon (Oct 10): dark "bald spots or holes with something else showing through" on the right-hand side of the face
-- toward the top; "the right side of where the waterfall starts shows through (you can see the water behind it)".
-- Job 82 found: the dark spots are the grass plateau's shaded side, 0.6-8 studs behind the cliff's top slabs, seen through
-- openings between the slabs (at two spots the terrain stands 0.4-0.8 studs IN FRONT of the mesh); the water sheet (Body,
-- 36 wide) is 2.2 studs wider than the LipPlate behind it (31.5) on each side.
-- Does: (1) a BACKING WALL of sandstone blocks right behind the top band of the west cliff (and of the east cliff by the
-- notch), measured here column by column so it follows the face a stud behind it: every opening between slabs now shows
-- sandstone, and the recess between the top slabs and the grass is filled; (2) shaves the terrain wherever it stands in
-- front of the face or closer behind it than the wall (thin carves; the region backed up first to
-- ServerStorage.HudBackup.CliffTop_pre1); (3) widens FallsB.LipPlate to the sheet's width at the crest (SizeWas kept).
-- Undo: delete SouthGorge.Rock.CliffBacking; LipPlate.Size from its SizeWas attribute; terrain:
-- workspace.Terrain:PasteRegion(ServerStorage.HudBackup.CliffTop_pre1, Vector3int16.new(24, 5, -144), true). No publish.
local SS = game:GetService("ServerStorage")
local Terrain = workspace.Terrain
local SG = workspace:FindFirstChild("SouthGorge"); local Rock = SG and SG:FindFirstChild("Rock")
if not Rock then print("QQ CLIFFFIX ABORT: workspace.SouthGorge.Rock not found") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS

local GAP, THICK, CARVE = 1.0, 1.6, 0.5          -- wall starts GAP behind the furthest-back face point of its segment; terrain carved to CARVE behind the wall
local Y0, Y1, YTOP = 24, 42, 43.4                 -- the band: probes at y 26..42, blocks from Y0 up to the mesh top (capped at YTOP, the slabs' top is 43.6)
local BANDS = {{name = "W", x0 = 100, x1 = 168, prefix = "SouthCliff_W0"}, {name = "E", x0 = 200, x1 = 244, prefix = "SouthCliff_E0"}}
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Include; tparams.FilterDescendantsInstances = {Terrain}

local folder = Rock:FindFirstChild("CliffBacking")
if folder then folder:Destroy() end                -- (a re-run rebuilds the wall from fresh measurements)
folder = Instance.new("Folder"); folder.Name = "CliffBacking"; folder.Parent = Rock
local regionMin, regionMax = Vector3int16.new(24, 5, -144), Vector3int16.new(64, 13, -130)   -- studs x 96..256, y 20..52, z -576..-520
if not hb:FindFirstChild("CliffTop_pre1") then
	local reg = Terrain:CopyRegion(Region3int16.new(regionMin, regionMax)); reg.Name = "CliffTop_pre1"; reg.Parent = hb
end

local report = {}
for _, band in ipairs(BANDS) do
	local cliffs = {}
	for _, c in ipairs(Rock:GetChildren()) do if c:IsA("BasePart") and c.Name:sub(1, #band.prefix) == band.prefix and not c.Name:find("_Lo") then table.insert(cliffs, c) end end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = cliffs
	-- the face, column by column: its furthest-back z over the band's height, and its top
	local faceZ, faceTop, hits = {}, {}, 0
	local function probe()
		local pokes, close = 0, 0
		for x = band.x0, band.x1, 2 do
			local fz, top = nil, nil
			for y = Y0 + 2, Y1, 2 do
				local origin = Vector3.new(x, y, -600)
				local m = workspace:Raycast(origin, Vector3.new(0, 0, 90), params)
				if m then
					hits += 1
					fz = math.max(fz or m.Position.Z, m.Position.Z); top = y
					local t = workspace:Raycast(origin, Vector3.new(0, 0, 90), tparams)
					if t and t.Position.Z < m.Position.Z - 0.05 then pokes += 1 end
					if t and t.Position.Z < m.Position.Z + GAP + THICK + CARVE and t.Position.Z > m.Position.Z - 4 then close += 1 end
				end
			end
			faceZ[x] = fz; faceTop[x] = top
		end
		return pokes, close
	end
	local pokes0, close0 = probe()
	if hits == 0 then table.insert(report, band.name .. ": no cliff mesh hit in the band (CanQuery?) - nothing built") continue end
	-- the wall: one block per 4-stud segment, behind the segment's furthest-back face point
	local built = 0
	for x = band.x0, band.x1 - 4, 4 do
		local zs, top = {}, nil
		for _, xx in ipairs({x, x + 2, x + 4}) do if faceZ[xx] then table.insert(zs, faceZ[xx]); top = math.max(top or 0, faceTop[xx] or 0) end end
		if #zs > 0 then
			local zb = math.max(table.unpack(zs)) + GAP
			local yTop = math.min(YTOP, (top or Y1) + 1.5)
			if yTop - Y0 > 2 then
				local b = Instance.new("Part"); b.Name = string.format("CliffBack_%s_%d", band.name, x)
				b.Size = Vector3.new(4.4, yTop - Y0, THICK); b.CFrame = CFrame.new(x + 2, (Y0 + yTop) / 2, zb + THICK / 2)
				b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = true
				b.Material = Enum.Material.Sandstone; b.Color = Color3.fromRGB(214, 198, 168); b.Parent = folder
				built += 1
			end
		end
	end
	-- the terrain: carved back to behind the wall wherever it is closer (thin Air boxes; the top row clamped under the slabs' top)
	local carved = 0
	for x = band.x0, band.x1, 2 do
		for y = Y0 + 2, Y1, 2 do
			local origin = Vector3.new(x, y, -600)
			local m = workspace:Raycast(origin, Vector3.new(0, 0, 90), params)
			local t = m and workspace:Raycast(origin, Vector3.new(0, 0, 90), tparams)
			if m and t then
				local segX = x - ((x - band.x0) % 4)
				local zb = (faceZ[segX] or faceZ[x] or m.Position.Z)
				for _, xx in ipairs({segX, segX + 2, segX + 4}) do if faceZ[xx] then zb = math.max(zb, faceZ[xx]) end end
				local wallBack = zb + GAP + THICK + CARVE
				if t.Position.Z < wallBack and t.Position.Z > m.Position.Z - 4 then
					local z0 = math.min(t.Position.Z, m.Position.Z) - 0.3
					local yTop = math.min(y + 1.1, YTOP + 0.1)
					local yBot = y - 1.1
					Terrain:FillBlock(CFrame.new(Vector3.new(x, (yBot + yTop) / 2, (z0 + wallBack) / 2)), Vector3.new(2.2, yTop - yBot, wallBack - z0), Enum.Material.Air)
					carved += 1
				end
			end
		end
	end
	local pokes1, close1 = probe()
	table.insert(report, string.format("%s: %d blocks; terrain in front of the face %d -> %d, closer than the wall %d -> %d (%d carves)", band.name, built, pokes0, pokes1, close0, close1, carved))
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
print(string.format("QQ CLIFFFIX DONE: wall %s; backup HudBackup.CliffTop_pre1 (paste at voxel %s); %s", table.concat(report, " | "), tostring(regionMin), plateNote))
