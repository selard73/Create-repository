-- b5 READ-ONLY: find the thin wire crossing the river near z -165..-180
local rp = RaycastParams.new(); rp.IgnoreWater = true; rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {workspace.Terrain}
for _, x in ipairs({150, 156, 162}) do
	for z = -150, -190, -0.2 do
		local r = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -119, 0), rp)
		if r and r.Position.Y > 2 and not r.Instance:IsDescendantOf(workspace.Boundary) then print(("QQ OVER5 %d %.1f %s %.1f"):format(x, z, r.Instance:GetFullName(), r.Position.Y)) end
	end
end
print("QQ DONE b5")