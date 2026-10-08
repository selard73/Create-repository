-- Oct 7 2026: Chef Nutmeg the Pizza Maker (pizzamaker_squirrel, Meshy "Chef Nutmeg") in front of the Pizzeria della Piazza
-- shopfront (wall x 446), south of its cafe table, facing the square (+x). His flying pizza (workspace.PortoNocciola
-- "Chef Nutmeg's pizza", PizzaToss client script) gets HandLocal/EditSizeY so it follows his raised paw.
-- Registry after Nino (area borgo). Returns its log.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'pizzamaker_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then return 'QP@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local pizza = workspace.PortoNocciola:FindFirstChild("Chef Nutmeg's pizza")
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, pizza, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, -6, p.Z), Vector3.new(0, -12, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(449.2, 0, -776.6)
local WANT = Vector3.new(1, 0, 0)
local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not (Bn.Head and Bn.Tail2) then return 'QP@ABORT bones' end
local rel = cm.CFrame:Inverse() * col:GetPivot() col:PivotTo(CFrame.new(cm.Position) * rel)
local function axes()
	local hl = cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition)
	return hl.Z < 0 and 1 or -1
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
-- feet (feet_probe, model units): L x -0.35..0.00 y -0.73..-0.28, R x 0.52..1.02 y -0.03..0.33
local feet = {{-0.33, -0.70}, {-0.12, -0.40}, {-0.22, -0.58}, {-0.05, -0.60}, {0.55, 0.05}, {0.72, 0.24}, {0.85, 0.00}, {1.00, 0.30}}
local FC = {0.33, -0.23}
local k = 3.4 / cm.Size.Y
face(WANT)
local sz = axes()
local R = cm.CFrame - cm.Position
local fc = R:VectorToWorldSpace(Vector3.new(FC[1], 0, sz * FC[2]) * k)
local best
for dx = -0.3, 0.3, 0.1 do for dz = -0.3, 0.3, 0.1 do
	local c = SPOT + Vector3.new(dx, 0, dz)
	local hi, lo, ok = -1e9, 1e9, true
	for _, f in ipairs(feet) do
		local w = c - fc + R:VectorToWorldSpace(Vector3.new(f[1], 0, sz * f[2]) * k)
		local y = ground(w)
		if not y then ok = false break end
		hi = math.max(hi, y) lo = math.min(lo, y)
	end
	if ok then
		local score = (hi - lo) * 10 + math.abs(dx) + math.abs(dz)
		if not best or score < best.s then best = {s = score, c = c, y = hi, spread = hi - lo} end
	end
end end
if not best then return 'QP@ABORT no ground for Chef Nutmeg' end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
log('QP@CHEF feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)))
-- anything solid in his space (chairs, tables)?
local ov = OverlapParams.new() ov.FilterType = Enum.RaycastFilterType.Exclude ov.FilterDescendantsInstances = {col, pizza, workspace:FindFirstChild('Zones')}
local hits = {}
for _, p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(L + Vector3.new(0, 1.9, 0)), Vector3.new(2.6, 3.4, 2.6), ov)) do
	if p.Transparency < 1 then hits[#hits + 1] = (p.Name .. '<' .. p.Parent.Name):sub(1, 40) end
end
log('QP@CLEAR overlaps:', #hits, table.concat(hits, ', '))
game:GetService('ChangeHistoryService'):SetWaypoint('Chef Nutmeg placed')

-- the paw for the pizza: Blender paw centroid (0.855, -0.072, 2.096), mesh centre (0, 0, 1.2); the import may mirror X/Z,
-- so read the mapping off the Tail2 bone (Blender x < 0, y > 0)
local tl = cm.CFrame:PointToObjectSpace(Bn.Tail2.WorldPosition)
local sx = (tl.X < 0) and 1 or -1
local szz = (tl.Z > 0) and 1 or -1
local hand = Vector3.new(sx * 0.855, 2.096 - 1.2, szz * -0.072)
if pizza then
	pizza:SetAttribute('HandLocal', hand) pizza:SetAttribute('EditSizeY', cm.Size.Y)
	local pw = cm.CFrame:PointToWorldSpace(hand) + Vector3.new(0, 0.55, 0)
	pizza:PivotTo(CFrame.new(pw))
	log('QP@PIZZA hand local', hand, 'tail2 local', tl, 'pizza rest', pw)
else
	log('QP@PIZZA missing')
end
game:GetService('ChangeHistoryService'):SetWaypoint('Pizza follows Chef Nutmeg')

-- registry: after Nino (area borgo)
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('never once heard the end of a song."},\n', 1, true)
if not a or rs:find('pizzamaker_squirrel', 1, true) then log('QP@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "pizzamaker_squirrel",    map = "porto", area = "borgo", name = "Chef Nutmeg",\n\t\t bio = "Spins every pizza over his head before it goes in the oven. Most of them come back down."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Chef Nutmeg registry')
local n = 0 for _ in reg.Source:gmatch('area = "borgo"') do n += 1 end
log('QP@REG borgo entries', n)
return table.concat(LOG, '\n')
