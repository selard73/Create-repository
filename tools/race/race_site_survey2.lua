-- race/race_site_survey2 (job 36c): READ-ONLY, EDIT mode. Shannon: the race start "should be in the piazza, the huge
-- drop-off to the right of the opera singer and accordion player, where the patio just drops off", so the gate hides the
-- edge. Prints the two singers' positions and facing, what stands within 30 studs, and a 4-stud floor grid around them
-- (first surface under y -2: material code + height; p = part; . = nothing within 60). Output lines "QQ PLAZA".
local C = Vector3.new(443, -12, -792)
for _, n in ipairs({"operasinger_squirrel_color", "accordion_squirrel_color"}) do
	local m = workspace:FindFirstChild(n, true)
	if m then local cf = m:GetPivot(); print(string.format("QQ PLAZA %s at %.1f,%.1f,%.1f facing %.2f,%.2f (x,z of its look)", n, cf.Position.X, cf.Position.Y, cf.Position.Z, cf.LookVector.X, cf.LookVector.Z)) end
end
local seen = 0
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and not m.Name:lower():find("squirrel") and not m:FindFirstChildWhichIsA("Model") then
		local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
		if ok and cf and (cf.Position - C).Magnitude < 30 and size.Magnitude < 120 then
			seen += 1
			if seen <= 25 then print(string.format("QQ PLAZA model %s | centre %.0f,%.0f,%.0f | size %.0fx%.0fx%.0f", m:GetFullName():gsub("^Workspace%.PortoNocciola%.", ""), cf.Position.X, cf.Position.Y, cf.Position.Z, size.X, size.Y, size.Z)) end
		end
	end
end
local CODE = {Sand = "S", Grass = "G", Rock = "R", Slate = "T", Limestone = "L", Water = "W", Ground = "D", Cobblestone = "C", Pavement = "P", Concrete = "N", Brick = "B", WoodPlanks = "K", Asphalt = "A", Basalt = "Z", Marble = "M"}
local params = RaycastParams.new(); params.IgnoreWater = false
local STEP = 4
local head = "QQ PLAZA x:    "
for x = 403, 483, STEP do head ..= string.format("%5d", x) end
print(head)
for z = -832, -752, STEP do
	local row = string.format("QQ PLAZA z%5d", z)
	for x = 403, 483, STEP do
		local hit = workspace:Raycast(Vector3.new(x, -2, z), Vector3.new(0, -60, 0), params)
		if not hit then row ..= "    ."
		else
			local c = hit.Instance == workspace.Terrain and (CODE[hit.Material.Name] or hit.Material.Name:sub(1, 1)) or (CODE[hit.Material.Name] and CODE[hit.Material.Name]:lower() or "p")
			row ..= string.format("%5s", c .. math.floor(hit.Position.Y + 0.5))
		end
	end
	print(row)
	task.wait()
end
