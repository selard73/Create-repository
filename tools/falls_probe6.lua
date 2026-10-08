-- falls_probe6 v2: READ-ONLY. For the rapids rocks: the boat's size (how wide the clear channel must be), the surface
-- (water or bank, and its height) across the river at the rapids' head and along the run, and the existing Falls model.
local boat = workspace:FindFirstChild("River") and workspace.River:FindFirstChild("BoatPreview") and workspace.River.BoatPreview:FindFirstChild("Boat")
if boat then
	local cf, size
	if boat:IsA("Model") then cf, size = boat:GetBoundingBox() else cf, size = boat.CFrame, boat.Size end
	print(string.format("QQ FP6 boat %s size %.1f x %.1f x %.1f at (%.1f, %.1f, %.1f) look (%.2f, %.2f, %.2f) children %d", boat.ClassName, size.X, size.Y, size.Z, cf.X, cf.Y, cf.Z, cf.LookVector.X, cf.LookVector.Y, cf.LookVector.Z, #boat:GetChildren()))
else
	print("QQ FP6 boat NOT FOUND under workspace.River.BoatPreview")
end
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = {workspace.Terrain}
rp.IgnoreWater = false
local function surf(x, z)
	local r = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0), rp)
	if not r then return "none" end
	return string.format("%s@%.1f", r.Material.Name:sub(1, 5), r.Position.Y)
end
for _, z in ipairs({-495, -499, -503, -509, -515, -521, -527, -533, -539}) do
	local row = {}
	for x = 176, 216, 2.5 do row[#row + 1] = string.format("%g:%s", x, surf(x, z)) end
	print("QQ FP6 z " .. z .. " | " .. table.concat(row, " "))
end
-- the river bed under the water at four spots (ignore water)
local rp2 = RaycastParams.new()
rp2.FilterType = Enum.RaycastFilterType.Include
rp2.FilterDescendantsInstances = {workspace.Terrain}
rp2.IgnoreWater = true
local beds = {}
for _, p in ipairs({{197, -495}, {199, -509}, {193, -527}, {186, -541}}) do
	local r = workspace:Raycast(Vector3.new(p[1], 10, p[2]), Vector3.new(0, -60, 0), rp2)
	beds[#beds + 1] = string.format("(%d,%d) bed %s", p[1], p[2], r and string.format("%.1f %s", r.Position.Y, r.Material.Name) or "none")
end
print("QQ FP6 beds: " .. table.concat(beds, "; "))
local F = workspace.SouthGorge:FindFirstChild("Falls")
local rr = workspace.SouthGorge:FindFirstChild("RapidsRocks")
print(string.format("QQ FP6 Falls %s (%d descendants); RapidsRocks %s", F and "present" or "MISSING", F and #F:GetDescendants() or 0, rr and ("present " .. #rr:GetChildren()) or "absent"))
print("QQ FP6 DONE")
