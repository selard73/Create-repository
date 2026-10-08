-- READ-ONLY survey pass 2: Porto-only names, Porto sub-folders, fine waterline grid around the lighthouse coast.
local porto = workspace:FindFirstChild('PortoNocciola')
if not porto then warn('QW@NOPORTO') return end
for _, f in ipairs(porto:GetChildren()) do
	local ok, cf, size = pcall(function() if f:IsA('Model') then return f:GetBoundingBox() end
		if f:IsA('BasePart') then return f.CFrame, f.Size end
		local mn, mx
		for _, d in ipairs(f:GetDescendants()) do if d:IsA('BasePart') then local p = d.Position
			mn = mn and Vector3.new(math.min(mn.X,p.X),math.min(mn.Y,p.Y),math.min(mn.Z,p.Z)) or p
			mx = mx and Vector3.new(math.max(mx.X,p.X),math.max(mx.Y,p.Y),math.max(mx.Z,p.Z)) or p end end
		if not mn then return nil end
		return CFrame.new((mn+mx)/2), mx-mn end)
	if ok and cf then warn(string.format('QW@SUB %s [%s] n=%d centre %.0f,%.0f,%.0f extent %.0fx%.0fx%.0f', f.Name, f.ClassName, #f:GetDescendants(), cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z))
	else warn('QW@SUB ' .. f.Name .. ' [' .. f.ClassName .. '] n=' .. #f:GetDescendants()) end
end
local keys = {'cave', 'grotta', 'grotto', 'faro', 'lighthouse', 'light', 'molo', 'mole', 'breakwater', 'pier', 'jetty', 'cala', 'beach', 'spiaggia', 'buoy', 'boulder', 'scoglio', 'whale', 'sea', 'mouth', 'harbour', 'harbor', 'bay'}
local seen = 0
for _, inst in ipairs(porto:GetDescendants()) do
	local nm = inst.Name:lower()
	for _, k in ipairs(keys) do
		if nm:find(k, 1, true) and (inst:IsA('Model') or inst:IsA('Folder') or inst:IsA('BasePart')) then
			local ok, cf, size = pcall(function() if inst:IsA('BasePart') then return inst.CFrame, inst.Size end return inst:GetBoundingBox() end)
			if ok and cf and size.Magnitude > 3 then seen += 1
				if seen <= 120 then warn(string.format('QW@PN %s [%s] at %.1f,%.1f,%.1f size %.0fx%.0fx%.0f', inst:GetFullName():gsub('^Workspace%.PortoNocciola%.', ''), inst.ClassName, cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z)) end
			end
			break
		end
	end
end
warn('QW@PN_TOTAL ' .. seen)
-- fine grid at the waterline on the lighthouse coast: x 240..420 step 10, z -900..-1060 step 10; raycast includes parts too
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = {} rp.IgnoreWater = true
for z = -900, -1060, -10 do
	local cells = {}
	for x = 240, 420, 10 do
		local b = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -140, 0), rp)
		if not b then table.insert(cells, '..') elseif b.Instance == workspace.Terrain then table.insert(cells, string.format('%.0f', b.Position.Y)) else table.insert(cells, string.format('%.0fp', b.Position.Y)) end
	end
	warn('QW@FINE z=' .. z .. ' ' .. table.concat(cells, ' '))
end
-- sea bed check: three deep rays
for _, p in ipairs({Vector3.new(100, 20, -900), Vector3.new(0, 20, -1100), Vector3.new(200, 20, -700)}) do
	local b = workspace:Raycast(p, Vector3.new(0, -400, 0), rp)
	warn(string.format('QW@BED %.0f,%.0f -> %s', p.X, p.Z, b and string.format('%.1f %s', b.Position.Y, tostring(b.Material)) or 'none'))
end
warn('QW@SURVEY2_DONE')
