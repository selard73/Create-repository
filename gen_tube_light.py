"""
Old-building fluorescent tube light fixture, matching the dish/UFO metal style.

Outputs: tube_light[_suffix].obj / .mtl, tube_light_texture.png, tube_light_setup.lua, preview_tube.html
Run:  python gen_tube_light.py            -> 6-stud tube
      python gen_tube_light.py 10 _long   -> 10-stud tube written as tube_light_long.obj
Studio: Home > Import (tick Anchored), select the model, paste tube_light_setup.lua into the command bar.
        The tube becomes glowing Neon with a soft light; change LIGHT_COLOR at the top of the script.
"""
import math
import sys
from pathlib import Path

from PIL import Image

from gen_mesh import add, sub, mul, dot, cross, length, norm, lathe, blob, grain, paint_gradient
from gen_sign import Obj, box
from gen_dish import revolve, rot_x, rot_y, rust, write_preview

OUT = Path(__file__).parent
TEX = 512
LENGTH = float(sys.argv[1]) if len(sys.argv) > 1 else 6.0
SUFFIX = sys.argv[2] if len(sys.argv) > 2 else ""

UV = {
    "plate": (0.00, 1.00, 0.50, 1.00),
    "dark":  (0.00, 0.50, 0.00, 0.50),
    "glow":  (0.50, 1.00, 0.00, 0.50),
}

def along_x(verts):
    """Rotate a Y-axis revolve so it lies along X."""
    return [rot_x(rot_y(p, 0.0), 0.0) if False else (p[1], -p[0], p[2]) for p in verts]

def build():
    o = Obj()
    L, R = LENGTH, 0.22
    # mounting plate against the wall (wall is behind, -Z), with chamfered look via two stacked boxes
    o.add_flat("Plate", box(0.0, 0.0, -0.32, L + 1.2, 0.9, 0.16, UV["plate"]), (0.0, 0.0, -1.0))
    o.add_flat("PlateInner", box(0.0, 0.0, -0.22, L + 0.9, 0.62, 0.06, UV["dark"]), (0.0, 0.0, -1.0))
    # screw heads at the plate corners
    for sx in (-1, 1):
        for sy in (-1, 1):
            c = (sx * (L / 2 + 0.42), sy * 0.3, -0.23)
            v, uv, f = blob(c, (0.06, 0.06, 0.03), 8, 4, UV["dark"])
            o.add_smooth(f"Screw{sx}{sy}", v, uv, f, lambda p, c=c: (c[0], c[1], -1.0))
    # end caps: short cylinders along X holding the tube
    for i, sx in enumerate((-1, 1)):
        v, uv, f = revolve([(0.0, 0.0), (0.34, 0.0), (0.34, 0.5), (0.3, 0.55), (0.0, 0.55)], 20, UV["dark"])
        v = [(sx * (L / 2 - 0.05 + y), x, z) if sx > 0 else (sx * (L / 2 - 0.05) - y, x, z) for x, y, z in v]
        o.add_smooth(f"EndCap{i}", v, uv, f, lambda p, sx=sx: (sx * (L / 2 + 0.2), 0.0, 0.0))
        # bracket from cap down to the plate
        o.add_flat(f"Bracket{i}", box(sx * (L / 2 + 0.2), 0.0, -0.1, 0.5, 0.18, 0.3, UV["dark"]), (sx * (L / 2 + 0.2), 0.0, -1.0))
    # the tube: a capsule along X, rounded ends, tinted glow texture (Neon in Studio)
    n = 10
    prof = [(R * math.sin(math.pi / 2 * k / n), -L / 2 - R * (1 - math.cos(math.pi / 2 * k / n)) + R) for k in range(n + 1)]
    prof = [(0.0, -L / 2 - 0.0)] + [(R * math.sin(math.pi / 2 * k / n), -L / 2 + R - R * math.cos(math.pi / 2 * k / n)) for k in range(1, n + 1)]
    prof += [(R, L / 2 - R)] + [(R * math.cos(math.pi / 2 * k / n), L / 2 - R + R * math.sin(math.pi / 2 * k / n)) for k in range(1, n + 1)]
    v, uv, f = revolve(prof, 24, UV["glow"])
    v = [(y, x, z) for x, y, z in v]      # revolve is around Y; lay it along X
    o.add_smooth("NeonGreen_Tube", v, uv, f, lambda p: (min(max(p[0], -L / 2 + R), L / 2 - R), 0.0, 0.0))
    # faint inner filament line, a thinner tube inside, gives depth when the outer one is translucent
    v, uv, f = revolve([(0.0, -L / 2 + 0.3), (0.05, -L / 2 + 0.3), (0.05, L / 2 - 0.3), (0.0, L / 2 - 0.3)], 8, UV["glow"])
    v = [(y, x, z) for x, y, z in v]
    o.add_smooth("NeonGreen_Filament", v, uv, f, lambda p: (p[0], 0.0, 0.0))
    return o

def paint():
    atlas = Image.new("RGB", (TEX, TEX), (30, 30, 30))
    def rb(r):
        u0, u1, v0, v1 = r
        return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)
    x0, y0, x1, y1 = rb(UV["plate"]); atlas.paste(rust(x1 - x0, y1 - y0, base=(128, 118, 122), seed=3, rust_amount=0.9).convert("RGB"), (x0, y0))
    x0, y0, x1, y1 = rb(UV["dark"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (62, 60, 66), (36, 36, 40)), 0.08, 30), (x0, y0))
    x0, y0, x1, y1 = rb(UV["glow"]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), (170, 255, 190)), (x0, y0))
    return atlas

LUA = r'''-- Tube light: run in the Command Bar with the imported fixture SELECTED. Safe to run again.
local LIGHT_COLOR = Color3.fromRGB(120, 255, 150)   -- change the glow colour here (green default)
local FLICKER = false                               -- true = occasional old-fixture flicker while the game runs
local model = game.Selection:Get()[1] or workspace:FindFirstChild("tube_light")
assert(model and model:IsA("Model"), "Select the imported tube light model first")
local tube
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Light") then c:Destroy() end end
		if p.Name == "NeonGreen_Tube" then
			tube = p
			p.Material = Enum.Material.Neon; p.Color = LIGHT_COLOR; p.TextureID = ""; p.Transparency = 0.25; p.CanCollide = false; p.CastShadow = false
		elseif p.Name == "NeonGreen_Filament" then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(235, 255, 240); p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
		else
			p.Material = Enum.Material.SmoothPlastic
		end
	end
end
if tube then
	local l = Instance.new("SurfaceLight"); l.Face = Enum.NormalId.Front; l.Color = LIGHT_COLOR; l.Range = 14; l.Brightness = 1.6; l.Angle = 150; l.Shadows = false; l.Parent = tube
	local p = Instance.new("PointLight"); p.Color = LIGHT_COLOR; p.Range = 8; p.Brightness = 0.6; p.Shadows = false; p.Parent = tube
end
local old = model:FindFirstChild("TubeFlicker"); if old then old:Destroy() end
if FLICKER and tube then
	local s = Instance.new("Script"); s.Name = "TubeFlicker"
	s.Source = [[
local tube = script.Parent:FindFirstChild("NeonGreen_Tube")
local rng = Random.new()
while tube and tube.Parent do
	task.wait(rng:NextNumber(2, 7))
	for i = 1, rng:NextInteger(1, 3) do
		tube.Material = Enum.Material.SmoothPlastic
		for _, l in ipairs(tube:GetChildren()) do if l:IsA("Light") then l.Enabled = false end end
		task.wait(rng:NextNumber(0.04, 0.12))
		tube.Material = Enum.Material.Neon
		for _, l in ipairs(tube:GetChildren()) do if l:IsA("Light") then l.Enabled = true end end
		task.wait(rng:NextNumber(0.05, 0.2))
	end
end
]]
	s.Parent = model
end
model.Name = "TubeLight"
print("Tube light applied")
'''

if __name__ == "__main__":
    o = build()
    tris = o.write(OUT / f"tube_light{SUFFIX}.obj", "tube_light_texture.png")
    paint().save(OUT / "tube_light_texture.png")
    (OUT / "tube_light_setup.lua").write_text(LUA, encoding="utf-8")
    write_preview((OUT / f"tube_light{SUFFIX}.obj").read_text(encoding="utf-8"), OUT / "tube_light_texture.png", "preview_tube.html", (4, 3, LENGTH * 1.1 + 3), (0, 0, 0))
    print(f"tube_light{SUFFIX}.obj: {tris} triangles, {len(o.objects)} pieces, length {LENGTH}")
