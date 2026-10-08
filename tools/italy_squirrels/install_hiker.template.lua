-- Oct 7 2026 (night): Hiker Squirrel (hiker_squirrel), The Groves 4 of 15. Spot (proposed): the grass corner where the tower path
-- (Watchtower approach, paving top y 12) leaves the main "Upper town to meadow" path at its landing (551,-996), just south of
-- the borgo/groves line z -1000, facing the junction. Facing from the TAIL. Registry after the Snorkel Squirrel.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'hiker_squirrel'
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
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, 30, p.Z), Vector3.new(0, -40, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(559, 0, -1001.6)
local WANT = Vector3.new(-0.68, 0, 0.73)  -- toward the junction (landing 551,-996)
-- fins (feet_probe group centres, model units): wide flippers, toes forward (y < 0)
local feet = {{-0.85, -0.21}, {-0.72, -0.04}, {-0.61, 0.15}, {-0.35, -0.17}, {-0.28, 0.21}, {-0.08, -0.59}, {0.06, -0.25}, {0.17, -0.04}, {0.34, -0.64}, {0.35, -0.13}}
local FC = {-0.25, -0.2}
local k = 3.4 / cm.Size.Y
face(WANT)
local sz, sx = axes()
local R = cm.CFrame - cm.Position
local function W(bx, by) return R:VectorToWorldSpace(Vector3.new(sx * bx, 0, sz * by) * k) end
local fc = W(FC[1], FC[2])
local best
for dx = -0.4, 0.4, 0.2 do for dz = -0.4, 0.2, 0.2 do
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
log('QM@HIKER feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'sx', sx, 'sz', sz)
game:GetService('ChangeHistoryService'):SetWaypoint('Hiker Squirrel placed')

local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('named all of them Gerald."},\n', 1, true)
if not a or rs:find('hiker_squirrel', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "hiker_squirrel",         map = "porto", area = "groves", name = "Hiker Squirrel",\n\t\t bio = "%BIO%"},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Hiker Squirrel registry')
local n = 0 for _ in reg.Source:gmatch('area = "groves"') do n += 1 end
log('QM@REG groves entries', n)
return table.concat(LOG, '\n')
