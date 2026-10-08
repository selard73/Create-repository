-- Oct 7 2026 (Shannon: "your original pizza looks really really good ... put some version of that on one of the tables
-- with slices and plates"): Pizzeria table 1 (marble top dia 3.7, surface y -8.85, centre 452.2,-770.5; espresso cup at
-- +0.55 x; chairs north/south). A pizza on a round wooden board toward the shop (x 451.6), two neighbouring 45-degree
-- slices cut out with CSG (the gap faces the plates) and served one on each of two white plates in front of the chairs.
-- Returns its log.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local seating = workspace.PortoNocciola:FindFirstChild('Usable village seating', true)
local tbl = seating and seating:FindFirstChild('Pizzeria table 1')
if not tbl then return 'ABORT no Pizzeria table 1' end
if tbl:FindFirstChild('Table pizza') then return 'already built' end
local top
for _, p in ipairs(tbl:GetDescendants()) do if p.Name == 'Marble cafe tabletop' then top = p end end
if not top then return 'ABORT no tabletop' end
local SURF = top.Position.Y + top.Size.X / 2          -- the top is a cylinder lying flat: its thickness is Size.X
local TC = top.Position
local C = Color3.fromRGB
local holder = Instance.new('Model') holder.Name = 'Table pizza'
holder:SetAttribute('Built', 'Oct 7 2026 pizza with two slices on plates (Shannon)')
local UP = CFrame.Angles(0, 0, math.pi / 2)           -- cylinder axis (X) -> up
local function prop(p)
	p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end
local function disc(name, dia, thick, centre, col, mat)
	local p = prop(Instance.new('Part')) p.Name = name p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(thick, dia, dia) p.CFrame = CFrame.new(centre) * UP
	p.Color = col p.Material = mat or Enum.Material.SmoothPlastic
	return p
end
-- board and pizza
local PC = Vector3.new(TC.X - 0.6, 0, TC.Z)           -- pizza centre (x 451.6): clear of the espresso saucer
local board = disc('Pizza board', 1.72, 0.06, Vector3.new(PC.X, SURF + 0.03, PC.Z), C(176, 122, 74), Enum.Material.Wood)
board.Parent = holder
local B0 = SURF + 0.06                                 -- pizza sits on the board
local layers = {
	{name = 'Crust',  dia = 1.52, bot = 0,     th = 0.08,  col = C(222, 170, 98)},
	{name = 'Sauce',  dia = 1.34, bot = 0.005, th = 0.085, col = C(192, 46, 32)},
	{name = 'Cheese', dia = 1.20, bot = 0.01,  th = 0.09,  col = C(250, 222, 132)},
}
-- sector solids: the half-space beside the radial line at angle a (degrees, 0 = +x toward the plates)
local function half(a, side)                           -- side +1: the increasing-angle side, -1: the other
	local r = math.rad(a)
	local rv = Vector3.new(math.cos(r), 0, math.sin(r))
	local tv = Vector3.new(-math.sin(r), 0, math.cos(r)) -- = rv x up
	local b = prop(Instance.new('Part')) b.Size = Vector3.new(8, 2, 4)
	b.CFrame = CFrame.fromMatrix(Vector3.new(PC.X, B0, PC.Z) + tv * 2 * side, rv, Vector3.yAxis)
	b.Parent = workspace
	return b
end
local function sector(a0, a1)
	local A, B = half(a0, 1), half(a1, -1)
	local ok, s = pcall(function() return A:IntersectAsync({B}) end)
	A:Destroy() B:Destroy()
	if not ok then error('sector ' .. tostring(s)) end
	return s
end
local gap = sector(-45, 45)
local s1, s2 = sector(-45, 0), sector(0, 45)
local rest, sl1, sl2 = {}, {}, {}
for _, L in ipairs(layers) do
	local p = disc(L.name, L.dia, L.th, Vector3.new(PC.X, B0 + L.bot + L.th / 2, PC.Z), L.col)
	p.Parent = workspace
	local ok1, r = pcall(function() return p:SubtractAsync({gap}) end)
	local ok2, a = pcall(function() return p:IntersectAsync({s1}) end)
	local ok3, b = pcall(function() return p:IntersectAsync({s2}) end)
	p:Destroy()
	if not (ok1 and ok2 and ok3) then gap:Destroy() s1:Destroy() s2:Destroy() holder:Destroy() return 'ABORT csg ' .. L.name .. ' ' .. tostring(r) .. tostring(a) .. tostring(b) end
	for _, u in ipairs({r, a, b}) do
		prop(u) u.UsePartColor = true u.Color = L.col u.Material = Enum.Material.SmoothPlastic
		u.CollisionFidelity = Enum.CollisionFidelity.Box u.RenderFidelity = Enum.RenderFidelity.Precise
	end
	r.Name = L.name a.Name = 'Slice ' .. L.name b.Name = 'Slice ' .. L.name
	table.insert(rest, r) table.insert(sl1, a) table.insert(sl2, b)
end
gap:Destroy() s1:Destroy() s2:Destroy()
local pizza = Instance.new('Model') pizza.Name = 'Pizza' pizza.Parent = holder
for _, u in ipairs(rest) do u.Parent = pizza end
local TOPY = B0 + 0.1                                  -- cheese top
local function pep(parent, x, z)
	local p = disc('Pepperoni', 0.22, 0.025, Vector3.new(x, TOPY + 0.0125, z), C(170, 40, 32)) p.Parent = parent
end
local function leaf(parent, x, z, yaw)
	local p = prop(Instance.new('Part')) p.Name = 'Basil' p.Size = Vector3.new(0.17, 0.02, 0.1)
	p.CFrame = CFrame.new(x, TOPY + 0.01, z) * CFrame.Angles(0, math.rad(yaw), 0) p.Color = C(52, 128, 58) p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
end
local function at(r, deg) local a = math.rad(deg) return PC.X + math.cos(a) * r, PC.Z + math.sin(a) * r end
for _, d in ipairs({{0.4, 100}, {0.4, 150}, {0.4, 200}, {0.4, 250}, {0.4, 300}, {0.16, 180}}) do pep(pizza, at(d[1], d[2])) end
for _, d in ipairs({{0.26, 125, 20}, {0.3, 225, 80}, {0.24, 280, 140}}) do local x, z = at(d[1], d[2]) leaf(pizza, x, z, d[3]) end
-- the two slices, each with a pepperoni and a basil leaf, moved onto the plates
local plates = {Vector3.new(TC.X + 0.45, 0, TC.Z - 1.15), Vector3.new(TC.X + 0.45, 0, TC.Z + 1.15)}
local function plate(i, centre)
	local base = disc('Plate', 0.95, 0.03, Vector3.new(centre.X, SURF + 0.015, centre.Z), C(250, 250, 248))
	local ringO = disc('r', 0.95, 0.06, Vector3.new(centre.X, SURF + 0.03, centre.Z), C(250, 250, 248))
	local ringI = disc('r', 0.78, 0.2, Vector3.new(centre.X, SURF + 0.03, centre.Z), C(250, 250, 248))
	ringO.Parent = workspace ringI.Parent = workspace
	local ok, ring = pcall(function() return ringO:SubtractAsync({ringI}) end)
	ringO:Destroy() ringI:Destroy()
	local m = Instance.new('Model') m.Name = 'Plate ' .. i m.Parent = holder
	base.Parent = m
	if ok then prop(ring) ring.Name = 'Plate rim' ring.UsePartColor = true ring.Color = C(236, 236, 232) ring.Material = Enum.Material.SmoothPlastic ring.Parent = m end
	return m
end
for i, sl in ipairs({sl1, sl2}) do
	local m = Instance.new('Model') m.Name = 'Slice ' .. i
	for _, u in ipairs(sl) do u.Parent = m end
	local mid = (i == 1) and -22.5 or 22.5
	pep(m, at(0.48, mid)) local lx, lz = at(0.3, mid + 6) leaf(m, lx, lz, 60 * i)
	local pm = plate(i, plates[i])
	m.Parent = pm
	local cf, sz = m:GetBoundingBox()
	local dest = Vector3.new(plates[i].X, SURF + 0.03 + (cf.Position.Y - (B0)), plates[i].Z)   -- slice bottom onto the plate top
	m:PivotTo(m:GetPivot() + (dest - cf.Position) + Vector3.new(0, 0, 0))
	local cf2 = m:GetBoundingBox()
	log('slice', i, 'on plate at', plates[i], 'slice centre', cf2.Position)
end
holder.Parent = tbl
game:GetService('ChangeHistoryService'):SetWaypoint('Table pizza with two slices on plates')
log('built: pizza parts', #pizza:GetChildren(), 'surface', SURF, 'pizza centre', PC)
return table.concat(LOG, '\n')
