-- v15 measure the v14 test patches (x -720..-576, z 700..720) a moment after they were written, then erase them to air
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local T = workspace.Terrain
local occs = {0.1, 0.3, 0.5, 0.7, 0.9, 1.0}
local x0, z0 = -720, 700
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {T}
task.wait(0.5)
for i, o in ipairs(occs) do
	local cx = x0 + (i - 1) * 24 + 10
	local h = workspace:Raycast(Vector3.new(cx, 20, z0 + 10), Vector3.new(0, -40, 0), rp)
	P("calib", o, h and string.format("%.2f", h.Position.Y) or "none")
end
T:FillBlock(CFrame.new(x0 + 72, -2, z0 + 10), Vector3.new(144, 12, 20), Enum.Material.Air)
task.wait(0.3)
local h = workspace:Raycast(Vector3.new(x0 + 58, 20, z0 + 10), Vector3.new(0, -40, 0), rp)
P("DONE15 erased", h and "STILL THERE" or "clean")
