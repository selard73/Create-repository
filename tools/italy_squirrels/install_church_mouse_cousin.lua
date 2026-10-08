-- Oct 7 2026: The Church Mouse's Cousin (church_mouse_cousin, Meshy "Pious Little Mouse" - an actual mouse) in front of the
-- Chiesa di Santa Marina doors (timber doors centre 404.0,-12,-964.5, facing -z onto the forecourt), a little to one side,
-- facing the forecourt. Registry after Chef Nutmeg (area borgo). Returns its log.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'church_mouse_cousin'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then return 'QM@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, -6, p.Z), Vector3.new(0, -12, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(400.4, 0, -967.2)            -- just left of the doors (seen from the forecourt) and 2.7 in front of them
local WANT = Vector3.new(0, 0, -1)                     -- out onto the forecourt
local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not Bn.Head then return 'QM@ABORT no Head bone' end
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
-- feet (feet_probe, model units): x -0.45..-0.21 y -0.35..-0.03, -0.20..0.05, 0.05..0.30, 0.30..0.46 y -0.30..-0.03
local feet = {{-0.42, -0.30}, {-0.25, -0.10}, {-0.10, 0.00}, {0.15, -0.05}, {0.32, -0.25}, {0.44, -0.10}}
local FC = {0.02, -0.12}
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
if not best then return 'QM@ABORT no ground for the mouse' end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
log('QM@MOUSE feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)))
game:GetService('ChangeHistoryService'):SetWaypoint("The Church Mouse's Cousin placed")

-- registry: after Chef Nutmeg (area borgo)
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('Most of them come back down."},\n', 1, true)
if not a or rs:find('church_mouse_cousin', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "church_mouse_cousin",    map = "porto", area = "borgo", name = "The Church Mouse\'s Cousin",\n\t\t bio = "Quiet as a church mouse. No one has had the heart to tell him he isn\'t a squirrel."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Church Mouse Cousin registry')
local n = 0 for _ in reg.Source:gmatch('area = "borgo"') do n += 1 end
log('QM@REG borgo entries', n)
return table.concat(LOG, '\n')
