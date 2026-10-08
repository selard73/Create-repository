-- READ-ONLY survey for the whale's route (Oct 7 2026). Prints QW@ lines: water surface + sea-bed depth on a grid,
-- anything named like a cave / lighthouse / mole / pier / beach, and the Porto top-level folders with their extents.
local GX0, GX1, GZ0, GZ1, STEP = -200, 450, -560, -1200, 25
local rpW = RaycastParams.new() rpW.FilterType = Enum.RaycastFilterType.Include rpW.FilterDescendantsInstances = {workspace.Terrain} rpW.IgnoreWater = false
local rpB = RaycastParams.new() rpB.FilterType = Enum.RaycastFilterType.Include rpB.FilterDescendantsInstances = {workspace.Terrain} rpB.IgnoreWater = true
local rows = {}
for z = GZ0, GZ1, -STEP do
	local cells = {}
	for x = GX0, GX1, STEP do
		local w = workspace:Raycast(Vector3.new(x, 20, z), Vector3.new(0, -150, 0), rpW)
		local b = workspace:Raycast(Vector3.new(x, 20, z), Vector3.new(0, -150, 0), rpB)
		local c = '.'
		if w and w.Material == Enum.Material.Water then
			local depth = b and (w.Position.Y - b.Position.Y) or 99
			c = string.format('w%.0f/%.0f', w.Position.Y, depth)      -- water y / depth
		elseif b then
			c = string.format('L%.0f', b.Position.Y)                     -- land height
		end
		table.insert(cells, c)
	end
	warn('QW@ROW z=' .. z .. ' ' .. table.concat(cells, ' '))
end
warn('QW@GRID x ' .. GX0 .. '..' .. GX1 .. ' step ' .. STEP .. ' (left to right), rows z ' .. GZ0 .. '..' .. GZ1)
-- named things
local keys = {'cave', 'grotta', 'grotto', 'faro', 'lighthouse', 'molo', 'mole', 'breakwater', 'pier', 'jetty', 'cala', 'beach', 'spiaggia', 'buoy', 'rock', 'scoglio', 'whale'}
local seen = 0
for _, inst in ipairs(workspace:GetDescendants()) do
	local nm = inst.Name:lower()
	for _, k in ipairs(keys) do
		if nm:find(k, 1, true) and (inst:IsA('Model') or inst:IsA('Folder') or inst:IsA('BasePart')) then
			local ok, cf, size = pcall(function()
				if inst:IsA('BasePart') then return inst.CFrame, inst.Size end
				return inst:GetBoundingBox()
			end)
			if ok and cf and size.Magnitude > 3 then
				seen += 1
				if seen <= 80 then warn(string.format('QW@NAME %s [%s] at %.1f,%.1f,%.1f size %.0fx%.0fx%.0f', inst:GetFullName(), inst.ClassName, cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z)) end
			end
			break
		end
	end
end
warn('QW@NAMES total ' .. seen)
for _, f in ipairs(workspace:GetChildren()) do
	if (f:IsA('Folder') or f:IsA('Model')) and #f:GetChildren() > 0 then
		local ok, cf, size = pcall(function() if f:IsA('Model') then return f:GetBoundingBox() end
			local mn, mx
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA('BasePart') then
					local p = d.Position
					mn = mn and Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z)) or p
					mx = mx and Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z)) or p
				end
			end
			if not mn then return nil end
			return CFrame.new((mn + mx) / 2), mx - mn
		end)
		if ok and cf then warn(string.format('QW@TOP %s [%s] centre %.0f,%.0f,%.0f extent %.0fx%.0fx%.0f', f.Name, f.ClassName, cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z)) end
	end
end
warn('QW@SURVEY_DONE')
-- state check (handoff: verify live version + registry count before trusting PART7)
local okR, R = pcall(require, workspace.SquirrelScripts.SquirrelRegistry)
local n, np = 0, 0
if okR and type(R) == 'table' then for _, e in pairs(R) do if type(e) == 'table' then n += 1 if e.map == 'porto' then np += 1 end end end end
warn(string.format('QW@STATE placeVersion=%d registry=%d porto=%d whale=%s', game.PlaceVersion, n, np, tostring(workspace:FindFirstChild('PortoWhale') ~= nil)))
