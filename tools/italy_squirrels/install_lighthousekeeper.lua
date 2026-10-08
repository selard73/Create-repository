-- Oct 7 2026 (night): Lighthouse Keeper Squirrel (lighthousekeeper_squirrel), The Groves 8 of 15. Spot (her yes): on the round
-- stone base of the Faro di Porto Nocciola, just right (east) of the green door (520,2..8,-1168.9, faces +z), facing the meadow
-- path (north). Facing from the TAIL. Registry after the Treasure Hunter.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'lighthousekeeper_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then return 'QM@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not (Bn.Head and Bn.Tail2) then return 'QM@ABORT no Head/Tail2 bone' end
local rel = cm.CFrame:Inverse() * col:GetPivot() col:PivotTo(CFrame.new(cm.Position) * rel)
local function axes()
	local tl = cm.CFrame:PointToObjectSpace(Bn.Tail2.WorldPosition)
	return tl.Z > 0 and 1 or -1, tl.X < 0 and 1 or -1
end
local function face(want)
	for i = 1, 3 do
		local sz = axes()
		local R = cm.CFrame - cm.Position
		local fwd = R:VectorToWorldSpace(Vector3.new(0, 0, -sz)) * Vector3.new(1, 0, 1)
		local ang = math.atan2(want.X, want.Z) - math.atan2(fwd.X, fwd.Z)
		local c = CFrame.new(cm.Position) col:PivotTo(c * CFrame.Angles(0, ang, 0) * c:Inverse() * col:GetPivot())
	end
end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
rp.IgnoreWater = false
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, 4.5, p.Z), Vector3.new(0, -10, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(523.8, 0, -1166.6)
local WANT = Vector3.new(0, 0, 1)  -- north, toward the meadow path
-- feet (feet_probe, model units)
local feet = {{-0.42, -0.42}, {-0.18, -0.42}, {-0.42, 0.08}, {-0.18, 0.08}, {-0.12, 0.01}, {0.26, -0.34}, {0.51, 0.11}, {0.52, -0.35}, {0.71, -0.01}}
local FC = {0.145, -0.155}
local k = 3.4 / cm.Size.Y
face(WANT)
local sz, sx = axes()
local R = cm.CFrame - cm.Position
local function W(bx, by) return R:VectorToWorldSpace(Vector3.new(sx * bx, 0, sz * by) * k) end
local fc = W(FC[1], FC[2])
local best
for dx = -0.6, 0.6, 0.2 do for dz = -0.6, 0.6, 0.2 do
	local c = SPOT + Vector3.new(dx, 0, dz)
	local hi, lo, ok = -1e9, 1e9, true
	for _, f in ipairs(feet) do
		local w = c + W(f[1] - FC[1], f[2] - FC[2])
		local y, inst = ground(w)
		if not y or (inst == workspace.Terrain and y < -52.5) then ok = false break end   -- every fin on the beach, none in the water
		hi = math.max(hi, y) lo = math.min(lo, y)
	end
	if ok then
		local score = (hi - lo) * 10 + math.abs(dx) + math.abs(dz)
		if not best or score < best.s then best = {s = score, c = c, y = hi, spread = hi - lo} end
	end
end end
if not best then return 'QM@ABORT no footing near ' .. tostring(SPOT) end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
log('QM@KEEPER feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'sx', sx, 'sz', sz)
game:GetService('ChangeHistoryService'):SetWaypoint('Lighthouse Keeper placed')

local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('The treasure is still out there."},\n', 1, true)
if not a or rs:find('lighthousekeeper_squirrel', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "lighthousekeeper_squirrel", map = "porto", area = "groves", name = "Lighthouse Keeper Squirrel",\n\t\t bio = "Has kept the light burning for forty years. Carries a lantern anyway, in case the lighthouse forgets."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Lighthouse Keeper registry')
local n = 0 for _ in reg.Source:gmatch('area = "groves"') do n += 1 end
log('QM@REG groves entries', n)
return table.concat(LOG, '\n')
