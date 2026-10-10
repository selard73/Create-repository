-- cliff_fix1.lua (Studio EDIT mode; re-runnable). Job 83. The waterfall cliff's bald spots and the lip's right edge.
-- Shannon (Oct 10): dark "bald spots or holes with something else showing through" on the right-hand side of the face
-- toward the top; "the right side of where the waterfall starts shows through (you can see the water behind it)".
-- Job 82 found: the dark spots are the grass plateau's shaded side, 0.6-8 studs behind the west cliff's top slabs, seen
-- through openings in the meshes (and at two spots the terrain stands 0.4-0.8 studs IN FRONT of the mesh); the water sheet
-- (Body, 36 wide) is 2.2 studs wider than the LipPlate behind it (31.5) on each side.
-- Does: (1) a BACKING COPY of SouthCliff_W01, W02 and E01, the same mesh and texture 1.5 studs behind the face, so every
-- opening shows rock behind rock (and the recess between the top slabs and the grass is roofed); (2) shaves the terrain
-- wherever it stands in front of the west cliff's top band or closer behind the face than the backing copy, so the copy is
-- always the first thing behind an opening (thin carves, the region backed up first to ServerStorage.HudBackup.CliffTop_pre1);
-- (3) widens FallsB.LipPlate to the sheet's width (SizeWas kept).
-- Undo: delete the *_Back parts; LipPlate.Size from its SizeWas attribute; terrain: Terrain:PasteRegion(HudBackup.CliffTop_pre1,
-- the Min corner printed below, true). No publish.
local SS = game:GetService("ServerStorage")
local Terrain = workspace.Terrain
local function v3(v) return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
local SG = workspace:FindFirstChild("SouthGorge"); local Rock = SG and SG:FindFirstChild("Rock")
if not Rock then print("QQ CLIFFFIX ABORT: workspace.SouthGorge.Rock not found") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS

-- (1) the backing copies
local BACK = 1.5
local made, kept = {}, {}
for _, name in ipairs({"SouthCliff_W01", "SouthCliff_W02", "SouthCliff_E01"}) do
	local src = Rock:FindFirstChild(name)
	if src then
		if Rock:FindFirstChild(name .. "_Back") then table.insert(kept, name)
		else
			local c = src:Clone(); c.Name = name .. "_Back"
			for _, d in ipairs(c:GetDescendants()) do if d:IsA("LuaSourceContainer") or d:IsA("Attachment") then d:Destroy() end end
			c.CFrame = src.CFrame + Vector3.new(0, 0, BACK)   -- behind the face (the plateau side is +Z of it)
			c.Anchored = true; c.CanCollide = false; c.CanQuery = false; c.CanTouch = false; c.DoubleSided = true; c.CastShadow = true
			c:SetAttribute("BackingOf", name); c.Parent = Rock
			table.insert(made, name)
		end
	end
end

-- (2) the terrain in front of the west cliff's top band: probe, back up, shave, re-probe
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include
local cliffs = {}
for _, c in ipairs(Rock:GetChildren()) do if c.Name:find("SouthCliff_W0") and not c.Name:find("_Back") then table.insert(cliffs, c) end end
params.FilterDescendantsInstances = cliffs
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Include; tparams.FilterDescendantsInstances = {Terrain}
local function pokes()
	local list = {}
	for x = 100, 168, 2 do
		for y = 26, 46, 2 do
			local origin = Vector3.new(x, y, -600)
			local m = workspace:Raycast(origin, Vector3.new(0, 0, 80), params)
			if m then
				local t = workspace:Raycast(origin, Vector3.new(0, 0, 80), tparams)
				if t and t.Position.Z < m.Position.Z + BACK + 0.4 and t.Position.Z > m.Position.Z - 3 then   -- in front, or closer behind than the backing copy
					table.insert(list, {x = x, y = y, tz = t.Position.Z, mz = m.Position.Z})
				end
			end
		end
	end
	return list
end
local before = pokes()
local shaved = 0
local regionMin
if #before > 0 then
	-- the backup once: the whole top band in voxel steps
	regionMin = Vector3int16.new(24, 5, -144)   -- x 96, y 20, z -576 (voxels of 4)
	if not hb:FindFirstChild("CliffTop_pre1") then
		local reg = Terrain:CopyRegion(Region3int16.new(regionMin, Vector3int16.new(44, 13, -133)))   -- to x 176, y 52, z -532
		reg.Name = "CliffTop_pre1"; reg.Parent = hb
	end
	for _, p in ipairs(before) do
		-- a thin box of Air from where the terrain begins back to just behind the backing copy
		local z0, z1 = math.min(p.tz, p.mz) - 0.3, p.mz + BACK + 0.4
		Terrain:FillBlock(CFrame.new(Vector3.new(p.x, p.y, (z0 + z1) / 2)), Vector3.new(2.2, 2.2, z1 - z0), Enum.Material.Air)
		shaved += 1
	end
end
local after = pokes()

-- (3) the lip plate as wide as the sheet
local plate = SG:FindFirstChild("FallsB") and SG.FallsB:FindFirstChild("LipPlate")
local plateNote = "no FallsB.LipPlate"
if plate then
	if plate:GetAttribute("SizeWas") == nil then plate:SetAttribute("SizeWas", plate.Size) end
	local body
	for _, d in ipairs(SG:GetDescendants()) do if d:IsA("Beam") and d.Name == "Body" then body = d end end
	local w = body and math.max(body.Width0, body.Width1) or 36
	plate.Size = Vector3.new(w, plate.Size.Y, plate.Size.Z)
	plateNote = string.format("LipPlate %.1f wide (was %s)", plate.Size.X, tostring(plate:GetAttribute("SizeWas")))
end

local function fmt(list) local s = {} for _, p in ipairs(list) do table.insert(s, string.format("(%d,%d: terrain %.1f, mesh %.1f)", p.x, p.y, p.tz, p.mz)) end return #s > 0 and table.concat(s, " ") or "none" end
print(string.format("QQ CLIFFFIX DONE: backing copies made %s (kept %s), %.1f studs behind; terrain pokes before %d: %s; shaved %d; after %d: %s; backup %s; %s",
	#made > 0 and table.concat(made, ",") or "none", #kept > 0 and table.concat(kept, ",") or "none", BACK, #before, fmt(before), shaved, #after, fmt(after),
	regionMin and ("HudBackup.CliffTop_pre1 from voxel " .. tostring(regionMin)) or "none needed", plateNote))
