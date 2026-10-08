-- bd2 (PLAY, CLIENT, read-only): the Baseplate under the south stretch
local bp = workspace.Baseplate
warn("QQ BD2 bp", bp.ClassName, tostring(bp.Size), tostring(bp.Position), bp.CollisionGroup)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {bp}
for _, z in ipairs({-140, -166, -190}) do
	local row = {}
	for x = 144, 168, 2 do
		local r = workspace:Raycast(Vector3.new(x, 10, z), Vector3.new(0, -30, 0), rp)
		table.insert(row, x .. ":" .. (r and string.format("%.2f", r.Position.Y) or "--"))
	end
	warn("QQ BD2 z" .. z .. " " .. table.concat(row, " "))
end
