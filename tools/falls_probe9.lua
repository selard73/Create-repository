-- falls_probe9 v1: READ-ONLY. What are the teal blobs at the two corners of the lip? Rays from her low camera
-- (185.4, -14, -578) toward points across each blob; prints what they hit (instance or terrain material) and where.
local from = Vector3.new(185.4, -14.0, -578.0)
local targets = {
	{"E1", Vector3.new(197, -3, -547.5)}, {"E2", Vector3.new(200, -5, -547)}, {"E3", Vector3.new(203, -3, -548)}, {"E4", Vector3.new(205, -6, -549)},
	{"W1", Vector3.new(174, -3, -547.5)}, {"W2", Vector3.new(171, -5, -547)}, {"W3", Vector3.new(168, -3, -548)}, {"W4", Vector3.new(166, -6, -549)},
	{"C", Vector3.new(185.4, -3, -547.5)},
}
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {workspace.SouthGorge.FallsB, workspace.SouthGorge.Falls}
rp.IgnoreWater = false
local out = {}
for _, t in ipairs(targets) do
	local dir = (t[2] - from).Unit * 80
	local r = workspace:Raycast(from, dir, rp)
	if r then
		local what = (r.Instance == workspace.Terrain) and ("terrain " .. r.Material.Name) or (r.Instance:GetFullName() .. " [" .. r.Instance.ClassName .. "]")
		out[#out + 1] = string.format("%s -> %s at (%.1f, %.1f, %.1f)", t[1], what, r.Position.X, r.Position.Y, r.Position.Z)
	else
		out[#out + 1] = t[1] .. " -> nothing"
	end
end
print("QQ P9 " .. table.concat(out, " | "))
-- the rocks near the lip, for the record
local R = workspace.SouthGorge:FindFirstChild("RapidsRocks")
local near = {}
if R then for _, p in ipairs(R:GetChildren()) do if p:IsA("BasePart") and p.Position.Z < -528 then near[#near + 1] = string.format("%s (%.1f, %.1f, %.1f) size %.1f", p.Name, p.Position.X, p.Position.Y, p.Position.Z, math.max(p.Size.X, p.Size.Z)) end end end
print("QQ P9 rocks near the lip: " .. table.concat(near, "; "))
print("QQ P9 DONE")
