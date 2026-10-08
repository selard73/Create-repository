-- gorge_probe1: READ-ONLY. Saves the editor camera, samples terrain along the river south of the rim, lists parts out there.
local cam = workspace.CurrentCamera
print("QQ G1 CAM", cam.FieldOfView, table.concat({cam.CFrame:GetComponents()}, ","))
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}
tp.IgnoreWater = false
local tpd = RaycastParams.new(); tpd.FilterType = Enum.RaycastFilterType.Include; tpd.FilterDescendantsInstances = {workspace.Terrain}
tpd.IgnoreWater = true
local short = {Grass = "g", Water = "~", Sand = "s", Mud = "m", Ground = "e", Rock = "r", Slate = "l", LeafyGrass = "G", Sandstone = "S", Limestone = "L", Cobblestone = "c", Basalt = "b"}
print("QQ G1 profile: per z, x 60..260 step 4; char = top material (~ water); then bed depth at water centre")
for z = -180, -900, -20 do
	local row, wmin, wmax, bed = {}, nil, nil, nil
	for x = 60, 260, 4 do
		local r = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), tp)
		local c = "."
		if r then c = short[r.Material.Name] or "?"; if r.Material == Enum.Material.Water then wmin = wmin or x; wmax = x end end
		row[#row + 1] = c
	end
	if wmin then
		local mid = (wmin + wmax) / 2
		local d = workspace:Raycast(Vector3.new(mid, 200, z), Vector3.new(0, -400, 0), tpd)
		bed = d and string.format("%.1f", d.Position.Y) or "none"
	end
	print(string.format("QQ G1 Z %4d %s | water x %s..%s bed %s", z, table.concat(row), tostring(wmin), tostring(wmax), tostring(bed)))
end
-- ground heights just outside the rim (x -150..700 at z -270, -320, -400)
for _, z in ipairs({-230, -270, -320, -400, -600}) do
	local hs = {}
	for x = -150, 700, 50 do
		local r = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
		hs[#hs + 1] = r and string.format("%.0f%s", r.Position.Y, r.Instance == workspace.Terrain and "t" or "p") or "-"
	end
	print("QQ G1 H z" .. z, table.concat(hs, " "))
end
-- parts outside the south wall (z < -252), x -200..800, down to z -1100
local counts = {}
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and p.Name ~= "Baseplate" then
		local q = p.Position
		if q.Z < -252 and q.Z > -1100 and q.X > -200 and q.X < 800 then
			local top = p:FindFirstAncestorOfClass("Folder") or p:FindFirstAncestorOfClass("Model") or p
			local key = top:GetFullName() .. (p.Transparency >= 1 and " (invisible)" or "")
			local c = counts[key] or {n = 0, zmin = 1e9, zmax = -1e9, xmin = 1e9, xmax = -1e9}
			c.n += 1; c.zmin = math.min(c.zmin, q.Z); c.zmax = math.max(c.zmax, q.Z); c.xmin = math.min(c.xmin, q.X); c.xmax = math.max(c.xmax, q.X)
			counts[key] = c
		end
	end
end
for k, c in pairs(counts) do print(string.format("QQ G1 OUT %s n=%d x %.0f..%.0f z %.0f..%.0f", k, c.n, c.xmin, c.xmax, c.zmin, c.zmax)) end
local L = game:GetService("Lighting")
print("QQ G1 LIGHT", L.ClockTime, "fogend", L.FogEnd, "atmo", tostring(L:FindFirstChildOfClass("Atmosphere") ~= nil), "sky", tostring(L:FindFirstChildOfClass("Sky") and L:FindFirstChildOfClass("Sky").Name))
local a = L:FindFirstChildOfClass("Atmosphere"); if a then print("QQ G1 ATMO density", a.Density, "haze", a.Haze, "offset", a.Offset, "glare", a.Glare) end
print("QQ G1 DONE")
