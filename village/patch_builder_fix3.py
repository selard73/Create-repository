"""Fountain v3: water streaks instead of a cloud. Droplets are small, stretched along their motion (VelocityParallel +
Squash), thrown up in a tight cone from the jet top and pulled back down; a tiny splash emitter sits at the upper bowl's
water surface. No mist. Also writes the same Lua to fountain_v3.lua for pasting into the command bar.
Run: python patch_builder_fix3.py && python make_village_scripts.py"""
import shutil
from pathlib import Path

D = Path(__file__).parent
p = D / "make_village_scripts.py"
shutil.copy2(p, D / "make_village_scripts.before_fix3.py")
s = p.read_text(encoding="utf-8")

BODY = r'''	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	if not base then return model end
	for _, n in ipairs({"Jet", "JetTop", "Spout", "Mist"}) do local old = model:FindFirstChild(n, true) while old do old:Destroy() old = model:FindFirstChild(n, true) end end
	local bb, size = model:GetBoundingBox()
	local s = model:GetScale()
	local top = Vector3.new(bb.Position.X, bb.Position.Y + size.Y / 2, bb.Position.Z)
	local h = 2.2 * s
	local function water(name, shape, sz, cf, tr)
		local w = Instance.new("Part"); w.Name = name; w.Shape = shape; w.Anchored = true; w.CanCollide = false; w.CanQuery = false; w.Locked = true
		w.Material = Enum.Material.Glass; w.Color = C(165, 212, 240); w.Transparency = tr; w.CastShadow = false
		w.Size = sz; w.CFrame = cf; w.Parent = model
		return w
	end
	water("Jet", Enum.PartType.Cylinder, Vector3.new(h, 0.34 * s, 0.34 * s), CFrame.new(top + Vector3.new(0, h / 2 - 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), 0.45)
	water("JetTop", Enum.PartType.Ball, Vector3.new(0.5 * s, 0.5 * s, 0.5 * s), CFrame.new(top + Vector3.new(0, h - 0.2, 0)), 0.45)
	local function emitter(parent, name, rate, speedLo, speedHi, spread, life, size0, size1, accel)
		local pe = Instance.new("ParticleEmitter"); pe.Name = name
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(C(190, 226, 255), C(235, 246, 255))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size0), NumberSequenceKeypoint.new(1, size1)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.75, 0.55), NumberSequenceKeypoint.new(1, 1)})
		pe.Squash = NumberSequence.new(2.2)                          -- stretched along the motion: streaks, not puffs
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
		pe.Lifetime = NumberRange.new(life * 0.85, life * 1.15); pe.Rate = rate; pe.Speed = NumberRange.new(speedLo, speedHi)
		pe.SpreadAngle = Vector2.new(spread, spread); pe.Acceleration = Vector3.new(0, accel, 0); pe.Drag = 0.2
		pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.2; pe.LightInfluence = 0.5
		pe.Parent = parent
		return pe
	end
	local a = Instance.new("Attachment"); a.Name = "Spout"; a.Parent = base
	a.WorldCFrame = CFrame.new(top + Vector3.new(0, h - 0.1, 0))
	emitter(a, "Streaks", 140, 7 * s, 10 * s, 11, 1.15, 0.13 * s, 0.2 * s, -34)
	local waterPart = model:FindFirstChild("Water", true)
	if waterPart then
		local wb, ws = waterPart.CFrame, waterPart.Size
		local sp = Instance.new("Attachment"); sp.Name = "Splash"; sp.Parent = base
		sp.WorldCFrame = CFrame.new(bb.Position.X, wb.Position.Y + ws.Y / 2 + 0.05, bb.Position.Z)
		local e = emitter(sp, "SplashDrops", 60, 1.5 * s, 3 * s, 70, 0.4, 0.08 * s, 0.12 * s, -30)
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	end
	return model
'''

start = s.index("local function fountainSpray(model)")
end_ = s.index("\nend\n", start) + 1
s = s[:start] + "local function fountainSpray(model)\n" + BODY + s[end_:]
p.write_text(s, encoding="utf-8")

# command-bar version: same body applied to the fountain already standing in Village.Props
lua = ('local C=Color3.fromRGB local model for _,m in ipairs(workspace.Village.Props:GetChildren()) do if m.Name=="fountain" then model=m break end end '
       'local function fountainSpray(model)\n' + BODY + 'end fountainSpray(model) print("FOUNTAIN v3 applied", model and model:FindFirstChild("Jet")~=nil, model and model:FindFirstChild("Splash", true)~=nil)')
(D / "fountain_v3.lua").write_text(lua, encoding="utf-8")
print("fountain v3 patched; command-bar script", len(lua), "chars")
