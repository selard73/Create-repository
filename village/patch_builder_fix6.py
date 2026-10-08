"""Fountain v6, after Shannon's second reference photo (classic tiered garden fountain): no dome, no column. Two dozen
thin beaded jets leave the finial's top steeply (70 degrees), arc up and out in an umbrella of streams and land in the
big basin beyond the upper bowl. Launch speed is solved from the landing radius, the elevation and the drop, so the arcs
always meet the basin water. The v4 rim curtain and RimRing stay. Writes the routine into make_village_scripts.py
(fountainSpray) and export/Fix6.rbxmx (ModuleScript 'Run') for applying to the standing fountain.
Run: python patch_builder_fix6.py && python make_village_scripts.py"""
import shutil
import xml.dom.minidom as md
from pathlib import Path

D = Path(__file__).parent
p = D / "make_village_scripts.py"
bk = D / "make_village_scripts.before_fix6.py"
if bk.exists(): shutil.copy2(bk, p)          # re-runnable: always start from the pre-fix-6 builder
else: shutil.copy2(p, bk)
s = p.read_text(encoding="utf-8")

FOUNTAIN = r'''	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	if not base then return model end
	for _, n in ipairs({"Jet", "JetTop", "Spout", "Mist", "Splash", "RimStream", "RimRing", "Stem", "Cap", "CapRim"}) do
		local old = model:FindFirstChild(n, true)
		while old do old:Destroy() old = model:FindFirstChild(n, true) end
	end
	local bb, size = model:GetBoundingBox()
	local s = model:GetScale()
	local bottom = bb.Position.Y - size.Y / 2
	local cx, cz = bb.Position.X, bb.Position.Z
	local function streaks(parent, name, rate, speedLo, speedHi, spread, life, size0, size1, accel)
		local pe = Instance.new("ParticleEmitter"); pe.Name = name
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(C(205, 232, 255), C(240, 248, 255))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size0), NumberSequenceKeypoint.new(1, size1)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1)})
		pe.Squash = NumberSequence.new(-2.5)                           -- NEGATIVE = taller: long thin drops along their motion
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
		pe.Lifetime = NumberRange.new(life * 0.9, life * 1.1); pe.Rate = rate; pe.Speed = NumberRange.new(speedLo, speedHi)
		pe.SpreadAngle = Vector2.new(spread, spread); pe.Acceleration = Vector3.new(0, accel or -30, 0); pe.Drag = 0.1
		pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.05; pe.LightInfluence = 0.6
		pe.Parent = parent
		return pe
	end
	-- the top: two dozen thin beaded jets leave the finial steeply, arc up and out in an umbrella of streams and land in
	-- the basin beyond the upper bowl. Launch speed solved from landing radius, elevation and drop (particle gravity G).
	local spoutY = bottom + 6.4 * s + 0.05
	local nJet, elev, G = 24, math.rad(70), 60
	local landR, drop = 3.8 * s, (6.4 - 1.1) * s
	local ct, st = math.cos(elev), math.sin(elev)
	local vt = landR / ct                                                  -- speed x time (the horizontal reach)
	local t = math.sqrt(2 * (st * vt + drop) / G)                          -- flight time down to the basin water
	local v = vt / t
	for i = 1, nJet do
		local ang = (i - 1) / nJet * 2 * math.pi
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local dir = out * ct + Vector3.yAxis * st
		local a = Instance.new("Attachment"); a.Name = "Jet"; a.Parent = base
		a.WorldCFrame = CFrame.fromMatrix(Vector3.new(cx, spoutY, cz) + out * (0.12 * s), dir:Cross(Vector3.yAxis).Unit, dir)
		local pe = streaks(a, "Arc", 40, v * 0.985, v * 1.015, 0.6, t, 0.12 * s, 0.16 * s, -G)
		pe.Drag = 0; pe.Squash = NumberSequence.new(-1.8)
		pe.Lifetime = NumberRange.new(t * 0.98, t * 1.02)
		pe.Color = ColorSequence.new(C(222, 240, 255), C(248, 252, 255))
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.9, 0.3), NumberSequenceKeypoint.new(1, 0.8)})
	end
	-- the curtain: thin streams spilling over the upper bowl's rim, thrown a little outward, falling into the basin
	local rimR, rimY = 2.2 * s, bottom + 4.7 * s
	local n = 20
	for i = 1, n do
		local ang = (i - 1) / n * 2 * math.pi
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local pos = Vector3.new(cx, rimY, cz) + out * rimR
		local dir = (out * 0.94 + Vector3.yAxis * 0.34).Unit                  -- outward, 20 degrees above level
		local a = Instance.new("Attachment"); a.Name = "RimStream"; a.Parent = base
		a.WorldCFrame = CFrame.fromMatrix(pos, dir:Cross(Vector3.yAxis).Unit, dir)
		streaks(a, "Stream", 42, 2.0 * s, 2.6 * s, 4, 0.9, 0.14 * s, 0.19 * s, -30)
	end
	-- a thin glassy sheet just over the rim so the spill reads as water even at a distance
	local ring = Instance.new("Part"); ring.Name = "RimRing"; ring.Shape = Enum.PartType.Cylinder; ring.Anchored = true; ring.CanCollide = false; ring.CanQuery = false; ring.Locked = true
	ring.Material = Enum.Material.Glass; ring.Color = C(170, 215, 240); ring.Transparency = 0.55; ring.CastShadow = false
	ring.Size = Vector3.new(0.06, 2 * rimR + 0.16 * s, 2 * rimR + 0.16 * s)
	ring.CFrame = CFrame.new(cx, rimY + 0.03, cz) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = model
	return model
'''

start = s.index("local function fountainSpray(model)")
end_ = s.index("\nend\n", start) + 1
s = s[:start] + "local function fountainSpray(model)\n" + FOUNTAIN + s[end_:]
p.write_text(s, encoding="utf-8")

src = ('return function()\n\tlocal C = Color3.fromRGB\n\tlocal model\n'
       '\tfor _, m in ipairs(workspace.Village.Props:GetChildren()) do if m.Name == "fountain" then model = m break end end\n'
       '\tlocal function fountainSpray(model)\n' + FOUNTAIN + '\tend\n\tfountainSpray(model)\n'
       '\tlocal nj = 0 for _, a in ipairs(model:GetDescendants()) do if a.Name == "Jet" then nj += 1 end end\n'
       '\tprint("FOUNTAIN v6 applied:", model ~= nil, "jets", nj, "cap left", model:FindFirstChild("Cap", true) ~= nil)\nend\n')
assert "]]>" not in src
xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0">
    <Properties><string name="Name">Fix6</string></Properties>
    <Item class="ModuleScript" referent="RBX1">
      <Properties>
        <string name="Name">Run</string>
        <ProtectedString name="Source"><![CDATA[{src}]]></ProtectedString>
      </Properties>
    </Item>
  </Item>
</roblox>
'''
md.parseString(xml.encode("utf-8"))
(D / "export" / "Fix6.rbxmx").write_text(xml, encoding="utf-8")
print("fountain v6 in builder; wrote export/Fix6.rbxmx;", len(src), "chars; Cap refs left in builder:", s.count('glass("Cap"'))
