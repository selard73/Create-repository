"""
Cartoon satellite dish on a round bunker, in old rusty red metal. Roblox Import 3D mesh.

Outputs: dish.obj / dish.mtl / dish_texture.png / dish_setup.lua / preview_dish.html
Run:  python gen_dish.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from gen_mesh import add, sub, mul, dot, cross, length, norm, lathe, blob, grain, paint_gradient
from gen_sign import Obj, tube, extrude_shape, box, rounded_rect, write_preview as _wp

OUT = Path(__file__).parent
TEX = 1024
random.seed(3)

UV = {
    "dish":    (0.00, 0.50, 0.50, 1.00),   # dish front, u = angle, v = centre->rim
    "base":    (0.50, 1.00, 0.50, 1.00),   # bunker wall, u = angle, v = height
    "rust":    (0.00, 0.25, 0.25, 0.50),   # plain rusty metal
    "rustdk":  (0.25, 0.50, 0.25, 0.50),   # darker rust (undersides, back of dish)
    "steel":   (0.50, 0.75, 0.25, 0.50),   # grey steel trims
    "dark":    (0.75, 1.00, 0.25, 0.50),
    "lime":    (0.00, 0.10, 0.00, 0.10),
    "orange":  (0.10, 0.20, 0.00, 0.10),
    "green":   (0.20, 0.30, 0.00, 0.10),
    "cyan":    (0.30, 0.40, 0.00, 0.10),
    "glass":   (0.40, 0.50, 0.00, 0.10),
    "red":     (0.50, 0.60, 0.00, 0.10),
    "yellow":  (0.60, 0.70, 0.00, 0.10),
    "magenta": (0.70, 0.80, 0.00, 0.10),
}

# ------------------------------------------------------------ helpers -----
def revolve(profile, segs, uv, axis_center=(0, 0, 0), vmode="index"):
    """Revolve a (r, y) profile around the Y axis. Rings are stitched in order;
    r == 0 makes a degenerate ring (pole)."""
    u0, u1, v0, v1 = uv
    cum = [0.0]
    for i in range(1, len(profile)):
        cum.append(cum[-1] + math.hypot(profile[i][0] - profile[i - 1][0], profile[i][1] - profile[i - 1][1]))
    total = cum[-1] or 1
    rings = []
    for i, (r, y) in enumerate(profile):
        v = v0 + (v1 - v0) * (cum[i] / total)
        pts, uvs = [], []
        for j in range(segs + 1):
            th = 2 * math.pi * j / segs
            pts.append((axis_center[0] + r * math.cos(th), axis_center[1] + y, axis_center[2] + r * math.sin(th)))
            uvs.append((u0 + (u1 - u0) * j / segs, v))
        rings.append((pts, uvs, abs(r) < 1e-6))
    return lathe(rings)

def rot_x(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0], p[1] * c - p[2] * s, p[1] * s + p[2] * c)

def rot_y(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c + p[2] * s, p[1], -p[0] * s + p[2] * c)

def xform(verts, tilt, yaw, offset):
    return [add(rot_y(rot_x(p, tilt), yaw), offset) for p in verts]

# --------------------------------------------------------------- build ----
DISH_R, DISH_DEPTH = 4.6, 1.5
TILT, YAW = math.radians(38), math.radians(25)      # dish opens up and toward the viewer-left
MAST_TOP = 9.3
PIVOT = (0.0, MAST_TOP + 0.6, 0.0)

def build():
    o = Obj()

    # --- bunker: revolved wall with a lip, a top plate and a shallow dome
    wall = [(4.3, 0.0), (4.3, 0.35), (4.05, 0.5), (4.05, 3.9), (4.35, 4.0), (4.35, 4.5), (4.0, 4.6),
            (3.4, 4.75), (2.4, 5.05), (1.3, 5.2), (0.0, 5.25)]
    v, uv, f = revolve(wall, 48, UV["base"])
    o.add_smooth("Bunker", v, uv, f, lambda p: (0.0, min(p[1], 2.5), 0.0))
    # base ring plate on the ground
    v, uv, f = revolve([(0.0, 0.0), (5.0, 0.0), (5.0, 0.22), (4.3, 0.28)], 48, UV["steel"])
    o.add_smooth("GroundRing", v, uv, f, lambda p: (0.0, -1.0, 0.0))
    # rivet rows on the lip and base band
    for i in range(16):
        a = 2 * math.pi * i / 16
        for (r, y) in ((4.37, 4.25), (4.32, 0.18)):
            c = (r * math.cos(a), y, r * math.sin(a))
            v, uv, f = blob(c, (0.13, 0.13, 0.13), 8, 4, UV["steel"])
            o.add_smooth(f"Rivet{i}_{int(y)}", v, uv, f, lambda p, c=c: (0.0, c[1], 0.0))

    # --- door on the front: dark frame box + glowing lime panel + steel step
    o.add_flat("DoorFrame", box(0.0, 1.9, 3.95, 2.2, 3.4, 0.5, UV["dark"]), (0.0, 1.9, 0.0))
    o.add_flat("NeonLime_Door", box(0.0, 1.9, 4.16, 1.6, 2.8, 0.14, UV["lime"]), (0.0, 1.9, 0.0))
    o.add_flat("DoorStep", box(0.0, 0.15, 4.5, 2.4, 0.3, 0.9, UV["steel"]), (0.0, -1.0, 0.0))
    # round coloured lights: a control panel with a 3x2 grid, plus lamps scattered around the wall
    def round_light(o, angle, y, col, i, r_wall=4.05, size=1.0):
        d = (math.sin(angle), 0.0, math.cos(angle))
        base = (r_wall * d[0], y, r_wall * d[2])
        bez = revolve([(0.0, 0.0), (0.36 * size, 0.0), (0.36 * size, 0.1), (0.27 * size, 0.13)], 14, UV["dark"])
        lamp = revolve([(0.0, 0.06), (0.25 * size, 0.06), (0.25 * size, 0.18), (0.17 * size, 0.3), (0.0, 0.36)], 14, UV[col])
        for name, (v, uv, f) in ((f"Bezel{i}", bez), (f"Neon{col.capitalize()}_Lamp{i}", lamp)):
            v = [add(rot_y(rot_x(p, math.pi / 2), angle), base) for p in v]
            o.add_smooth(name, v, uv, f, lambda p, c=base: (0.0, c[1], 0.0))
    pa = math.radians(-38)
    pd = (math.sin(pa), 0.0, math.cos(pa))
    pc = (4.0 * pd[0], 2.1, 4.0 * pd[2])
    panel = box(0.0, 0.0, 0.0, 1.9, 0.8, 0.3, UV["dark"])
    panel = [tuple((add(rot_y(rot_x(p, 0.0), pa), pc), t) for p, t in tri) for tri in panel]
    o.add_flat("ControlPanel", panel, (0.0, 2.1, 0.0))
    for k, col in enumerate(("red", "yellow", "green")):
        round_light(o, pa + (k - 1) * 0.55 / 4.0, 2.1, col, k, r_wall=4.12, size=0.7)
    rnd = random.Random(21)
    scatter = [("orange", 60), ("red", 105), ("green", 150), ("cyan", 200), ("orange", 245), ("red", 290), ("green", 330)]
    for k, (col, deg) in enumerate(scatter):
        round_light(o, math.radians(deg), rnd.uniform(0.9, 3.5), col, 10 + k)
    # a pipe running up the right side
    pipe = [(3.2, 0.3, 2.9), (3.2, 3.2, 2.9), (2.9, 3.9, 2.6), (2.2, 4.9, 2.0)]
    v, uv, f = tube(pipe, 0.18, 8, UV["rust"])
    o.add_smooth("Pipe", v, uv, f, lambda p: (0.0, p[1], 0.0))

    # --- stylised roof: rim ring, stepped drum with seams, bolts, hatch, vent box, cable, antenna
    rimring = [(4.25 * math.cos(2 * math.pi * i / 56), 4.62, 4.25 * math.sin(2 * math.pi * i / 56)) for i in range(56)]
    v, uv, f = tube(rimring, 0.2, 8, UV["steel"], closed=True)
    o.add_smooth("RoofRim", v, uv, f, lambda p: (0.0, 4.62, 0.0))
    v, uv, f = revolve([(0.0, 5.0), (2.9, 5.0), (2.9, 5.25), (2.7, 5.35), (2.7, 6.0), (2.3, 6.15), (0.0, 6.15)], 40, UV["base"])
    o.add_smooth("RoofDrum", v, uv, f, lambda p: (0.0, 5.5, 0.0))
    drumring = [(2.75 * math.cos(2 * math.pi * i / 40), 5.32, 2.75 * math.sin(2 * math.pi * i / 40)) for i in range(40)]
    v, uv, f = tube(drumring, 0.11, 6, UV["dark"], closed=True)
    o.add_smooth("DrumSeam", v, uv, f, lambda p: (0.0, 5.32, 0.0))
    for i in range(10):
        a2 = 2 * math.pi * i / 10 + 0.3
        c = (2.72 * math.cos(a2), 5.75, 2.72 * math.sin(a2))
        v, uv, f = blob(c, (0.16, 0.16, 0.16), 8, 4, UV["dark"])
        o.add_smooth(f"DrumBolt{i}", v, uv, f, lambda p, c=c: (0.0, c[1], 0.0))
    # round hatch on the roof, front-left, with a handle
    ha = math.radians(-60); hr = 3.4
    hc = (hr * math.sin(ha), 4.95, hr * math.cos(ha))
    v, uv, f = revolve([(0.0, 0.0), (0.75, 0.0), (0.75, 0.16), (0.62, 0.22), (0.0, 0.26)], 20, UV["steel"])
    o.add_smooth("Hatch", [add(p, hc) for p in v], uv, f, lambda p: (hc[0], 4.5, hc[2]))
    v, uv, f = tube([add(hc, (-0.3, 0.26, 0.0)), add(hc, (-0.3, 0.5, 0.0)), add(hc, (0.3, 0.5, 0.0)), add(hc, (0.3, 0.26, 0.0))], 0.06, 6, UV["dark"])
    o.add_smooth("HatchHandle", v, uv, f, lambda p: add(hc, (0.0, 0.2, 0.0)))
    # vent box at the back-right with slats
    va = math.radians(130); vc = (3.1 * math.sin(va), 5.05, 3.1 * math.cos(va))
    vb = box(0.0, 0.0, 0.0, 1.3, 0.7, 0.9, UV["steel"])
    vb = [tuple((add(rot_y(p, va), vc), t) for p, t in tri) for tri in vb]
    o.add_flat("VentBox", vb, (vc[0], 4.5, vc[2]))
    for k in range(4):
        sl = box(0.0, -0.22 + k * 0.15, 0.46, 1.0, 0.06, 0.06, UV["dark"])
        sl = [tuple((add(rot_y(p, va), vc), t) for p, t in tri) for tri in sl]
        o.add_flat(f"VentSlat{k}", sl, (vc[0], vc[1], vc[2]))
    # small antenna on the roof with a red lamp
    ac = (-2.2, 4.95, -2.4)
    v, uv, f = tube([ac, add(ac, (0.0, 2.2, 0.0))], 0.07, 6, UV["steel"])
    o.add_smooth("Antenna", v, uv, f, lambda p: add(ac, (0.0, 1.0, 0.0)))
    tipc = add(ac, (0.0, 2.35, 0.0))
    v, uv, f = blob(tipc, (0.2, 0.2, 0.2), 10, 5, UV["red"])
    o.add_smooth("NeonRed_AntennaLamp", v, uv, f, lambda p: tipc)
    # cable from the joint down over the roof edge and along the wall to the control panel
    cable = [(0.6, MAST_TOP + 0.2, 0.3), (1.6, 7.6, 1.2), (2.4, 6.2, 2.0), (3.0, 5.2, 2.6), (3.6, 4.7, 2.2), (4.15, 3.9, 1.6), (4.15, 2.9, 0.4), (4.05, 2.6, -1.0)]
    v, uv, f = tube(cable, 0.1, 6, UV["dark"])
    o.add_smooth("Cable", v, uv, f, lambda p: (0.0, p[1] - 0.5, 0.0))
    # a second small box with a lime lamp near the roof edge, front-right
    ba = math.radians(35); bc = (3.35 * math.sin(ba), 5.0, 3.35 * math.cos(ba))
    bb = box(0.0, 0.0, 0.0, 0.8, 0.6, 0.6, UV["dark"])
    bb = [tuple((add(rot_y(p, ba), bc), t) for p, t in tri) for tri in bb]
    o.add_flat("RoofBox", bb, (bc[0], 4.5, bc[2]))
    lc = add(bc, (0.0, 0.42, 0.0))
    v, uv, f = blob(lc, (0.18, 0.18, 0.18), 10, 5, UV["lime"])
    o.add_smooth("NeonLime_RoofLamp", v, uv, f, lambda p: lc)

    # --- pedestal, mast and rings
    v, uv, f = revolve([(0.0, 6.1), (1.15, 6.1), (1.15, 6.45), (0.85, 6.6), (0.85, 6.95), (0.0, 6.95)], 32, UV["rust"])
    o.add_smooth("Pedestal", v, uv, f, lambda p: (0.0, 6.5, 0.0))
    v, uv, f = revolve([(0.0, 6.9), (0.36, 6.9), (0.36, MAST_TOP), (0.0, MAST_TOP)], 24, UV["rust"])
    o.add_smooth("Mast", v, uv, f, lambda p: (0.0, p[1], 0.0))
    for i, y in enumerate((7.5, 8.6)):
        v, uv, f = revolve([(0.0, y - 0.14), (0.56, y - 0.14), (0.56, y + 0.14), (0.0, y + 0.14)], 24, UV["steel"])
        o.add_smooth(f"MastRing{i}", v, uv, f, lambda p, y=y: (0.0, y, 0.0))
    v, uv, f = blob(PIVOT, (0.62, 0.62, 0.62), 20, 10, UV["rustdk"])
    o.add_smooth("Joint", v, uv, f, lambda p: PIVOT)

    # --- dish: paraboloid with thickness, tilted. Built around the origin then moved.
    N = 14
    front = [((DISH_R * i / N), DISH_DEPTH * (i / N) ** 2) for i in range(N + 1)]            # centre -> rim
    back = [(r * 0.985, y - 0.22 - 0.12 * (1 - r / DISH_R)) for r, y in reversed(front)]      # rim -> centre, underneath
    profile = front + [(DISH_R + 0.05, DISH_DEPTH + 0.05), (DISH_R + 0.05, DISH_DEPTH - 0.15)] + back
    v, uv, f = revolve(profile, 56, UV["dish"])
    dish_offset = add(PIVOT, rot_y(rot_x((0.0, 0.9, 0.0), TILT), YAW))
    v = xform(v, TILT, YAW, dish_offset)
    axis = norm(rot_y(rot_x((0.0, 1.0, 0.0), TILT), YAW))
    o.add_smooth("Dish", v, uv, f, lambda p: add(dish_offset, mul(axis, -2.0)))
    # rim ring
    ring = [(DISH_R * math.cos(2 * math.pi * i / 56), DISH_DEPTH, DISH_R * math.sin(2 * math.pi * i / 56)) for i in range(56)]
    v, uv, f = tube(xform(ring, TILT, YAW, dish_offset), 0.16, 8, UV["rust"], closed=True)
    o.add_smooth("DishRim", v, uv, f, lambda p: add(dish_offset, mul(axis, DISH_DEPTH)))
    # radial ribs on the back of the dish
    for i in range(8):
        a = 2 * math.pi * i / 8
        rib = [((DISH_R * t) * math.cos(a), DISH_DEPTH * t * t - 0.3, (DISH_R * t) * math.sin(a)) for t in (0.15, 0.4, 0.65, 0.9, 1.0)]
        v, uv, f = tube(xform(rib, TILT, YAW, dish_offset), 0.09, 6, UV["rustdk"])
        o.add_smooth(f"DishRib{i}", v, uv, f, lambda p: add(dish_offset, mul(axis, 0.5)))
    # hub, feed rod, green glowing tip and three struts
    hub = xform([(0.0, 0.1, 0.0)], TILT, YAW, dish_offset)[0]
    v, uv, f = blob(hub, (0.5, 0.35, 0.5), 14, 6, UV["steel"])
    o.add_smooth("Hub", v, uv, f, lambda p: hub)
    tip_local = (0.0, 4.2, 0.0)
    rod = xform([(0.0, 0.1, 0.0), tip_local], TILT, YAW, dish_offset)
    v, uv, f = tube(rod, 0.13, 8, UV["rust"])
    o.add_smooth("FeedRod", v, uv, f, lambda p: add(dish_offset, mul(axis, 2.0)))
    tip = rod[-1]
    v, uv, f = blob(tip, (0.42, 0.42, 0.42), 14, 7, UV["yellow"])
    o.add_smooth("NeonYellow_FeedTip", v, uv, f, lambda p: tip)
    for i in range(3):
        a = 2 * math.pi * i / 3 + 0.5
        strut = xform([(DISH_R * 0.82 * math.cos(a), DISH_DEPTH * 0.67, DISH_R * 0.82 * math.sin(a)), (0.0, 3.4, 0.0)], TILT, YAW, dish_offset)
        v, uv, f = tube(strut, 0.06, 6, UV["steel"])
        o.add_smooth(f"Strut{i}", v, uv, f, lambda p: add(dish_offset, mul(axis, 1.5)))
    # counterweight box behind the pivot
    cw = xform([(0.0, -1.3, 0.0)], TILT, YAW, PIVOT)[0]
    v, uv, f = blob(cw, (0.5, 0.65, 0.5), 12, 6, UV["rustdk"])
    o.add_smooth("Counterweight", v, uv, f, lambda p: cw)
    return o

# ------------------------------------------------------------- texture ----
def rbox(r):
    u0, u1, v0, v1 = r
    return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)

def rust(w, h, base=(138, 138, 146), seed=1, rust_amount=0.35):
    """Cartoon worn metal: smooth grey with a soft gradient, a few big soft rust patches near
    the bottom, and no fine noise. Panel lines and rivets are drawn by the callers."""
    rnd = random.Random(seed)
    img = grain(paint_gradient(w, h, tuple(min(255, c + 18) for c in base), tuple(max(0, c - 22) for c in base)), 0.04, 30).convert("RGBA")
    blot = Image.new("RGBA", (w, h), (0, 0, 0, 0)); bd = ImageDraw.Draw(blot)
    n = int(w * h / 14000 * rust_amount * 4)
    for _ in range(n):
        x, y = rnd.randint(0, w), rnd.randint(int(h * 0.35), h)
        r = rnd.randint(int(w * 0.04), int(w * 0.12))
        col = rnd.choice(((150, 82, 52, 120), (128, 66, 44, 130), (168, 100, 62, 100)))
        bd.ellipse([x - r, y - r * 0.55, x + r, y + r * 0.55], fill=col)
    blot = blot.filter(ImageFilter.GaussianBlur(w / 60))
    img.alpha_composite(blot)
    d = ImageDraw.Draw(img)
    for _ in range(int(w / 40)):   # a few soft drips
        x, y = rnd.randint(0, w), rnd.randint(int(h * 0.3), h)
        d.line([(x, y), (x, y + rnd.randint(20, 70))], fill=(120, 62, 40, 70), width=rnd.randint(3, 6))
    return img

def paint():
    atlas = Image.new("RGB", (TEX, TEX), (30, 30, 30))

    # dish: rust with radial panel seams and two concentric rings
    x0, y0, x1, y1 = rbox(UV["dish"]); w, h = x1 - x0, y1 - y0
    d_img = rust(w, h, seed=2, rust_amount=0.4); d = ImageDraw.Draw(d_img)
    for k in range(12):
        x = int(w * k / 12); d.line([(x, 0), (x, h)], fill=(58, 58, 66, 235), width=5)
        d.line([(x + 5, 0), (x + 5, h)], fill=(200, 200, 210, 60), width=3)
    for fy in (0.42, 0.75):
        d.line([(0, int(h * fy)), (w, int(h * fy))], fill=(58, 58, 66, 235), width=5)
    # the far edge of the region is the rim (v=1 at the top of the image is the centre in our profile? centre->rim maps v0->v1)
    atlas.paste(d_img.convert("RGB"), (x0, y0))

    # bunker wall: rust with vertical panel seams, rivets, a steel band near the top and bottom
    x0, y0, x1, y1 = rbox(UV["base"]); w, h = x1 - x0, y1 - y0
    b = rust(w, h, base=(124, 124, 130), seed=5, rust_amount=0.5); d = ImageDraw.Draw(b)
    for k in range(8):
        x = int(w * k / 8); d.line([(x, 0), (x, h)], fill=(58, 58, 66, 235), width=6)
        d.line([(x + 6, 0), (x + 6, h)], fill=(205, 205, 214, 55), width=3)
        for fy in (0.25, 0.5, 0.75):
            for rx in (x + 16, x - 16):
                d.ellipse([rx - 7, int(h * fy) - 7, rx + 7, int(h * fy) + 7], fill=(72, 72, 80, 255))
                d.ellipse([rx - 4, int(h * fy) - 5, rx + 3, int(h * fy) + 2], fill=(150, 150, 160, 255))
    # v runs bottom(0)->top(1) of the wall: bands at the base and the lip
    d.rectangle([0, int(h * 0.90), w, h], fill=(96, 96, 104, 255))
    d.rectangle([0, 0, w, int(h * 0.08)], fill=(110, 110, 118, 255))
    d.line([(0, int(h * 0.90)), (w, int(h * 0.90))], fill=(40, 40, 44, 255), width=3)
    atlas.paste(b.convert("RGB"), (x0, y0))

    x0, y0, x1, y1 = rbox(UV["rust"]); atlas.paste(rust(x1 - x0, y1 - y0, seed=7, rust_amount=0.45).convert("RGB"), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["rustdk"]); atlas.paste(rust(x1 - x0, y1 - y0, base=(104, 102, 108), seed=9, rust_amount=0.7).convert("RGB"), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["steel"]); atlas.paste(grain(paint_gradient(x1 - x0, y1 - y0, (128, 130, 138), (84, 86, 94)), 0.18, 40), (x0, y0))
    x0, y0, x1, y1 = rbox(UV["dark"]); atlas.paste(grain(Image.new("RGB", (x1 - x0, y1 - y0), (38, 36, 40)), 0.15, 40), (x0, y0))
    for key, col in (("lime", (205, 255, 70)), ("orange", (255, 150, 50)), ("green", (100, 255, 110)), ("cyan", (90, 230, 255)), ("glass", (140, 200, 220)), ("red", (255, 70, 60)), ("yellow", (255, 225, 70)), ("magenta", (255, 90, 220))):
        x0, y0, x1, y1 = rbox(UV[key]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), col), (x0, y0))
    return atlas

LUA = r'''-- Satellite dish: run in the Command Bar with the imported model SELECTED (or it finds it in Workspace).
-- Body stays matte dull metal. Only the round lamps glow, blink (while the game runs) and cast light; the doorway casts lime light.
local model = workspace:FindFirstChild("SatelliteDish") or workspace:FindFirstChild("dish") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the dish model first")
local colors = { Lime = Color3.fromRGB(205, 255, 70), Orange = Color3.fromRGB(255, 150, 50), Green = Color3.fromRGB(100, 255, 110), Cyan = Color3.fromRGB(90, 230, 255), Red = Color3.fromRGB(255, 70, 60), Yellow = Color3.fromRGB(255, 225, 70), Magenta = Color3.fromRGB(255, 90, 220) }
local door
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Light") then c:Destroy() end end
		local tone = p.Name:match("^Neon(%a+)_")
		if tone and colors[tone] then
			p.Material = Enum.Material.Neon; p.Color = colors[tone]; p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
			if p.Name:find("Lamp") then
				local l = Instance.new("PointLight"); l.Color = colors[tone]; l.Range = 5; l.Brightness = 1; l.Shadows = false; l.Parent = p
			end
		else
			p.Material = Enum.Material.SmoothPlastic
		end
		if p.Name == "NeonLime_Door" then door = p end
	end
end
if door then
	local l = Instance.new("PointLight"); l.Color = colors.Lime; l.Range = 12; l.Brightness = 2; l.Shadows = false; l.Parent = door
	local sp = Instance.new("SpotLight"); sp.Color = colors.Lime; sp.Range = 16; sp.Brightness = 2.5; sp.Angle = 110; sp.Face = Enum.NormalId.Front; sp.Shadows = true; sp.Parent = door
	local sp2 = sp:Clone(); sp2.Face = Enum.NormalId.Back; sp2.Parent = door
end
local oldScript = model:FindFirstChild("LampBlinker"); if oldScript then oldScript:Destroy() end
local blinker = Instance.new("Script"); blinker.Name = "LampBlinker"
blinker.Source = [[
local model = script.Parent
local rng = Random.new()
for _, lamp in ipairs(model:GetDescendants()) do
	if lamp:IsA("BasePart") and lamp.Name:find("Lamp") then
		task.spawn(function()
			local onColor = lamp.Color
			local offColor = onColor:Lerp(Color3.new(0, 0, 0), 0.7)
			local light = lamp:FindFirstChildOfClass("PointLight")
			local period = rng:NextNumber(0.6, 2.2)
			task.wait(rng:NextNumber(0, 2))
			while lamp.Parent do
				lamp.Material = Enum.Material.SmoothPlastic; lamp.Color = offColor
				if light then light.Enabled = false end
				task.wait(period * rng:NextNumber(0.3, 0.7))
				lamp.Material = Enum.Material.Neon; lamp.Color = onColor
				if light then light.Enabled = true end
				task.wait(period * rng:NextNumber(0.6, 1.4))
			end
		end)
	end
end
]]
blinker.Parent = model
model.Name = "SatelliteDish"
print("Satellite dish: matte metal, blinking lamps, door light")
'''

def write_preview(obj_text, png_path, out_name, cam, look):
    _wp(obj_text, png_path, out_name, cam, look)
    p = OUT / out_name; h = p.read_text(encoding="utf-8")
    h = h.replace("new THREE.MeshStandardMaterial({map:tex,roughness:0.8,metalness:0.05})", "new THREE.MeshStandardMaterial({map:tex,roughness:0.55,metalness:0.45})")
    h = h.replace("const pink=new THREE.PointLight(0xff50d0,1.6,18)", "const pink=new THREE.PointLight(0xfff0e0,0.6,30)")
    h = h.replace("const cyan=new THREE.PointLight(0x50e8ff,1.4,12)", "const cyan=new THREE.PointLight(0xe0f0ff,0.4,30)")
    h = h.replace("scene.background=new THREE.Color(0x2a1f3d)", "scene.background=new THREE.Color(0x87a8c8)")
    h = h.replace("new THREE.HemisphereLight(0xffd8c0,0x6a3a28,0.6)", "new THREE.HemisphereLight(0xdfe8ff,0x8a5a3a,0.9)")
    h = h.replace("new THREE.DirectionalLight(0xffc090,0.9)", "new THREE.DirectionalLight(0xfff2dc,1.4)")
    p.write_text(h, encoding="utf-8")

if __name__ == "__main__":
    o = build()
    tris = o.write(OUT / "dish.obj", "dish_texture.png")
    paint().save(OUT / "dish_texture.png")
    (OUT / "dish_setup.lua").write_text(LUA, encoding="utf-8")
    write_preview((OUT / "dish.obj").read_text(encoding="utf-8"), OUT / "dish_texture.png", "preview_dish.html", (17, 13, 25), (0, 7, 0))
    print(f"dish.obj: {len(o.v)} verts, {tris} triangles, {len(o.objects)} objects")
