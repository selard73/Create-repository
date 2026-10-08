-- falls_probe2: READ-ONLY. What is the teal band above the water sheet at the lip, seen from the harbour? Rays from the
-- harbour camera's eye (218.8, -44, -707.5) toward the lip at several heights, with and without water, and the lip
-- pieces' placement.
local eye = Vector3.new(218.8, -44, -707.5)
local function cast(ignoreWater, target)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {}
	rp.IgnoreWater = ignoreWater
	local r = workspace:Raycast(eye, (target - eye).Unit * 400, rp)
	if not r then return "nothing" end
	return string.format("%s%s at (%.1f,%.1f,%.1f) %s", r.Instance.Name, r.Instance:IsA("Terrain") and ("/" .. r.Material.Name) or "", r.Position.X, r.Position.Y, r.Position.Z, r.Instance:IsA("Terrain") and "" or ("[" .. r.Instance.ClassName .. "]"))
end
for _, y in ipairs({-8, -6, -4, -2.5, -1.5, -0.5, 0.5, 1.5, 3, 5}) do
	local t = Vector3.new(183.8, y, -548)
	print(string.format("QQ FP2 to lip y %+.1f: solid-only -> %s | with water -> %s", y, cast(true, t), cast(false, t)))
end
for _, nm in ipairs({"SouthCliff_L01", "SouthCliff_L01_Lo"}) do
	local p = workspace.SouthGorge.Rock:FindFirstChild(nm)
	if p then print(string.format("QQ FP2 %s pos %s size %s doubleSided %s look %s", nm, tostring(p.Position), tostring(p.Size), tostring(p.DoubleSided), tostring(p.CFrame.LookVector))) end
end
local F = workspace.SouthGorge:FindFirstChild("Falls")
if F then
	for _, b in ipairs(F:GetDescendants()) do
		if b:IsA("Beam") then print(string.format("QQ FP2 beam %s A0 %s A1 %s w %.0f/%.0f curve %.1f/%.1f", b.Name, tostring(b.Attachment0.WorldPosition), tostring(b.Attachment1.WorldPosition), b.Width0, b.Width1, b.CurveSize0, b.CurveSize1)) end
	end
end
print("QQ FP2 DONE")
