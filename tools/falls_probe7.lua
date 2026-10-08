-- falls_probe7 v1: READ-ONLY. Her 23:26 screenshot: a teal sliver at the top of the EAST corner where the fall meets the wall,
-- seen from the foot. Measures, at several heights, where the east and west rock faces are (upstream row z ZC+1.5, the
-- brink row z ZC-0.5, and z ZC-1.5 in front of it) and how far east/west the terrain water reaches south of the brink.
local ZC = -547.5
local rock = workspace.SouthGorge.Rock
local function ray(from, dir, list, ignoreWater)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = list; rp.IgnoreWater = ignoreWater
	local r = workspace:Raycast(from, dir, rp)
	if not r then return "none" end
	return string.format("%.1f %s", r.Position.X, (r.Instance == workspace.Terrain) and (r.Material.Name:sub(1, 4)) or r.Instance.Name:gsub("South", ""))
end
for _, z in ipairs({ZC + 1.5, ZC - 0.5, ZC - 1.5, ZC - 3}) do
	local rows = {}
	for _, y in ipairs({-0.5, -1.5, -3, -5, -7, -9, -12}) do
		local e = ray(Vector3.new(215, y, z), Vector3.new(-40, 0, 0), {rock, workspace.Terrain}, true)
		local ew = ray(Vector3.new(215, y, z), Vector3.new(-40, 0, 0), {workspace.Terrain}, false)
		local w = ray(Vector3.new(155, y, z), Vector3.new(40, 0, 0), {rock, workspace.Terrain}, true)
		local ww = ray(Vector3.new(155, y, z), Vector3.new(40, 0, 0), {workspace.Terrain}, false)
		rows[#rows + 1] = string.format("y%g: E rock %s | E water %s | W rock %s | W water %s", y, e, ew, w, ww)
	end
	print(string.format("QQ FP7 z %.1f :: %s", z, table.concat(rows, " || ")))
end
-- the beams' ends as built
local rig = workspace.SouthGorge.Falls.Rig
for _, n in ipairs({"Crest", "Body", "Sheet2", "Ribbon1", "Ribbon4"}) do
	local b = rig:FindFirstChild(n)
	if b then
		local a0 = b.Attachment0.WorldPosition
		print(string.format("QQ FP7 beam %s w0 %g at x %.1f -> spans %.1f..%.1f (y %.1f z %.1f)", n, b.Width0, a0.X, a0.X - b.Width0 / 2, a0.X + b.Width0 / 2, a0.Y, a0.Z))
	end
end
print("QQ FP7 DONE")
