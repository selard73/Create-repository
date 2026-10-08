-- v48 the fishing squirrel gets rocks to stand on: a flat boulder under his feet, one half in the water in front of him
-- and a small one beside him (copies of the riverside rocks), then he is set on the boulder by his REAL underside.
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local sq = workspace:FindFirstChild("fishing_squirrel_color")
local tmpl = {}
for _, m in ipairs(workspace.Village.Props:GetChildren()) do
	if m.Name == "riverside" then
		for _, p in ipairs(m:GetChildren()) do if p:IsA("MeshPart") and p.Name:match("^Rock%d") and not tmpl[p.Name] then tmpl[p.Name] = p end end
	end
end
if not sq or not tmpl.Rock1 or not tmpl.Rock2 or not tmpl.Rock3 then P("STOP", sq, tmpl.Rock1, tmpl.Rock2, tmpl.Rock3) return end
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("FishRocks")
local old = workspace.River:FindFirstChild("FishRocks"); if old then old:Destroy() end
local M = Instance.new("Model"); M.Name = "FishRocks"; M.Parent = workspace.River
local cf0, sz0 = sq:GetBoundingBox()
local sx, sz = cf0.Position.X, cf0.Position.Z
local function rock(t, size, x, z, bottom, yaw)
	local r = tmpl[t]:Clone()
	r.Size = size; r.Anchored = true; r.CanCollide = true
	r.CFrame = CFrame.new(x, bottom + size.Y / 2, z) * CFrame.Angles(0, math.rad(yaw), 0)
	r.Parent = M
	return r
end
rock("Rock1", Vector3.new(4.0, 1.1, 3.6), sx + 0.2, sz, -0.85, 18)   -- sunk: only its top shows          -- the boulder he stands on
rock("Rock2", Vector3.new(1.7, 0.9, 1.8), sx - 2.5, sz + 0.9, -1.55, -25)   -- half in the water in front
rock("Rock3", Vector3.new(1.4, 0.7, 1.2), sx + 1.5, sz - 2.4, -0.55, 40)    -- small one beside him
-- set him on the boulder: lowest contact between his real underside and the rocks/ground below
local parts = {}
for _, p in ipairs(sq:GetDescendants()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end
local ip = RaycastParams.new(); ip.FilterType = Enum.RaycastFilterType.Include; ip.FilterDescendantsInstances = parts
local gp = RaycastParams.new(); gp.FilterType = Enum.RaycastFilterType.Include; gp.FilterDescendantsInstances = {M, workspace.Terrain}; gp.IgnoreWater = true
local gap = math.huge
for _, o in ipairs({{0, 0}, {0.4, 0.4}, {-0.4, 0.4}, {0.4, -0.4}, {-0.4, -0.4}, {0.7, 0}, {-0.7, 0}, {0, 0.9}, {0, -0.9}}) do
	local x, z = sx + o[1], sz + o[2]
	local up = workspace:Raycast(Vector3.new(x, -8, z), Vector3.new(0, 14, 0), ip)
	if up then
		local dn = workspace:Raycast(Vector3.new(x, up.Position.Y + 3, z), Vector3.new(0, -15, 0), gp)
		if dn then gap = math.min(gap, up.Position.Y - dn.Position.Y) end
	end
end
if gap ~= math.huge and math.abs(gap) < 2.5 then
	sq:PivotTo(sq:GetPivot() - Vector3.new(0, gap - 0.02, 0))
	P("fisher set on the rocks, moved", string.format("%.2f", -(gap - 0.02)))
else
	P("fisher NOT moved, gap", gap)
end
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
P("DONE44")
