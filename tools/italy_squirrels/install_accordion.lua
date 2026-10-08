-- Oct 7 2026: Nino the Accordion Player (accordion_squirrel, Meshy "Accordion Squirrel", furry 9:40 picture) beside the
-- Fat Lady (operasinger at 443.24,-791.16, wall 1.2 behind her on +z) in Piazza del Limone: on her left (west), back to the
-- same wall, facing the square and turned a little toward her. Registry after Signor Scopa (area borgo). Returns its log.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'accordion_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then return 'QA@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local op = workspace:FindFirstChild('operasinger_squirrel_color')
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, -6, p.Z), Vector3.new(0, -12, 0), rp) return q and q.Position.Y, q and q.Instance end
-- the wall behind the Fat Lady: ray toward +z from 4 west of her
local probe = Vector3.new(443.24 - 3.9, -10.5, -795)
local wq = workspace:Raycast(probe, Vector3.new(0, 0, 10), rp)
if not wq then return 'QA@ABORT no wall west of the Fat Lady' end
local SPOT = Vector3.new(probe.X, 0, wq.Position.Z - 2.0)
local WANT = Vector3.new(0.4, 0, -0.92).Unit                 -- out to the square, turned a little toward her (east)

local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not Bn.Head then return 'QA@ABORT no Head bone' end
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
-- feet (feet_probe, model units): L x -0.62..-0.37 y -0.39..-0.13 (+ -0.35,-0.22), R x 0.48..0.77 y -0.13..0.12
local feet = {{-0.60, -0.36}, {-0.40, -0.16}, {-0.50, -0.28}, {-0.35, -0.22}, {0.50, -0.10}, {0.70, 0.10}, {0.74, -0.04}, {0.55, 0.08}}
local FC = {0.06, -0.14}
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
if not best then return 'QA@ABORT no ground for Nino' end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
local gapToHer = op and ((op.Squirrel.Position - L) * Vector3.new(1, 0, 1)).Magnitude
log('QA@NINO feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'wall z', wq.Position.Z, 'to Fat Lady', gapToHer)
game:GetService('ChangeHistoryService'):SetWaypoint('Nino the Accordion Player placed')

-- registry: after Signor Scopa (area borgo)
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('whether you asked or not."},\n', 1, true)
if not a or rs:find('accordion_squirrel', 1, true) then log('QA@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "accordion_squirrel",     map = "porto", area = "borgo", name = "Nino the Accordion Player",\n\t\t bio = "Has played for the Fat Lady for thirty years. He has never once heard the end of a song."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Nino registry')
local n = 0 for _ in reg.Source:gmatch('area = "borgo"') do n += 1 end
log('QA@REG borgo entries', n)
return table.concat(LOG, '\n')
