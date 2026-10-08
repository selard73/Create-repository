-- v35 read-only: what is under the painter (terrain / Baseplate), and a camera on him
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain, workspace.Baseplate}; rp.IgnoreWater = true
local t = {}
for _, o in ipairs({{0, 0}, {-2, 0}, {2, 0}, {0, -2}, {0, 2}, {-4, 0}, {4, 0}}) do
	local h = workspace:Raycast(Vector3.new(187.5 + o[1], 6, -19.6 + o[2]), Vector3.new(0, -20, 0), rp)
	t[#t + 1] = string.format("(%d,%d)%s@%.2f", o[1], o[2], h and h.Instance.Name or "-", h and h.Position.Y or 0)
end
print("QQ under", table.concat(t, " "))
local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = {workspace.painter_squirrel_color}
local up = workspace:Raycast(Vector3.new(187.5, -8, -19.6), Vector3.new(0, 14, 0), ip)
print("QQ feet", up and up.Position.Y)
local cam = workspace.CurrentCamera
cam.CFrame = CFrame.lookAt(Vector3.new(180, 4, -12), Vector3.new(187.5, 0.3, -19.6))
