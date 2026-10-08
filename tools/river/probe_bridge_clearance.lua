-- v77 read-only: how high is the bridge deck's underside above the water (y -0.9) across the river at z -120?
local bps = {}
for _, d in ipairs(workspace.Village.Props.bridge:GetDescendants()) do if d:IsA("BasePart") and d.Transparency < 1 then bps[#bps + 1] = d end end
local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = bps
local t = {}
for x = 144, 166, 2 do
	local lo = math.huge
	for z = -123.5, -116.5, 1 do
		local h = workspace:Raycast(Vector3.new(x, -0.9, z), Vector3.new(0, 10, 0), ip)
		if h then lo = math.min(lo, h.Position.Y) end
	end
	t[#t + 1] = x .. ":" .. (lo < math.huge and string.format("%.2f", lo + 0.9) or "-")
end
print("QQ clearance above water", table.concat(t, " "))
