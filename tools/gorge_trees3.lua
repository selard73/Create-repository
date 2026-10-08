-- gorge_trees3: CHANGES THE PLACE (cleanup): any tree in workspace.SouthGorge.Trees whose base is below y 6 is standing
-- inside the gorge (its ground was carved away) - report and remove it. Every legitimate tree stands on hills >= 9.5.
local TF = workspace.SouthGorge.Trees
local function aabb(m)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, q in ipairs(m:GetDescendants()) do
		if q:IsA("BasePart") then
			local cf, s = q.CFrame, q.Size / 2
			local ext = Vector3.new(math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
				math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
				math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)
			lo = lo:Min(cf.Position - ext); hi = hi:Max(cf.Position + ext)
		end
	end
	return lo, hi
end
local gone, list = 0, {}
for _, m in ipairs(TF:GetChildren()) do
	local lo, hi = aabb(m)
	if lo.Y < 6.0 then
		list[#list + 1] = string.format("%s@%.0f,%.1f,%.0f", m.Name, (lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
		m:Destroy(); gone += 1
	end
end
print(string.format("QQ T8 removed %d low trees (%s); left %d", gone, table.concat(list, " "), #TF:GetChildren()))
print("QQ T8 DONE")