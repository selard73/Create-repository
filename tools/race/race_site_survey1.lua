-- race/race_site_survey1 (job 36b): READ-ONLY, EDIT mode. Shannon: the Piazza Race's start and board go "next to the
-- sailing club by where the policeman is" (officer_acorn_police_squirrel at 465,-12,-963). Prints what stands within 40
-- studs (sailing club, boats, benches...) and a 3-stud grid of the first surface under y -4: material code + height
-- (p = a part, W = water, . = nothing within 30), so a flat open 20 x 12 patch can be chosen for the gate. "QQ SITE".
local C = Vector3.new(465, -12, -963)
local seen = 0
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m.Parent and not m.Parent:IsA("Model") and not m.Name:lower():find("squirrel") then
		local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
		if ok and cf and (cf.Position - C).Magnitude < 40 and size.Magnitude < 400 then
			seen += 1
			if seen <= 30 then print(string.format("QQ SITE model %s | centre %.0f,%.0f,%.0f | size %.0fx%.0fx%.0f", m:GetFullName(), cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z)) end
		end
	end
end
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m.Name:lower():find("squirrel") and (m:GetPivot().Position - C).Magnitude < 40 then
		local p = m:GetPivot().Position; print(string.format("QQ SITE squirrel %s at %.0f,%.0f,%.0f", m.Name, p.X, p.Y, p.Z))
	end
end
local CODE = {Sand = "S", Grass = "G", Rock = "R", Slate = "T", Limestone = "L", Water = "W", Ground = "D", Cobblestone = "C", Pavement = "P", Concrete = "N", Brick = "B", WoodPlanks = "K", Asphalt = "A", Basalt = "Z"}
local params = RaycastParams.new(); params.IgnoreWater = false
local STEP = 3
local head = "QQ SITE x:    "
for x = 435, 495, STEP do head ..= string.format("%5d", x) end
print(head)
for z = -995, -931, STEP do
	local row = string.format("QQ SITE z%5d", z)
	for x = 435, 495, STEP do
		local hit = workspace:Raycast(Vector3.new(x, -4, z), Vector3.new(0, -30, 0), params)
		if not hit then row ..= "    ."
		else
			local c = hit.Instance == workspace.Terrain and (CODE[hit.Material.Name] or hit.Material.Name:sub(1, 1)) or (CODE[hit.Material.Name] and CODE[hit.Material.Name]:lower() or "p")
			row ..= string.format("%5s", c .. math.floor(hit.Position.Y + 0.5))
		end
	end
	print(row)
	task.wait()
end
