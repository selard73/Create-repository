"""Fountain v4, after Shannon's reference photo (classic tiered garden fountain): a short spout on the finial and a
curtain of thin water streams spilling over the upper bowl's rim into the basin. Kit geometry (gen_village.fountain,
kit units, scale 1.4 in the village): basin water y 1.1, upper bowl outer rim r 2.2 at y 4.7, water y 4.55, finial top
y 6.4. Writes the same routine into make_village_scripts.py (fountainSpray) and export/FountainV4.rbxmx (ModuleScript
'Run' returning a function) for applying to the fountain already standing in the place.
Run: python patch_builder_fix4.py && python make_village_scripts.py"""
import shutil
import xml.dom.minidom as md
from pathlib import Path

D = Path(__file__).parent
p = D / "make_village_scripts.py"
shutil.copy2(p, D / "make_village_scripts.before_fix4.py")
s = p.read_text(encoding="utf-8")

BODY = r'''	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	if not base then return model end
	for _, n in ipairs({"Jet", "JetTop", "Spout", "Mist", "Splash", "RimStream", "RimRing"}) do
		local old = model:FindFirstChild(n, true)
		while old do old:Destroy() old = model:FindFirstChild(n, true) end
	end
	local bb, size = model:GetBoundingBox()
	local s = model:GetScale()
	local bottom = bb.Position.Y - size.Y / 2
	local cx, cz = bb.Position.X, bb.Position.Z
	local function streaks(parent, name, rate, speedLo, speedHi, spread, life, size0, size1)
		local pe = Instance.new("ParticleEmitter"); pe.Name = name
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(C(205, 232, 255), C(240, 248, 255))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size0), NumberSequenceKeypoint.new(1, size1)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1)})
		pe.Squash = NumberSequence.new(-2.5)                           -- NEGATIVE = taller: long thin drops along their motion
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
		pe.Lifetime = NumberRange.new(life * 0.9, life * 1.1); pe.Rate = rate; pe.Speed = NumberRange.new(speedLo, speedHi)
		pe.SpreadAngle = Vector2.new(spread, spread); pe.Acceleration = Vector3.new(0, -30, 0); pe.Drag = 0.1
		pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.15; pe.LightInfluence = 0.6
		pe.Parent = parent
		return pe
	end
	-- the small spout on the finial, falling back into the upper bowl
	local spout = Instance.new("Attachment"); spout.Name = "Spout"; spout.Parent = base
	spout.WorldCFrame = CFrame.new(cx, bottom + 6.4 * s, cz)
	streaks(spout, "SpoutDrops", 90, 2.6 * s, 3.4 * s, 14, 0.95, 0.14 * s, 0.19 * s)
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
		streaks(a, "Stream", 42, 2.0 * s, 2.6 * s, 4, 0.9, 0.14 * s, 0.19 * s)
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
s = s[:start] + "local function fountainSpray(model)\n" + BODY + s[end_:]
p.write_text(s, encoding="utf-8")

src = ('return function()\n\tlocal C = Color3.fromRGB\n\tlocal model\n'
       '\tfor _, m in ipairs(workspace.Village.Props:GetChildren()) do if m.Name == "fountain" then model = m break end end\n'
       '\tlocal function fountainSpray(model)\n' + BODY + '\tend\n\tfountainSpray(model)\n'
       '\tprint("FOUNTAIN v4 applied:", model ~= nil, "streams", model and #model:GetDescendants())\nend\n')
assert "]]>" not in src
xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0">
    <Properties><string name="Name">FountainV4</string></Properties>
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
(D / "export" / "FountainV4.rbxmx").write_text(xml, encoding="utf-8")
print("fountain v4 in builder; wrote export/FountainV4.rbxmx; odd-quote lines:", sum(1 for l in src.splitlines() if l.count('"') % 2 == 1 and "--" not in l))
