"""
Martian environment props: cartoon red rock formations and small desert scatter.
One texture atlas shared by all pieces; each prop is its own .obj so it can be placed on its own.

Outputs: rock_mesa.obj, rock_spire.obj, rock_boulders.obj, rock_ledge.obj, barrel_cactus.obj, pebbles.obj,
         rocks_texture.png (+ one .mtl per obj), preview_rocks.html
Run:  python gen_rocks.py
Studio: Home > Import > any of the .obj files (tick Anchored). No script needed; the pink flower and the
        cactus ridge lines are painted. Combine with mars_environment.lua for the ground and sky.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from gen_mesh import add, sub, mul, dot, cross, length, norm, lathe, blob, grain, paint_gradient
from gen_sign import Obj, tube
from gen_dish import revolve, rot_y, write_preview

OUT = Path(__file__).parent
TEX = 1024

UV = {
    "rock":    (0.00, 0.50, 0.50, 1.00),   # strata, u = angle, v = bottom->top
    "rockdk":  (0.50, 1.00, 0.50, 1.00),   # darker variant
    "top":     (0.00, 0.50, 0.25, 0.50),   # dusty flat tops
    "cactus":  (0.50, 0.75, 0.25, 0.50),
    "pebble":  (0.75, 1.00, 0.25, 0.50),
    "pink":    (0.00, 0.12, 0.00, 0.12),
    "yellow":  (0.12, 0.24, 0.00, 0.12),
    "spine":   (0.24, 0.36, 0.00, 0.12),
    "stone1":  (0.36, 0.48, 0.00, 0.12),   # solid orange
    "stone2":  (0.48, 0.60, 0.00, 0.12),   # solid dark red-brown
    "stone3":  (0.60, 0.72, 0.00, 0.12),   # solid mid rust
    "stonetop": (0.72, 0.84, 0.00, 0.12),  # slightly lighter top
}

def lump(o, name, levels, segs, uv, seed, center=(0.0, 0.0, 0.0), flat_top=True, top_uv=None):
    """Irregular revolved rock. levels: list of (radius, y). Radius is wobbled per angle and per
    level with seeded sines so every rock is different but smooth. Flat tops get a cap ring."""
    rnd = random.Random(seed)
    ph = [rnd.uniform(0, 6.28) for _ in range(6)]
    amp = [rnd.uniform(0.05, 0.14) for _ in range(6)]
    def wob(th, k):
        return 1 + amp[0] * math.sin(2 * th + ph[0] + k * 0.4) + amp[1] * math.sin(3 * th + ph[1] - k * 0.3) \
                 + amp[2] * math.sin(5 * th + ph[2] + k * 0.7) + 0.04 * math.sin(9 * th + ph[3])
    u0, u1, v0, v1 = uv
    rings = []
    total = levels[-1][1] - levels[0][1] or 1
    for k, (r, y) in enumerate(levels):
        pts, uvs = [], []
        for j in range(segs + 1):
            th = 2 * math.pi * j / segs
            rr = r * wob(th, k) if r > 1e-6 else 0.0
            pts.append((center[0] + rr * math.cos(th), center[1] + y, center[2] + rr * math.sin(th)))
            uvs.append((u0 + (u1 - u0) * j / segs, v0 + (v1 - v0) * (y - levels[0][1]) / total))
        rings.append((pts, uvs, r < 1e-6))
    v, uvv, f = lathe(rings)
    o.add_smooth(name, v, uvv, f, lambda p: (center[0], min(p[1], center[1] + total * 0.5), center[2]))
    if flat_top and levels[-1][0] > 1e-6:
        # cap: fan from the top ring to the centre, textured with the dusty top
        tr, ty = levels[-1]
        cap = [(tr * wob(2 * math.pi * j / segs, len(levels) - 1) * math.cos(2 * math.pi * j / segs), ty,
                tr * wob(2 * math.pi * j / segs, len(levels) - 1) * math.sin(2 * math.pi * j / segs)) for j in range(segs + 1)]
        cu0, cu1, cv0, cv1 = top_uv or UV["top"]
        ring_pts = [add(center, p) for p in cap]
        ring_uv = [(cu0 + (cu1 - cu0) * (0.5 + 0.48 * math.cos(2 * math.pi * j / segs)), cv0 + (cv1 - cv0) * (0.5 + 0.48 * math.sin(2 * math.pi * j / segs))) for j in range(segs + 1)]
        apex = [(center[0], center[1] + ty + 0.02, center[2])] * (segs + 1)
        apex_uv = [((cu0 + cu1) / 2, (cv0 + cv1) / 2)] * (segs + 1)
        v, uvv, f = lathe([(ring_pts, ring_uv, False), (apex, apex_uv, True)])
        o.add_smooth(name + "Top", v, uvv, f, lambda p: (center[0], center[1], center[2]))

def slab(o, name, center, radius, height, sides, seed, taper=0.88, yaw=0.0, sx=1.0, sz=1.0, tilt=0.0, uv=None):
    """One geometric stone: an irregular convex polygon extruded with slanted sides and a flat top.
    Flat shaded so every facet reads as a plane, like the panels on the dish and saucer."""
    rnd = random.Random(seed)
    uv = uv or UV["rock"]
    angs = sorted(rnd.uniform(0, 2 * math.pi) for _ in range(sides))
    # push angles apart so no two facets are slivers
    angs = [2 * math.pi * i / sides + rnd.uniform(-0.18, 0.18) for i in range(sides)]
    rad = [radius * rnd.uniform(0.88, 1.1) for _ in range(sides)]
    def ring(scale, y, shift):
        pts = []
        for a_, r in zip(angs, rad):
            x, z = r * scale * math.cos(a_) * sx, r * scale * math.sin(a_) * sz
            x, z = x * math.cos(yaw) - z * math.sin(yaw), x * math.sin(yaw) + z * math.cos(yaw)
            pts.append((center[0] + x + shift[0], center[1] + y + z * math.tan(tilt), center[2] + z + shift[1]))
        return pts
    top_shift = (rnd.uniform(-0.12, 0.12) * radius, rnd.uniform(-0.12, 0.12) * radius)
    bot, top = ring(1.0, 0.0, (0.0, 0.0)), ring(taper, height, top_shift)
    u0, u1, v0, v1 = uv
    mid = ((u0 + u1) / 2, (v0 + v1) / 2)
    tris = []
    for i in range(sides):
        j = (i + 1) % sides
        tris.append(((bot[i], mid), (bot[j], mid), (top[j], mid)))
        tris.append(((bot[i], mid), (top[j], mid), (top[i], mid)))
    tu0, tu1, tv0, tv1 = UV["stonetop"] if uv is UV["stone1"] else uv
    tc = (sum(p[0] for p in top) / sides, sum(p[1] for p in top) / sides, sum(p[2] for p in top) / sides)
    for i in range(sides):
        j = (i + 1) % sides
        def tuv(p):
            return (tu0 + (tu1 - tu0) * (0.5 + 0.45 * (p[0] - tc[0]) / max(radius, 0.1)), tv0 + (tv1 - tv0) * (0.5 + 0.45 * (p[2] - tc[2]) / max(radius, 0.1)))
        tris.append(((tc, tuv(tc)), (top[i], tuv(top[i])), (top[j], tuv(top[j]))))
    bc = (center[0], center[1], center[2])
    for i in range(sides):
        j = (i + 1) % sides
        tris.append(((bc, mid), (bot[j], mid), (bot[i], mid)))
    o.add_flat(name, tris, (center[0], center[1] + height * 0.5, center[2]))
    return tc

def stack(o, prefix, base, layers, seed):
    """layers: list of (radius, height, sides, sx, sz). Each slab sits on the previous one's top,
    nudged sideways and rotated a little, alternating light and dark stone."""
    rnd = random.Random(seed)
    x, y, z = base
    for i, (r, h, n, sx, sz) in enumerate(layers):
        yaw = rnd.uniform(0, math.pi)
        c = (x + rnd.uniform(-0.12, 0.12) * r, y, z + rnd.uniform(-0.12, 0.12) * r)
        tones = (UV["stone1"], UV["stone2"], UV["stone3"])
        slab(o, f"{prefix}{i}", c, r, h, n, seed * 7 + i, taper=rnd.uniform(0.9, 0.98), yaw=yaw, sx=sx, sz=sz,
             tilt=rnd.uniform(-0.16, 0.16), uv=tones[(i + seed) % 3])
        y += h * 0.92

def build_mesa():
    o = Obj()
    stack(o, "Mesa", (0.0, 0.0, 0.0), [(9.5, 4.5, 5, 1.0, 0.8), (8.4, 4.0, 5, 1.05, 0.85), (6.8, 3.4, 4, 1.0, 0.9)], 3)
    stack(o, "MesaStone", (10.5, 0.0, 4.0), [(2.2, 2.0, 5, 1.0, 0.8)], 11)
    return o

def build_spire():
    o = Obj()
    stack(o, "Spire", (0.0, 0.0, 0.0), [(4.6, 4.2, 5, 1.0, 0.85), (3.6, 4.0, 4, 0.9, 1.0), (2.6, 3.8, 5, 1.0, 0.9), (1.6, 3.4, 4, 1.0, 1.0)], 7)
    stack(o, "SpireFoot", (4.6, 0.0, 1.6), [(2.4, 2.2, 5, 1.1, 0.8)], 8)
    return o

def build_boulders():
    o = Obj()
    stack(o, "BoulderA", (0.0, 0.0, 0.0), [(2.8, 2.4, 5, 1.1, 0.85), (1.9, 1.8, 4, 1.0, 1.0)], 20)
    stack(o, "BoulderB", (4.2, 0.0, 1.6), [(2.0, 2.0, 5, 1.0, 0.9)], 21)
    stack(o, "BoulderC", (-3.2, 0.0, 2.8), [(1.6, 1.6, 4, 1.2, 0.85)], 22)
    return o

def build_ledge():
    o = Obj()
    stack(o, "LedgeA", (-6.5, 0.0, 0.0), [(4.6, 2.2, 5, 1.4, 0.75), (3.4, 1.8, 4, 1.3, 0.8)], 30)
    stack(o, "LedgeB", (1.0, 0.0, 1.0), [(5.2, 2.6, 5, 1.4, 0.75), (3.8, 2.0, 4, 1.3, 0.8)], 31)
    stack(o, "LedgeC", (8.0, 0.0, -0.6), [(3.8, 2.0, 5, 1.3, 0.8)], 32)
    return o

def build_barrel_cactus():
    o = Obj()
    # squat ribbed body
    prof = [(0.0, 0.0), (0.9, 0.05), (1.25, 0.5), (1.35, 1.1), (1.25, 1.7), (0.9, 2.1), (0.4, 2.3), (0.0, 2.35)]
    segs = 48
    u0, u1, v0, v1 = UV["cactus"]
    rings = []
    for k, (r, y) in enumerate(prof):
        pts, uvs = [], []
        for j in range(segs + 1):
            th = 2 * math.pi * j / segs
            rr = r * (1 + 0.07 * math.cos(12 * th)) if r > 1e-6 else 0.0
            pts.append((rr * math.cos(th), y, rr * math.sin(th)))
            uvs.append((u0 + (u1 - u0) * j / segs, v0 + (v1 - v0) * y / 2.35))
        rings.append((pts, uvs, r < 1e-6))
    v, uv, f = lathe(rings)
    o.add_smooth("Barrel", v, uv, f, lambda p: (0.0, 1.1, 0.0))
    # spines: little pale dots along the ribs
    rnd = random.Random(5)
    for i in range(24):
        th = 2 * math.pi * (i % 12) / 12
        y = 0.6 + 1.1 * (i // 12) + rnd.uniform(-0.15, 0.15)
        r = 1.33 * (1 + 0.07) * (1 - ((y - 1.1) / 1.4) ** 2 * 0.35)
        c = (r * math.cos(th), y, r * math.sin(th))
        v, uv, f = blob(c, (0.09, 0.09, 0.09), 6, 3, UV["spine"])
        o.add_smooth(f"Spine{i}", v, uv, f, lambda p, c=c: c)
    # pink flower crown with a yellow centre
    for i in range(7):
        a = 2 * math.pi * i / 7
        c = (0.45 * math.cos(a), 2.42, 0.45 * math.sin(a))
        v, uv, f = blob(c, (0.3, 0.16, 0.3), 10, 5, UV["pink"])
        o.add_smooth(f"Petal{i}", v, uv, f, lambda p, c=c: c)
    v, uv, f = blob((0.0, 2.55, 0.0), (0.28, 0.2, 0.28), 10, 5, UV["yellow"])
    o.add_smooth("FlowerCore", v, uv, f, lambda p: (0.0, 2.5, 0.0))
    return o

def build_pebbles():
    o = Obj()
    rnd = random.Random(9)
    for i in range(9):
        a, d = rnd.uniform(0, 6.28), rnd.uniform(0.0, 1.6)
        s = rnd.uniform(0.18, 0.45)
        c = (d * math.cos(a), s * 0.5, d * math.sin(a))
        v, uv, f = blob(c, (s * 1.3, s * 0.7, s), 10, 5, UV["pebble"] if i % 3 else UV["rockdk"], noise=0.12, seed=40 + i)
        o.add_smooth(f"Pebble{i}", v, uv, f, lambda p, c=c: c)
    return o

# ------------------------------------------------------------- texture ----
def rbox(r):
    u0, u1, v0, v1 = r
    return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)

def strata(w, h, base_top, base_bot, seed, bands=9):
    """Red rock: warm gradient, wavy darker strata bands, light dust speckle."""
    rnd = random.Random(seed)
    img = grain(paint_gradient(w, h, base_top, base_bot), 0.05, 30).convert("RGBA")
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    for b in range(bands):
        y = int(h * (b + rnd.uniform(0.2, 0.8)) / bands)
        thick = rnd.randint(int(h * 0.012), int(h * 0.04))
        col = rnd.choice(((120, 44, 32, 150), (150, 62, 40, 120), (98, 36, 28, 160)))
        pts = []
        for x in range(0, w + 1, w // 16):
            pts.append((x, y + int(math.sin(x / w * 6.28 * 2 + b) * h * 0.012) + rnd.randint(-3, 3)))
        pts[-1] = (w, pts[0][1])     # wrap seam
        d.line(pts, fill=col, width=thick, joint="curve")
        d.line([(x, yy + thick // 2 + 2) for x, yy in pts], fill=(232, 150, 96, 60), width=3, joint="curve")
    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    img.alpha_composite(layer)
    d = ImageDraw.Draw(img)
    for _ in range(int(w * h / 900)):
        x, y = rnd.randint(0, w - 1), rnd.randint(0, h - 1)
        d.point((x, y), fill=rnd.choice(((240, 170, 120, 90), (110, 44, 34, 90))))
    return img.convert("RGB")

def paint():
    atlas = Image.new("RGB", (TEX, TEX), (30, 30, 30))
    x0, y0, x1, y1 = rbox(UV["rock"]); atlas.paste(strata(x1 - x0, y1 - y0, (214, 118, 72), (172, 78, 50), 1), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["rockdk"]); atlas.paste(strata(x1 - x0, y1 - y0, (186, 92, 58), (140, 58, 42), 2, bands=7), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["top"]); w, h = x1 - x0, y1 - y0
    top = grain(paint_gradient(w, h, (232, 156, 104), (220, 138, 88)), 0.08, 40); d = ImageDraw.Draw(top)
    rnd = random.Random(4)
    for _ in range(60):
        x, y, r = rnd.randint(0, w), rnd.randint(0, h), rnd.randint(6, 30)
        d.ellipse([x - r, y - r * 0.5, x + r, y + r * 0.5], fill=rnd.choice(((205, 120, 78), (240, 172, 120))))
    atlas.paste(top.filter(ImageFilter.GaussianBlur(3)), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["cactus"]); w, h = x1 - x0, y1 - y0
    c = grain(paint_gradient(w, h, (128, 172, 78), (92, 140, 62)), 0.05, 30); d = ImageDraw.Draw(c)
    for k in range(12):
        x = int(w * k / 12); d.line([(x, 0), (x, h)], fill=(70, 112, 50), width=5); d.line([(x + 6, 0), (x + 6, h)], fill=(180, 220, 120), width=2)
    atlas.paste(c, (x0, y0))
    x0, y0, x1, y1 = rbox(UV["pebble"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (196, 118, 84), (150, 84, 60)), 0.12, 40), (x0, y0))
    for key, col in (("pink", (255, 96, 170)), ("yellow", (255, 214, 70)), ("spine", (245, 235, 200)),
                     ("stone1", (206, 110, 62)), ("stone2", (146, 60, 42)), ("stone3", (180, 86, 52)), ("stonetop", (214, 124, 76))):
        x0, y0, x1, y1 = rbox(UV[key]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), col), (x0, y0))
    return atlas

MARS_LUA = r'''-- Martian environment: run once in Studio's Command Bar (edit mode). Keeps daytime. Safe to run again.
-- 1) every terrain material becomes a rust red/orange (paint hills with the Terrain Editor; they come out red)
-- 2) the Baseplate (if any) becomes red sand
-- 3) warm sunlight with only a light dusty haze at the horizon
local T = workspace.Terrain
local colors = {
	[Enum.Material.Sand] = Color3.fromRGB(176, 78, 44),
	[Enum.Material.Ground] = Color3.fromRGB(150, 64, 38),
	[Enum.Material.Sandstone] = Color3.fromRGB(190, 92, 50),
	[Enum.Material.Rock] = Color3.fromRGB(128, 50, 36),
	[Enum.Material.Slate] = Color3.fromRGB(118, 46, 34),
	[Enum.Material.Basalt] = Color3.fromRGB(100, 40, 32),
	[Enum.Material.Mud] = Color3.fromRGB(132, 56, 38),
	[Enum.Material.Grass] = Color3.fromRGB(168, 76, 44),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(160, 72, 42),
	[Enum.Material.Cobblestone] = Color3.fromRGB(140, 62, 44),
	[Enum.Material.Pavement] = Color3.fromRGB(130, 76, 62),
	[Enum.Material.Asphalt] = Color3.fromRGB(70, 42, 38),
	[Enum.Material.Limestone] = Color3.fromRGB(198, 116, 76),
	[Enum.Material.CrackedLava] = Color3.fromRGB(96, 34, 26),
	[Enum.Material.Snow] = Color3.fromRGB(220, 170, 140),
	[Enum.Material.Glacier] = Color3.fromRGB(214, 160, 130),
	[Enum.Material.Salt] = Color3.fromRGB(226, 186, 160),
	[Enum.Material.Ice] = Color3.fromRGB(214, 160, 130),
}
local applied = 0
for mat, col in pairs(colors) do
	local ok = pcall(function() T:SetMaterialColor(mat, col) end)
	if ok then applied += 1 end
end
T.WaterColor = Color3.fromRGB(70, 150, 140)
local base = workspace:FindFirstChild("Baseplate")
if base and base:IsA("BasePart") then base.Color = Color3.fromRGB(172, 76, 44); base.Material = Enum.Material.Sand end
local L = game:GetService("Lighting")
L.Ambient = Color3.fromRGB(96, 62, 54)
L.OutdoorAmbient = Color3.fromRGB(138, 92, 78)
L.ColorShift_Top = Color3.fromRGB(255, 214, 170)
L.ColorShift_Bottom = Color3.fromRGB(170, 84, 56)
L.Brightness = 2
L.ExposureCompensation = 0
L.FogStart = 100000; L.FogEnd = 100000     -- no legacy fog
local atmo = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", L)
atmo.Density = 0.12; atmo.Offset = 0
atmo.Color = Color3.fromRGB(232, 170, 130); atmo.Decay = Color3.fromRGB(150, 80, 56)
atmo.Glare = 0.15; atmo.Haze = 0.6
print("Mars environment applied: " .. applied .. " terrain colours, baseplate, warm sky")
'''

if __name__ == "__main__":
    props = {
        "rock_mesa": build_mesa(), "rock_spire": build_spire(), "rock_boulders": build_boulders(),
        "rock_ledge": build_ledge(), "barrel_cactus": build_barrel_cactus(), "pebbles": build_pebbles(),
    }
    paint().save(OUT / "rocks_texture.png")
    total = 0
    for name, o in props.items():
        tris = o.write(OUT / f"{name}.obj", "rocks_texture.png")
        total += tris
        print(f"{name}.obj: {tris} triangles, {len(o.objects)} pieces")
    (OUT / "mars_environment.lua").write_text(MARS_LUA, encoding="utf-8")
    # preview: all props laid out together
    scene = Obj()
    layout = {"rock_mesa": (0, 0, -22), "rock_spire": (-22, 0, -6), "rock_boulders": (14, 0, 2), "rock_ledge": (-4, 0, 8), "barrel_cactus": (10, 0, 12), "pebbles": (4, 0, 14)}
    for name, o in props.items():
        dx, dy, dz = layout[name]
        base = len(scene.v)
        scene.v += [(x + dx, y + dy, z + dz) for x, y, z in o.v]; scene.vt += o.vt; scene.vn += o.vn
        for pname, faces in o.objects:
            scene.objects.append((f"{name}_{pname}", [(a + base, b + base, c + base) for a, b, c in faces]))
    scene.write(OUT / "_rocks_scene.obj", "rocks_texture.png")
    write_preview((OUT / "_rocks_scene.obj").read_text(encoding="utf-8"), OUT / "rocks_texture.png", "preview_rocks.html", (30, 22, 42), (-2, 5, -4))
    print(f"total {total} triangles; mars_environment.lua and preview_rocks.html written")
