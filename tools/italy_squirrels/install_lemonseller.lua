-- Oct 7 2026 (night): Lemon Seller Squirrel (lemonseller_squirrel), The Groves 1 of 15. Her pick: spot A = the top terrace of
-- "Lemon and olive terraces", beside the crate of lemons (711.99,60.7,-790) at the top of the Salita degli Ulivi stairs (stair exit
-- ~700,60,-781), facing the stairs; the olive tree (715.6,-799.6) is behind him (bio 1). Brings his two models back from
-- ServerStorage.LemonSellerPending, registry after the Postcard Squirrel (area groves), and splits porto_borgo so the terraces
-- (x 617..800.5, z -949..-756) are a Groves zone. Returns its log.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'lemonseller_squirrel'
local pend = game.ServerStorage:FindFirstChild('LemonSellerPending')
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
if pend and not col then
	col, gry = pend:FindFirstChild(id .. '_color'), pend:FindFirstChild(id .. '_gray')
	if not (col and gry) then return 'QM@ABORT missing parked models ' .. tostring(col) .. ' ' .. tostring(gry) end
	col.Parent = workspace gry.Parent = workspace
end
if not (col and gry) then return 'QM@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, 75, p.Z), Vector3.new(0, -25, 0), rp) return q and q.Position.Y, q and q.Instance end
local SPOT = Vector3.new(709.3, 0, -789.8)             -- just west of the crate (x 710.7..713.3, z -790.85..-789.15)
local WANT = Vector3.new(-0.69, 0, 0.73)               -- toward the stair exit
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
-- feet (feet_probe, model units): L x -0.60..-0.35 y -0.23..0.08 (+ -0.33,-0.08), R x 0.16..0.50 y -0.60..-0.09
local feet = {{-0.60, -0.23}, {-0.35, -0.23}, {-0.60, 0.08}, {-0.35, 0.08}, {-0.33, -0.08}, {0.16, -0.60}, {0.50, -0.60}, {0.16, -0.09}, {0.50, -0.09}}
local FC = {-0.07, -0.21}
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
if not best then return 'QM@ABORT no ground for the lemon seller' end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
if pend and #pend:GetChildren() == 0 then pend:Destroy() end
log('QM@LEMON feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)))
game:GetService('ChangeHistoryService'):SetWaypoint('Lemon Seller placed')

-- zones: porto_borgo (x 355.5..800.5, z -1000..-540) -> west part + north/south strips; the terraces become porto_groves_terraces
local Z = workspace.Zones
local borgo = Z:FindFirstChild('porto_borgo')
if borgo and not Z:FindFirstChild('porto_groves_terraces') then
	local X0, X1, XS = 355.5, 800.5, 617
	local function rect(p, x0, x1, z0, z1) p.Size = Vector3.new(x1 - x0, borgo.Size.Y, z1 - z0) p.Position = Vector3.new((x0 + x1) / 2, borgo.Position.Y, (z0 + z1) / 2) end
	local north, south, terr = borgo:Clone(), borgo:Clone(), borgo:Clone()
	rect(borgo, X0, XS, -1000, -540)
	north.Name = 'porto_borgo_north' rect(north, XS, X1, -756, -540) north.Parent = Z
	south.Name = 'porto_borgo_south' rect(south, XS, X1, -1000, -949) south.Parent = Z
	terr.Name = 'porto_groves_terraces' terr:SetAttribute('Area', 'groves') rect(terr, XS, X1, -949, -756) terr.Parent = Z
	for _, p in ipairs({borgo, north, south, terr}) do log('QM@ZONE', p.Name, p:GetAttribute('Area'), p.Position, p.Size) end
	game:GetService('ChangeHistoryService'):SetWaypoint('Groves terraces zone')
else
	log('QM@ZONE_SKIP', borgo, Z:FindFirstChild('porto_groves_terraces'))
end

-- registry: after the Postcard Squirrel (area groves)
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('Business is excellent."},\n', 1, true)
if not a or rs:find('lemonseller_squirrel', 1, true) then log('QM@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "lemonseller_squirrel",   map = "porto", area = "groves", name = "Lemon Seller Squirrel",\n\t\t bio = "Swears every lemon in his basket came off the tree behind him. The tree behind him is an olive tree."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Lemon Seller registry')
local n = 0 for _ in reg.Source:gmatch('area = "groves"') do n += 1 end
log('QM@REG groves entries', n)
return table.concat(LOG, '\n')
