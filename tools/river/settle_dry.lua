-- v37d settle (DRY) (ground measured from 2.5 above the underside, so sunk things are seen too): set floating things by the river down onto the ground under them (run a few seconds after v31).
-- For each unit, the REAL underside is found by raycasting up into it (a mesh does not fill its box), and the ground by
-- raycasting down onto terrain / the Baseplate / paving (water ignored). The unit moves down by the smallest gap, so its
-- lowest contact just touches. Rocks and bushes standing in the water may sit partly under the waterline instead.
-- Only lowers, never more than 1.2 studs. MODE "dry" reports only.
local MODE = "dry"
local WATER_Y = -0.9
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local river = workspace.Village.Props.river
local W = river.Water
-- the old outline, coarse (the Water mesh is hidden but still queryable)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {W}
W.CanQuery = true
local function nearRiver(x, z)
	for dx = -16, 16, 2 do
		if workspace:Raycast(Vector3.new(x + dx, 30, z), Vector3.new(0, -60, 0), rp) then return true, math.abs(dx) end
	end
	return false
end
local groundList = {workspace.Terrain, workspace.Baseplate, workspace.Village.Ground}
if workspace.River:FindFirstChild("Quay") then table.insert(groundList, workspace.River.Quay) end
local gp = RaycastParams.new(); gp.FilterType = Enum.RaycastFilterType.Include; gp.FilterDescendantsInstances = groundList; gp.IgnoreWater = true

local units = {}
local function add(name, parts, mover, wet) units[#units + 1] = {name = name, parts = parts, mover = mover, wet = wet} end
local props = workspace.Village.Props
for _, m in ipairs(props:GetChildren()) do
	if m.Name == "riverside" then
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then add("riverside." .. p.Name, {p}, p, true) end
		end
	elseif m.Name == "plane_tree" or m.Name == "easel" then
		local parts = {}
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end
		add(m.Name, parts, m, false)
	end
end
for _, m in ipairs(workspace:GetChildren()) do
	if m:IsA("Model") and m.Name:find("_color") then
		local parts = {}
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end
		add(m.Name, parts, m, false)
	end
end

local moved = 0
for _, u in ipairs(units) do
	local lo = math.huge
	local cx, cz = 0, 0
	for _, p in ipairs(u.parts) do lo = math.min(lo, p.Position.Y - p.Size.Y / 2); cx += p.Position.X; cz += p.Position.Z end
	cx /= #u.parts; cz /= #u.parts
	local near = cz > -260 and cz < 70 and nearRiver(cx, cz)
	if near and lo < 2 then
		local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = u.parts
		local gap = math.huge
		for _, p in ipairs(u.parts) do
			if p.Position.Y - p.Size.Y / 2 < lo + 1.5 then            -- only the parts near the bottom can touch the ground
				local cf, s = p.CFrame, p.Size / 2
				for _, o in ipairs({{0, 0}, {0.35, 0.35}, {-0.35, 0.35}, {0.35, -0.35}, {-0.35, -0.35}, {0.45, 0}, {-0.45, 0}, {0, 0.45}, {0, -0.45}}) do
					local w = cf * Vector3.new(o[1] * s.X * 2, 0, o[2] * s.Z * 2)
					local up = workspace:Raycast(Vector3.new(w.X, lo - 8, w.Z), Vector3.new(0, 12, 0), ip)
					if up then
						local dn = workspace:Raycast(Vector3.new(w.X, up.Position.Y + 2.5, w.Z), Vector3.new(0, -15, 0), gp)
						local g = dn and dn.Position.Y or -12
						if u.wet then g = math.max(g, WATER_Y - 0.6) end
						gap = math.min(gap, up.Position.Y - g)
					end
				end
			end
		end
		if gap ~= math.huge then
			local d = math.clamp(gap - 0.02, 0, 1.2)
			if gap > 0.06 then
				P("settle", u.name, string.format("%.1f,%.1f", cx, cz), string.format("gap %.2f -> down %.2f", gap, d))
				if MODE == "build" then
					if u.mover:IsA("Model") then u.mover:PivotTo(u.mover:GetPivot() - Vector3.new(0, d, 0))
					else u.mover.CFrame = u.mover.CFrame - Vector3.new(0, d, 0) end
					moved += 1
				end
			elseif gap < -0.15 then
				P("sunk", u.name, string.format("%.1f,%.1f", cx, cz), string.format("gap %.2f", gap))
			end
		end
	end
end
W.CanQuery = false
P("SETTLE DONE", MODE, moved, "moved")
