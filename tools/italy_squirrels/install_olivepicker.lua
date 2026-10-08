-- Oct 7 2026 (night): Olive Picker Squirrel (olivepicker_squirrel), The Groves 2 of 15. Her pick: in the olive grove, standing on
-- a crate (her "stand on a crate") under the small Silver olive tree nearest the path (trunk 560.49,-1036.36), his raised LEFT
-- paw up at the tree's own olive pair south of the trunk ((560.46|561.82), 7.29, -1039.90), facing west toward the path.
-- Crate = a copy of the terraces' "Orchard produce crate" (2.6 x 1.4 x 1.7 WoodPlanks) stood on its side (1.7 high) so his fist
-- (model z 2.274 -> 3.22 studs in play) reaches the olives' underside (7.10). Registry after the Lemon Seller (area groves).
-- NOTE (after the run): his head bone sits almost straight over the body (local Z +0.08), so the head-based sz came out -1
-- and he faces EAST (into the grove, toward the lighthouse road), back to the grove path. She saw it: "that looks great".
-- For an upright head, take the facing from the tail instead (Tail2 local Z > 0 = behind). The paw/crate maths only
-- depends on sx, so the fist still sits under the olive pair. Placed: feet (561.09, 3.70, -1038.72), crate top 3.7.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'olivepicker_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if not (col and gry) then return 'QM@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not (Bn.Head and Bn.Tail2) then return 'QM@ABORT no Head/Tail2 bone' end
local rel = cm.CFrame:Inverse() * col:GetPivot() col:PivotTo(CFrame.new(cm.Position) * rel)
local function axes()
	local hl = cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition)
	local tl = cm.CFrame:PointToObjectSpace(Bn.Tail2.WorldPosition)
	return hl.Z < 0 and 1 or -1, tl.X < 0 and 1 or -1        -- sx: Blender's tail is at -x; +1 = local X follows Blender x
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
local WANT = Vector3.new(-1, 0, 0)                     -- west, toward the grove path
local FC = {0.11, 0.07}                                -- feet centre (feet_probe): L x -0.57..-0.26 y -0.17..0.18, R x 0.29..0.79 y -0.13..0.32
local PAW = {0.945, 0.104, 2.274}                      -- raised fist's top (paw_tip_probe)
local OLIVE = Vector3.new(561.14, 7.10, -1039.90)      -- underside of the olive pair
local k = 3.4 / cm.Size.Y
face(WANT)
local sz, sx = axes()
local R = cm.CFrame - cm.Position
local function W(bx, by) return R:VectorToWorldSpace(Vector3.new(sx * bx, 0, sz * by) * k) end
local pawOff = W(PAW[1] - FC[1], PAW[2] - FC[2])       -- feet centre -> fist, horizontal, game size
local C = Vector3.new(OLIVE.X - pawOff.X, 0, OLIVE.Z - pawOff.Z)
-- the crate: copy of the terraces' crate, long side across him, stood on its side (its 1.7 edge up)
local src
for _, d in ipairs(workspace.PortoNocciola['13 Hillside town']['Lemon and olive terraces']:GetChildren()) do
	if d.Name == 'Orchard produce crate' then src = d break end
end
if not src then return 'QM@ABORT no crate to copy' end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
local right = R:VectorToWorldSpace(Vector3.new(sx, 0, 0)) * Vector3.new(1, 0, 1)
right = right.Unit
local fwd = Vector3.new(-right.Z, 0, right.X)         -- horizontal, perpendicular
local gy = -1e9
for _, a in ipairs({-1.3, 0, 1.3}) do for _, b in ipairs({-0.7, 0, 0.7}) do
	local p = C + right * a + fwd * b
	local q = workspace:Raycast(Vector3.new(p.X, 25, p.Z), Vector3.new(0, -40, 0), rp)
	if not q then return 'QM@ABORT no ground under the crate at ' .. tostring(p) end
	gy = math.max(gy, q.Position.Y)
end end
local holder = Instance.new('Model') holder.Name = "Olive Picker's crate"
local crate = src:Clone() crate.Name = 'Upturned olive crate'
crate.Anchored = true crate.CanCollide = true crate.CanQuery = true crate.CanTouch = false
-- X = his left-right (2.6), then turn 90 deg about X so the 1.7 edge stands up and the 1.4 edge runs front-back
crate.CFrame = CFrame.fromMatrix(Vector3.new(C.X, gy + 0.85, C.Z), right, Vector3.yAxis) * CFrame.Angles(math.rad(90), 0, 0)
crate.Parent = holder holder.Parent = workspace.PortoNocciola
local top = gy + 1.7
-- feet centre onto the crate top
local fc = W(FC[1], FC[2])
col:PivotTo(col:GetPivot() + Vector3.new(C.X - fc.X - cm.Position.X, top + 0.02 - (cm.Position.Y - cm.Size.Y / 2), C.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
local fist = C + pawOff + Vector3.new(0, top + PAW[3] * k, 0)
log('QM@OLIVE feet centre', Vector3.new(C.X, top, C.Z), 'crate ground', gy, 'top', top, 'sx', sx, 'sz', sz)
log('QM@OLIVE facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'fist in play', fist, 'olive underside', OLIVE)
log('QM@OLIVE crate size', crate.Size, 'up extent', (crate.CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1))))
game:GetService('ChangeHistoryService'):SetWaypoint('Olive Picker placed')

-- registry: after the Lemon Seller (area groves)
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('The tree behind him is an olive tree."},\n', 1, true)
if not a or rs:find('olivepicker_squirrel', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "olivepicker_squirrel",   map = "porto", area = "groves", name = "Olive Picker Squirrel",\n\t\t bio = "Picks one olive for the basket and one for himself. The basket is still empty."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Olive Picker registry')
local n = 0 for _ in reg.Source:gmatch('area = "groves"') do n += 1 end
log('QM@REG groves entries', n)
return table.concat(LOG, '\n')
