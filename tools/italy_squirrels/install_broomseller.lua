-- Oct 7 2026: Signor Scopa the Broom Seller (broomseller_squirrel, Meshy "Broomtail") on Via della Piazza, in front of
-- the lilac house (door 27 on his right), facing the street; his broom cart (Meshy "Brooms for a Brighter Day", 18k tris)
-- on his left against the wall, sign end to the street, with real lettering on a plate over Meshy's scribbled sign.
-- Registry after the Fat Lady (area borgo). No asserts after the first edit: log + return. Returns its log.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local id = 'broomseller_squirrel'
local col, gry = workspace:FindFirstChild(id .. '_color'), workspace:FindFirstChild(id .. '_gray')
local cartM = workspace:FindFirstChild('broomcart')
if not (col and gry and cartM) then return 'QB@ABORT missing import ' .. tostring(col) .. ' ' .. tostring(gry) .. ' ' .. tostring(cartM) end
local cart = cartM:IsA('BasePart') and cartM or cartM:FindFirstChildWhichIsA('MeshPart', true)
if not cart then return 'QB@ABORT no cart mesh' end

local WANT = Vector3.new(0.96, 0, 0.281).Unit            -- out from the house fronts (the wall runs (0.281,0,-0.96))
local LEFT = Vector3.new(0.281, 0, -0.96).Unit           -- his left = along the wall toward the lilac/blue corner
local Y0 = -10.5
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, gry, cartM, workspace:FindFirstChild('SquirrelTwins'), workspace:FindFirstChild('Zones')}
local function ground(p) local q = workspace:Raycast(Vector3.new(p.X, Y0 + 6, p.Z), Vector3.new(0, -12, 0), rp) return q and q.Position.Y, q and q.Instance end
local function wallAt(p)                                   -- the house front behind point p (horizontal ray toward the wall)
	local q = workspace:Raycast(Vector3.new(p.X, Y0, p.Z) + WANT * 8, -WANT * 20, rp)
	return q and q.Position
end

-- ---------- the squirrel (same placement code as Rocco / Tonio)
local W1 = wallAt(Vector3.new(454.5, 0, -852.5))
if not W1 then return 'QB@ABORT no wall at the lilac house' end
local SPOT = W1 + WANT * 2.4
local cm, gm = col.Squirrel, gry.Squirrel
local Bn = {} for _, x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name] = x end end
if not Bn.Head then return 'QB@ABORT no Head bone' end
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
-- feet (feet_probe, model units): L x -0.36..-0.12 y -0.52..-0.20, heels (0.06,-0.14) (0.27,-0.23), R x 0.39..0.74 y -0.84..-0.26
local feet = {{-0.33, -0.48}, {-0.15, -0.22}, {-0.30, -0.26}, {0.06, -0.14}, {0.27, -0.23}, {0.45, -0.80}, {0.70, -0.70}, {0.45, -0.30}}
local FC = {0.17, -0.40}
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
if not best then return 'QB@ABORT no ground for Signor Scopa' end
local L = Vector3.new(best.c.X, best.y, best.c.Z)
col:PivotTo(col:GetPivot() + Vector3.new(L.X - fc.X - cm.Position.X, L.Y + 0.02 - (cm.Position.Y - cm.Size.Y / 2), L.Z - fc.Z - cm.Position.Z))
cm.RenderFidelity = Enum.RenderFidelity.Precise gm.RenderFidelity = Enum.RenderFidelity.Precise
cm:SetAttribute('ColorTexture', cm.TextureID) cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) end
log('QB@SCOPA feet centre', L, 'spread', best.spread, 'facing', R:VectorToWorldSpace(Vector3.new(0, 0, -sz)), 'wall', W1)
game:GetService('ChangeHistoryService'):SetWaypoint('Signor Scopa placed')

-- ---------- the cart: game scale (3.4 / 2.4 like the squirrels), sign end to the street, handle to the wall
local KC = 3.4 / 2.4
if math.abs(cart.Size.Y - 2.4) < 0.05 then cart.Size = cart.Size * KC end
cart.Anchored = true cart.CanTouch = false cart.CastShadow = true cart.Material = Enum.Material.Plastic
cart.RenderFidelity = Enum.RenderFidelity.Precise
-- which end carries the sign: the box face sits near the mesh's end on the sign side; the handle end is open space
local function endHit(sign)
	local cf = cart.CFrame
	local o = cf:PointToWorldSpace(Vector3.new(sign * (cart.Size.X / 2 + 2), -cart.Size.Y * 0.27, cart.Size.Z * 0.28))
	local only = RaycastParams.new() only.FilterType = Enum.RaycastFilterType.Include only.FilterDescendantsInstances = {cart}
	local q = workspace:Raycast(o, cf:VectorToWorldSpace(Vector3.new(-sign, 0, 0)) * (cart.Size.X + 4), only)
	return q and math.abs(cf:PointToObjectSpace(q.Position).X) or 0
end
local ePlus, eMinus = endHit(1), endHit(-1)
local SIGN = (ePlus >= eMinus) and 1 or -1
log('QB@CART end hits +X', ePlus, '-X', eMinus, 'sign end', SIGN)
-- turn: local SIGN*X -> WANT, upright
local cc = cart.CFrame
cart.CFrame = CFrame.lookAt(cart.Position, cart.Position + WANT) * CFrame.lookAt(Vector3.zero, Vector3.new(SIGN, 0, 0)):Inverse()
-- (lookAt puts local -Z on WANT; the inverse of lookAt(0, SIGN*X) maps local SIGN*X onto that -Z)
local fw = cart.CFrame:VectorToWorldSpace(Vector3.new(SIGN, 0, 0))
log('QB@CART sign dir now', fw, 'up', cart.CFrame.UpVector)
local CP = L + LEFT * 2.9
local W2 = wallAt(CP)
if not W2 then return 'QB@ABORT no wall at the cart' end
local centre = W2 + WANT * (0.2 + cart.Size.X / 2)
local gy = -1e9
for _, o in ipairs({{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}) do
	local y = ground(centre + WANT * o[1] * cart.Size.X * 0.3 + LEFT * o[2] * cart.Size.Z * 0.4)
	if y then gy = math.max(gy, y) end
end
if gy < -100 then return 'QB@ABORT no ground at the cart' end
cart.CFrame = (cart.CFrame - cart.Position) + Vector3.new(centre.X, gy + cart.Size.Y / 2, centre.Z)
cart.CanCollide = true
log('QB@CART at', cart.Position, 'ground', gy, 'wall', W2, 'size', cart.Size)

-- ---------- the sign plate: Meshy's sign spans x 1.16..1.65, y -0.57..0.65, z 0.20..1.11 (model units, 2.4 tall), faces +X tilted 7.5 up
local only = RaycastParams.new() only.FilterType = Enum.RaycastFilterType.Include only.FilterDescendantsInstances = {cart}
local sLocalY = (0.655 * KC) - cart.Size.Y / 2
local hits = {}
for _, zz in ipairs({-0.35, 0, 0.35}) do
	for _, yy in ipairs({-0.25, 0, 0.25}) do
		local o = cart.CFrame:PointToWorldSpace(Vector3.new(SIGN * (cart.Size.X / 2 + 1.5), sLocalY + yy * KC, zz * KC))
		local q = workspace:Raycast(o, -WANT * 4, only)
		if q then hits[#hits + 1] = cart.CFrame:PointToObjectSpace(q.Position).X * SIGN end
	end
end
table.sort(hits)
local faceX = hits[#hits] or (1.62 * KC)                    -- outermost hit = the plate's front
log('QB@SIGN face local x', faceX, 'hits', #hits)
local plate = Instance.new('Part') plate.Name = 'SignPlate'
plate.Size = Vector3.new(0.06, 0.95 * KC, 1.25 * KC)
plate.Anchored = true plate.CanCollide = false plate.CanTouch = false plate.CanQuery = false plate.CastShadow = false
plate.Material = Enum.Material.SmoothPlastic plate.Color = Color3.fromRGB(246, 238, 218)
local tilt = math.rad(7.5) * SIGN
plate.CFrame = cart.CFrame * CFrame.new(SIGN * (faceX + 0.12), sLocalY, 0.04 * KC) * CFrame.Angles(0, 0, tilt)
local sg = Instance.new('SurfaceGui') sg.Name = 'Lettering' sg.Face = (SIGN > 0) and Enum.NormalId.Right or Enum.NormalId.Left
sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 120 sg.LightInfluence = 1 sg.Parent = plate
local bg = Instance.new('Frame') bg.Size = UDim2.fromScale(1, 1) bg.BackgroundColor3 = Color3.fromRGB(246, 238, 218) bg.BorderSizePixel = 0 bg.Parent = sg
local st = Instance.new('UIStroke') st.Color = Color3.fromRGB(112, 74, 42) st.Thickness = 6 st.Parent = bg
local pad = Instance.new('UIPadding') pad.PaddingTop = UDim.new(0.07, 0) pad.PaddingBottom = UDim.new(0.07, 0) pad.PaddingLeft = UDim.new(0.06, 0) pad.PaddingRight = UDim.new(0.06, 0) pad.Parent = bg
local lay = Instance.new('UIListLayout') lay.FillDirection = Enum.FillDirection.Vertical lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
lay.VerticalAlignment = Enum.VerticalAlignment.Center lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Padding = UDim.new(0, 0) lay.Parent = bg
local INK = Color3.fromRGB(46, 34, 28)
local function line(order, text, font, h, colour)
	local t = Instance.new('TextLabel') t.LayoutOrder = order t.BackgroundTransparency = 1 t.Size = UDim2.fromScale(1, h)
	t.Text = text t.TextColor3 = colour or INK t.TextScaled = true t.Font = font t.Parent = bg
	return t
end
local hand = Enum.Font.Kalam
line(1, 'BROOMS', Enum.Font.FredokaOne, 0.32)
line(2, '- for a -', hand, 0.17)
line(3, 'Brighter Day', hand, 0.27)
line(4, '\u{2665}', Enum.Font.GothamBold, 0.14, Color3.fromRGB(214, 48, 48))
plate.Parent = cartM:IsA('Model') and cartM or cart
log('QB@SIGN plate at', plate.Position, 'face', sg.Face)

-- keep the cart under PortoNocciola
local stall = Instance.new('Model') stall.Name = 'Broom cart (Signor Scopa)' stall:SetAttribute('Built', 'Oct 7 2026 Signor Scopa the Broom Seller')
stall.Parent = workspace:FindFirstChild('PortoNocciola') or workspace
if cartM:IsA('Model') then cartM.Name = 'Broom cart' cartM.Parent = stall else cart.Parent = stall plate.Parent = stall end
game:GetService('ChangeHistoryService'):SetWaypoint('Broom cart + sign')

-- ---------- registry: after the Fat Lady (area borgo)
local reg = workspace.SquirrelScripts.SquirrelRegistry
local rs = reg.Source
local a, b = rs:find('The problem is, she never stops."},\n', 1, true)
if not a or rs:find('broomseller_squirrel', 1, true) then log('QB@REG_SKIP anchor/dup', a) return table.concat(LOG, '\n') end
local add = '\t\t{id = "broomseller_squirrel",   map = "porto", area = "borgo", name = "Signor Scopa",\n\t\t bio = "Every broom comes with a free demonstration. So does your doorstep, whether you asked or not."},\n'
reg.Source = rs:sub(1, b) .. add .. rs:sub(b + 1)
game:GetService('ChangeHistoryService'):SetWaypoint('Signor Scopa registry')
local n = 0 for _ in reg.Source:gmatch('area = "borgo"') do n += 1 end
log('QB@REG borgo entries', n)
return table.concat(LOG, '\n')
