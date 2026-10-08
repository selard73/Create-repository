-- READ-ONLY survey pass 3: lighthouse-coast children, exact-key names, fine grid to the SE.
local porto = workspace:FindFirstChild('PortoNocciola')
local lc = porto and porto:FindFirstChild('14 Lighthouse coast')
local function bb(inst)
	local ok, cf, size = pcall(function() if inst:IsA('BasePart') then return inst.CFrame, inst.Size end return inst:GetBoundingBox() end)
	if ok and cf then return cf.Position, size end
end
if lc then
	for _, c in ipairs(lc:GetChildren()) do
		local p, s = bb(c)
		if p then warn(string.format('QW@LC %s [%s] n=%d at %.0f,%.0f,%.0f size %.0fx%.0fx%.0f', c.Name, c.ClassName, #c:GetDescendants(), p.X, p.Y, p.Z, s.X, s.Y, s.Z))
		else warn('QW@LC ' .. c.Name .. ' [' .. c.ClassName .. '] n=' .. #c:GetDescendants()) end
		-- one level deeper for models
		if c:IsA('Model') or c:IsA('Folder') then
			for _, g in ipairs(c:GetChildren()) do
				if (g:IsA('Model') or g:IsA('Folder')) then local p2, s2 = bb(g)
					if p2 then warn(string.format('QW@LC2   %s / %s [%s] n=%d at %.0f,%.0f,%.0f size %.0fx%.0fx%.0f', c.Name, g.Name, g.ClassName, #g:GetDescendants(), p2.X, p2.Y, p2.Z, s2.X, s2.Y, s2.Z)) end
				end
			end
		end
	end
else warn('QW@NOLC') end
local keys = {'cave', 'grotta', 'grotto', 'faro', 'lighthouse', 'lantern', 'boulder', 'scoglio', 'headland', 'tower'}
local seen = 0
for _, inst in ipairs(workspace:GetDescendants()) do
	local nm = inst.Name:lower()
	if not nm:find('squirrel', 1, true) then
		for _, k in ipairs(keys) do
			if nm:find(k, 1, true) and (inst:IsA('Model') or inst:IsA('Folder') or inst:IsA('BasePart')) then
				local p, s = bb(inst)
				if p and p.Z < -500 then seen += 1
					if seen <= 60 then warn(string.format('QW@KEY %s [%s] at %.1f,%.1f,%.1f size %.0fx%.0fx%.0f', inst:GetFullName():gsub('^Workspace%.PortoNocciola%.', ''), inst.ClassName, p.X, p.Y, p.Z, s.X, s.Y, s.Z)) end
				end
				break
			end
		end
	end
end
warn('QW@KEY_TOTAL ' .. seen)
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = {} rp.IgnoreWater = true
for z = -1040, -1220, -10 do
	local cells = {}
	for x = 360, 540, 10 do
		local b = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -160, 0), rp)
		if not b then table.insert(cells, '..') elseif b.Instance == workspace.Terrain then table.insert(cells, string.format('%.0f', b.Position.Y)) else table.insert(cells, string.format('%.0fp', b.Position.Y)) end
	end
	warn('QW@FINE3 z=' .. z .. ' ' .. table.concat(cells, ' '))
end
-- horizontal rays at the waterline toward the cliff (find cave mouths: a ray at y=-50 that travels further than one at y=-40)
for z = -1040, -1200, -10 do
	local lo = workspace:Raycast(Vector3.new(340, -50, z), Vector3.new(260, 0, 0), rp)
	local hi = workspace:Raycast(Vector3.new(340, -40, z), Vector3.new(260, 0, 0), rp)
	warn(string.format('QW@HRAY z=%d lo=%s hi=%s', z, lo and string.format('%.0f', lo.Position.X) or 'none', hi and string.format('%.0f', hi.Position.X) or 'none'))
end
for z = -900, -1030, -10 do
	local lo = workspace:Raycast(Vector3.new(240, -50, z), Vector3.new(200, 0, 0), rp)
	local hi = workspace:Raycast(Vector3.new(240, -40, z), Vector3.new(200, 0, 0), rp)
	warn(string.format('QW@HRAY z=%d lo=%s hi=%s', z, lo and string.format('%.0f', lo.Position.X) or 'none', hi and string.format('%.0f', hi.Position.X) or 'none'))
end
warn('QW@SURVEY3_DONE')
