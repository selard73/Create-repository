-- italy_survey1: READ-ONLY. Bounds of each top-level workspace child + a 50-stud raycast map of what occupies the ground.
local skip = {Camera = true, Terrain = true}
local function bounds(inst)
	local mn, mx, n = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9), 0
	local list = inst:IsA("BasePart") and {inst} or inst:GetDescendants()
	for _, p in ipairs(list) do
		if p:IsA("BasePart") then
			local c, s = p.CFrame, p.Size / 2
			local e = Vector3.new(
				math.abs(c.RightVector.X) * s.X + math.abs(c.UpVector.X) * s.Y + math.abs(c.LookVector.X) * s.Z,
				math.abs(c.RightVector.Y) * s.X + math.abs(c.UpVector.Y) * s.Y + math.abs(c.LookVector.Y) * s.Z,
				math.abs(c.RightVector.Z) * s.X + math.abs(c.UpVector.Z) * s.Y + math.abs(c.LookVector.Z) * s.Z)
			mn = mn:Min(c.Position - e); mx = mx:Max(c.Position + e); n += 1
		end
	end
	return mn, mx, n
end
local all_mn, all_mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
for _, ch in ipairs(workspace:GetChildren()) do
	if not skip[ch.Name] and (ch:IsA("Model") or ch:IsA("Folder") or ch:IsA("BasePart")) then
		local mn, mx, n = bounds(ch)
		if n > 0 then
			print(string.format("QQ S1 %s [%s] parts=%d x %.0f..%.0f y %.0f..%.0f z %.0f..%.0f", ch.Name, ch.ClassName, n, mn.X, mx.X, mn.Y, mx.Y, mn.Z, mx.Z))
			if ch.Name ~= "Baseplate" then all_mn = all_mn:Min(mn); all_mx = all_mx:Max(mx) end
		end
	end
end
print(string.format("QQ S1 ALL(no baseplate) x %.0f..%.0f y %.0f..%.0f z %.0f..%.0f", all_mn.X, all_mx.X, all_mn.Y, all_mx.Y, all_mn.Z, all_mx.Z))
print("QQ S1 streaming", tostring(workspace.StreamingEnabled), "fallen", workspace.FallenPartsDestroyHeight)

local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}
local pp = RaycastParams.new(); pp.FilterType = Enum.RaycastFilterType.Exclude; pp.FilterDescendantsInstances = {workspace.Terrain}
local STEP, R = 50, 2500
local tmn, tmx = Vector2.new(1e9, 1e9), Vector2.new(-1e9, -1e9)
print("QQ S1 MAP step", STEP, "x from", -R, "left->right, rows z from", -R, "top->bottom. T terrain, W terrain water top, P part, B both, . empty")
for z = -R, R, STEP do
	local row = {}
	for x = -R, R, STEP do
		local o = Vector3.new(x, 1500, z)
		local t = workspace:Raycast(o, Vector3.new(0, -3000, 0), tp)
		local p = workspace:Raycast(o, Vector3.new(0, -3000, 0), pp)
		local ch = "."
		if t and p then ch = "B" elseif t then ch = (t.Material == Enum.Material.Water) and "W" or "T" elseif p then ch = "P" end
		if t then tmn = tmn:Min(Vector2.new(x, z)); tmx = tmx:Max(Vector2.new(x, z)) end
		row[#row + 1] = ch
	end
	print(string.format("QQ S1 R %5d %s", z, table.concat(row)))
end
print(string.format("QQ S1 terrain cells x %.0f..%.0f z %.0f..%.0f", tmn.X, tmx.X, tmn.Y, tmx.Y))
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") and d.Name == "BoatPrompt" then print("QQ S1 BOATPROMPT", d:GetFullName(), "Enabled", d.Enabled) end
end
print("QQ S1 DONE")
