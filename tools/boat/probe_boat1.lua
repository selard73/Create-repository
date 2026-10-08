-- b1 READ-ONLY boat probe: 44-count code, jetty area on the Rue quay south of the bridge, water depth. Changes nothing.
local cam = workspace.CurrentCamera
print("QQ CAM " .. tostring(cam.FieldOfView) .. " | " .. tostring(cam.CFrame))
-- 1) every script line that mentions the found counts / 44 / passport totals
local pats = {"Found_", "%f[%w]44%f[%W]", "Total", "SquirrelRegistry", "[Aa]llFound"}
for _, s in ipairs(game:GetDescendants()) do
	if s:IsA("LuaSourceContainer") then
		local ok, src = pcall(function() return s.Source end)
		if ok and src then
			local n = 0
			for line in (src .. "\n"):gmatch("(.-)\n") do
				n += 1
				for _, p in ipairs(pats) do
					if line:find(p) then
						print(("QQ SRC %s:%d: %s"):format(s:GetFullName(), n, line:sub(1, 180)))
						break
					end
				end
			end
		end
	end
end
local reg = workspace:FindFirstChild("SquirrelScripts") and workspace.SquirrelScripts:FindFirstChild("SquirrelRegistry")
if reg then
	print("QQ REG class " .. reg.ClassName)
	for k, v in pairs(reg:GetAttributes()) do print("QQ REG attr " .. k .. " = " .. tostring(v)) end
	for _, c in ipairs(reg:GetChildren()) do print("QQ REG child " .. c.Name .. " " .. c.ClassName) end
end
-- 2) river attributes
local R = workspace:FindFirstChild("River")
if R then for k, v in pairs(R:GetAttributes()) do print("QQ RIVER " .. k .. " = " .. tostring(v)) end end
-- 3) everything standing in the jetty box (x 150..190, z -205..-110), grouped by top-level model
local seen = {}
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and not p:IsA("Terrain") then
		local q = p.Position
		if q.X > 150 and q.X < 190 and q.Z > -205 and q.Z < -110 and q.Y > -12 and q.Y < 40 then
			local top = p
			while top.Parent and top.Parent ~= workspace and not (top.Parent:IsA("Folder") and top.Parent.Parent == workspace) do top = top.Parent end
			if not seen[top] then
				seen[top] = true
				local cf, sz
				if top:IsA("Model") then cf, sz = top:GetBoundingBox() else cf, sz = top.CFrame, top.Size end
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
print("QQ DONE b1")
