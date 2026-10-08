-- gorge_probe2: READ-ONLY. The real river channel south of the rim (every 4 studs), the ground south of the map,
-- the old riverside props outside the rim, and the south boundary walls. Nothing is changed.
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}
local tpd = RaycastParams.new(); tpd.FilterType = Enum.RaycastFilterType.Include; tpd.FilterDescendantsInstances = {workspace.Terrain}; tpd.IgnoreWater = true
local out = {}
for z = -196, -640, -4 do
	local wmin, wmax
	for x = 40, 300, 1 do
		local r = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -200, 0), tp)
		if r and r.Material == Enum.Material.Water then wmin = wmin or x; wmax = x end
	end
	if wmin then
		local mid = (wmin + wmax) / 2
		local d = workspace:Raycast(Vector3.new(mid, 100, z), Vector3.new(0, -200, 0), tpd)
		out[#out + 1] = string.format("%d:%d:%d:%.1f", z, wmin, wmax, d and d.Position.Y or -99)
	else
		out[#out + 1] = string.format("%d:-:-:-", z)
	end
	if #out == 16 then print("QQ G2 CH " .. table.concat(out, " ")); out = {} end
end
if #out > 0 then print("QQ G2 CH " .. table.concat(out, " ")) end
-- ground height (any hit, terrain or part) every 16 studs south of z -200, x -240..1000
local all = RaycastParams.new(); all.FilterType = Enum.RaycastFilterType.Exclude; all.FilterDescendantsInstances = {}
for z = -200, -1020, -16 do
	local row = {}
	for x = -240, 1000, 16 do
		local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), all)
		row[#row + 1] = r and string.format("%d", math.floor(r.Position.Y + 0.5)) or "-"
	end
	print(string.format("QQ G2 H %d %s", z, table.concat(row, ",")))
end
-- the old riverside props outside the rim: top-level children of Village.Props that reach south of z -210
local props = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Props")
if props then
	for _, ch in ipairs(props:GetChildren()) do
		local cf, sz
		if ch:IsA("Model") then cf, sz = ch:GetBoundingBox() elseif ch:IsA("BasePart") then cf, sz = ch.CFrame, ch.Size end
		if cf and cf.Position.Z - sz.Z / 2 < -210 then
			local vis = "?"
			if ch:IsA("BasePart") then vis = tostring(ch.Transparency) else local p = ch:FindFirstChildWhichIsA("BasePart", true); vis = p and tostring(p.Transparency) or "?" end
			print(string.format("QQ G2 PROP %s [%s] c %.0f,%.0f,%.0f size %.0f,%.0f,%.0f transp %s", ch.Name, ch.ClassName, cf.Position.X, cf.Position.Y, cf.Position.Z, sz.X, sz.Y, sz.Z, vis))
		end
	end
end
-- boundary walls whose ends reach south of z -200 (every Boundary folder, by name)
for _, b in ipairs(workspace:GetChildren()) do
	if b.Name == "Boundary" then
		for _, w in ipairs(b:GetDescendants()) do
			if w:IsA("BasePart") and w.Name == "Wall" then
				local a = w.CFrame * Vector3.new(-w.Size.X / 2, 0, 0)
				local c = w.CFrame * Vector3.new(w.Size.X / 2, 0, 0)
				if math.min(a.Z, c.Z) < -200 then
					print(string.format("QQ G2 WALL %s %.0f,%.0f -> %.0f,%.0f top %.0f", w.Parent.Name, a.X, a.Z, c.X, c.Z, w.Position.Y + w.Size.Y / 2))
				end
			end
		end
	end
end
local sc = workspace:FindFirstChild("SandstoneClimb")
if sc then
	for _, w in ipairs(sc:GetDescendants()) do
		if w:IsA("BasePart") and w.Transparency >= 1 and w.CanCollide and w.Size.Y > 60 then
			local a = w.CFrame * Vector3.new(-w.Size.X / 2, 0, 0); local c = w.CFrame * Vector3.new(w.Size.X / 2, 0, 0)
			print(string.format("QQ G2 CLIMBWALL %s %.0f,%.0f -> %.0f,%.0f top %.0f", w.Name, a.X, a.Z, c.X, c.Z, w.Position.Y + w.Size.Y / 2))
		end
	end
end
print("QQ G2 DONE")
