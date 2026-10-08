"""Village builder fix 1 (Sep 16, Shannon's list): river down to ground level, bridge ends flush with the cobbles,
pavement extended to the east bank, bikes parked on kickstands, chalkboards with a written menu, cafe tables dressed
(table_setting kit) with sit-able seats, fountain spray. No change touches the rng order, so the approved colours stay.
Run: python patch_builder_fix1.py   (then python make_village_scripts.py)"""
import re, shutil
from pathlib import Path

D = Path(__file__).parent
p = D / "make_village_scripts.py"
shutil.copy2(p, D / "make_village_scripts.before_fix1.py")
s = p.read_text(encoding="utf-8")
n0 = len(s)


def rep(old, new, count=1):
    global s
    assert s.count(old) == count, ("expected %d of %r, found %d" % (count, old[:70], s.count(old)))
    s = s.replace(old, new)


# kit list + fixed colour keys for the table settings (no rng use)
rep('''	"basket_flowers", "basket_bread", "basket_mixed"}''',
    '''	"basket_flowers", "basket_bread", "basket_mixed", "table_setting"}''')
rep('''Cross = C(150, 190, 160), Band = C(210, 205, 195), Yellow = C(225, 215, 170)}''',
    '''Cross = C(150, 190, 160), Band = C(210, 205, 195), Yellow = C(225, 215, 170),
	Cloth = C(232, 230, 226), Plate = C(240, 240, 238), Cup = C(240, 240, 238), Napkin = C(200, 190, 190), Rose = C(215, 200, 205), Cutlery = C(190, 190, 195)}''')
rep('''Cross = C(40, 205, 95), Band = C(245, 235, 210), Yellow = C(245, 200, 40)}''',
    '''Cross = C(40, 205, 95), Band = C(245, 235, 210), Yellow = C(245, 200, 40),
	Cloth = C(250, 248, 244), Plate = C(252, 252, 250), Cup = C(252, 252, 250), Napkin = C(196, 58, 58), Rose = C(228, 88, 118), Cutlery = C(182, 184, 192)}''')

# pavement extended 5 studs west so it meets the east river bank (no bare grass under the bridge's village end)
rep('''local STREET_W, WALK_W = 22, 9''', '''local STREET_W, WALK_W = 22, 9
local QUAY = 5                     -- the pavement runs this far past the row toward the river and meets the east bank''')
for nm in ("Street", "SidewalkN", "SidewalkS", "PlotN", "PlotS"):
    pat = re.compile(r'slab\("%s", CX, (CZ[^,]*), LEN, ' % nm)
    assert len(pat.findall(s)) == 1, nm
    s = pat.sub(lambda m: 'slab("%s", CX - QUAY / 2, %s, LEN + QUAY, ' % (nm, m.group(1)), s)

# river: its hidden underside belongs below the grass (bank tops 0.25, water 0.15), not 0.75 up in the air
rep('''GY + 0.05 - (bb.Position.Y - size.Y / 2), CZ - bb.Position.Z))''',
    '''GY - 0.45 - (bb.Position.Y - size.Y / 2), CZ - bb.Position.Z))''')
# bridge: deck-end tops flush with the cobbles (0.30); the open ends and underside disappear into the ground
rep('''	if kitName == "bridge" then model:PivotTo(model:GetPivot() + Vector3.new(0, 0.25, 0)) end''',
    '''	if kitName == "bridge" then model:PivotTo(model:GetPivot() + Vector3.new(0, -0.20, 0)) end   -- deck-end tops meet the cobbles''')

HELPERS = r'''-- a parked bike leans 9 degrees toward the shop side on a kickstand (the whole model tilts about the wheels' contact line)
local function parkBike(bike, dz)
	local bb, size = bike:GetBoundingBox()
	local s = bike:GetScale()
	local P0 = Vector3.new(bb.Position.X, bb.Position.Y - size.Y / 2, bb.Position.Z)
	local top = P0 + Vector3.new(0, 0.78 * s, 0)
	local foot = P0 + Vector3.new(0.1 * s, 0.1 * s, dz * 0.55 * s)
	local ks = Instance.new("Part"); ks.Name = "Kickstand"; ks.Anchored = true; ks.CanCollide = false; ks.CanQuery = false; ks.Locked = true
	ks.Material = Enum.Material.SmoothPlastic; ks.Color = PALETTE == "color" and C(50, 50, 50) or C(60, 60, 60)
	ks.Size = Vector3.new(0.1 * s, 0.1 * s, (foot - top).Magnitude)
	ks.CFrame = CFrame.lookAt((top + foot) / 2, foot)
	ks.Parent = bike
	local R = CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, math.rad(9) * dz) * CFrame.new(-P0)
	bike:PivotTo(R * bike:GetPivot())
end

-- chalkboard: the placeholder chalk squiggles become a written menu on each outer face
local MENUS = {
	"MENU DU JOUR\n\nSoupe à l'oignon ........ 5€\nCroque-monsieur ....... 6€\nQuiche lorraine ......... 5€\nSalade niçoise ........... 7€\nTarte aux noisettes ... 4€",
	"BOISSONS\n\nCafé crème ................ 2€\nChocolat chaud .......... 3€\nCitron pressé ............. 3€\nJus de pomme ........ 2€50\nCroissant .................. 1€50",
}
local function menuBoard(cb)
	local post = cb:FindFirstChild("Post", true)
	if not post then return end
	for _, p in ipairs(cb:GetDescendants()) do if p:IsA("BasePart") and p.Name == "Trim" then p:Destroy() end end
	local s = cb:GetScale()
	for i, sgn in ipairs({-1, 1}) do
		local out = post.CFrame.LookVector * sgn
		local n = (out * 0.978 + Vector3.yAxis * 0.204).Unit               -- the boards lean 12 degrees, so the faces tilt up
		local c = post.Position + Vector3.new(0, -1.795 * s, 0) + out * (0.453 * s) + n * 0.03
		local part = Instance.new("Part"); part.Name = "MenuText"; part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.Locked = true
		part.Transparency = 1; part.Size = Vector3.new(1.9 * s, 2.6 * s, 0.04)
		part.CFrame = CFrame.lookAt(c, c + n)
		part.Parent = cb
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.LightInfluence = 0; gui.Brightness = 1.2
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 60; gui.Parent = part
		local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.fromScale(0.92, 0.92); lbl.Position = UDim2.fromScale(0.04, 0.04); lbl.BackgroundTransparency = 1
		lbl.FontFace = Font.new("rbxasset://fonts/families/PatrickHand.json"); lbl.TextColor3 = C(246, 240, 226)
		lbl.TextScaled = true; lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.Text = MENUS[i]; lbl.Parent = gui
	end
end

-- a cafe table with its setting (cloth, vase, plates; the kit's y = 0 is 0.6 below the table top) and two invisible
-- Seats over the chairs, facing the table, so players can sit (touch) and stand up (jump)
local function cafeTable(x, z, yaw)
	local tbl = place("cafe_table", x, z, yaw, 1, {"UnderTable"})
	local gy = groundAt(x, z)
	local st = place("table_setting", x, z, yaw, 1, {}, true, nil, nil, gy + 2.3 - 0.6)
	if st then for _, p in ipairs(st:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
	if tbl then
		for _, sgn in ipairs({-1, 1}) do
			local off = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(Vector3.new(0, 0, sgn * 2.1))
			local pos = Vector3.new(x, gy + 1.375, z) + off
			local seat = Instance.new("Seat"); seat.Name = "ChairSeat"; seat.Anchored = true; seat.CanCollide = true; seat.CanQuery = false
			seat.Transparency = 1; seat.Locked = true; seat.Size = Vector3.new(1.3, 0.2, 1.3)
			seat.CFrame = CFrame.lookAt(pos, Vector3.new(x, pos.Y, z))
			seat.Parent = tbl
		end
	end
end

-- fountain: a water jet from the top of the column that arcs back down into the bowls
local function fountainSpray(model)
	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	local bb, size = model:GetBoundingBox()
	if not base then return model end
	local a = Instance.new("Attachment"); a.Name = "Spout"
	a.Parent = base
	a.WorldCFrame = CFrame.new(bb.Position.X, bb.Position.Y + size.Y / 2 - 0.15, bb.Position.Z)
	local pe = Instance.new("ParticleEmitter"); pe.Name = "Jet"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(C(205, 236, 255), C(240, 250, 255))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 1.3)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.45), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(1.0, 1.3); pe.Rate = 45; pe.Speed = NumberRange.new(15, 18)
	pe.SpreadAngle = Vector2.new(9, 9); pe.Acceleration = Vector3.new(0, -38, 0)
	pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.25; pe.LightInfluence = 0.6
	pe.Parent = a
	return model
end

-- 1. shop-houses along both sides (north row faces -Z toward the street; south row is turned around)'''
rep('''-- 1. shop-houses along both sides (north row faces -Z toward the street; south row is turned around)''', HELPERS)

rep('''					if bike then addBasket(bike) end''', '''					if bike then addBasket(bike); parkBike(bike, dz) end''')
rep('''				local cb = place("chalkboard", beside(3.6), front + dz * 6.6, yaw + 0.35, 1, {}, false)''',
    '''				local cb = place("chalkboard", beside(3.6), front + dz * 6.6, yaw + 0.35, 1, {}, false)
				if cb then menuBoard(cb) end''')
pat = re.compile(r'place\("cafe_table", ([^\n]*?), 1, \{"UnderTable"\}\)')
assert len(pat.findall(s)) == 3, pat.findall(s)          # 2 real call sites + the one inside the cafeTable helper
s = pat.sub(lambda m: m.group(0) if m.group(1) == "x, z, yaw" else 'cafeTable(%s)' % m.group(1), s)

lines = s.split("\n")
hits = [i for i, l in enumerate(lines) if 'place("fountain",' in l]
assert len(hits) == 1, hits
l = lines[hits[0]]
assert l.rstrip().endswith(")"), l
lines[hits[0]] = l.rstrip().replace('place("fountain",', 'fountainSpray(place("fountain",', 1) + ")"
s = "\n".join(lines)

p.write_text(s, encoding="utf-8")
print("builder patched; size", n0, "->", len(s))
for key in ('slab("Street", CX - QUAY', 'GY - 0.45', '-0.20, 0', 'parkBike(bike, dz)', 'menuBoard(cb)', 'cafeTable(', 'fountainSpray(place'):
    print(f"  {key!r}: {s.count(key)}")
