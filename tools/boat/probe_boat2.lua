-- b2 READ-ONLY boat probe (part 2): what stands in the jetty box + water depth. Changes nothing.
-- 3) everything standing in the jetty box (x 150..190, z -205..-110), grouped by top-level model
local seen = {}
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and not p:IsA("Terrain") then
		local q = p.Position
		if q.X > 150 and q.X < 190 and q.Z > -205 and q.Z < -110 and q.Y > -12 and q.Y < 40 then
			local top = p
			while top.Parent and top.Parent:IsA("Model") do top = top.Parent end
			if not seen[top] then
				seen[top] = true
				local cf, sz
				if top:IsA("Model") then cf, sz = top:GetBoundingBox() elseif top:IsA("BasePart") then cf, sz = top.CFrame, top.Size else cf, sz = p.CFrame, p.Size end
				local c = cf.Position
				print(("QQ OBJ %s | ctr %.1f %.1f %.1f | size %.1f %.1f %.1f"):format(top:GetFullName(), c.X, c.Y, c.Z, sz.X, sz.Y, sz.Z))
			end
		end
	end
end
-- 4) water surface / bed / bank along the south stretch
local pw = RaycastParams.new(); pw.IgnoreWater = false; pw.FilterType = Enum.RaycastFilterType.Include; pw.FilterDescendantsInstances = {workspace.Terrain}
local pb = RaycastParams.new(); pb.IgnoreWater = true; pb.FilterType = Enum.RaycastFilterType.Include; pb.FilterDescendantsInstances = {workspace.Terrain}
local pa = RaycastParams.new(); pa.IgnoreWater = true
for z = -126, -206, -5 do
	local row = {}
	for x = 140, 176, 3 do
		local w = workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), pw)
		local b = workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), pb)
		local a = workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), pa)
		local tag
		if w and w.Material == Enum.Material.Water then
			tag = ("W%.0f"):format(w.Position.Y - (b and b.Position.Y or -30))   -- water depth
		else
			tag = a and ("%s%.1f"):format(a.Instance == workspace.Terrain and "t" or "p", a.Position.Y) or "--"
		end
		table.insert(row, ("%d:%s"):format(x, tag))
	end
	print("QQ DEPTH z" .. z .. " " .. table.concat(row, " "))
end
print("QQ DONE b2")
