-- Oct 7 2026 (night): Photographer Squirrel (photographer_squirrel, Meshy "Shuttertail"), The Groves 10 of 15. Her pick: on the
-- meadow, shooting the lighthouse: top of the grassy rise north of the Faro (y 2.0), facing south at the door (520,-1168.9) and
-- the Lighthouse Keeper (523.8,-1166.6) ~20 studs away. NoHeadAnim = true on the colour model (his camera is at his eye; a head
-- turn tears it - the game's existing switch, as on the baker / parachute squirrel). Facing from the TAIL. Registry after the Wife.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'photographer_squirrel'
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
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, 6.0, p.Z), Vector3.new(0, -12, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(525.5, 0, -1148)
local WANT = Vector3.new(-0.1, 0, -0.995)  -- WNW, toward people coming up the path
-- feet (feet_probe, model units)
local feet = {{-0.65, -0.53}, {-0.40, -0.14}, {-0.29, -0.28}, {-0.04, 0.0}, {0.40, -0.50}, {0.64, 0.03}, {0.90, -0.02}, {0.96, -0.43}, {0.75, -0.58}}
local FC = {0.155, -0.275}
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
col:SetAttribute('NoHeadAnim', true)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
log('QM@PHOTO feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'sx', sx, 'sz', sz)
game:GetService('ChangeHistoryService'):SetWaypoint('Photographer placed')

local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('There is a lot of laundry."},\n', 1, true)
if not a or rs:find('photographer_squirrel', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "photographer_squirrel",  map = "porto", area = "groves", name = "Photographer Squirrel",\n\t\t bio = "Always says one more. It is never one more."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Photographer registry')
local n = 0 for _ in reg.Source:gmatch('area = "groves"') do n += 1 end
log('QM@REG groves entries', n)
return table.concat(LOG, '\n')
