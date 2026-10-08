-- v28 read-only: what is hit at the bridge's east landing (x 163..172, z -126..-113)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {}
for z = -126, -113, 2.5 do
	local t = {}
	for x = 163, 172, 1.5 do
		local h = workspace:Raycast(Vector3.new(x, 6, z), Vector3.new(0, -20, 0), rp)
		t[#t + 1] = string.format("%.1f:%s@%.2f", x, h and (h.Instance.Name .. "/" .. h.Material.Name:sub(1, 4)) or "-", h and h.Position.Y or 0)
	end
	print("QQ land", z, table.concat(t, " "))
end
local st = workspace.Village.Ground.Street
print("QQ street", st.Position, st.Size, st.Material.Name)
