"""Cafe v3: one continuous Parisian cafe interior across the whole window (zinc bar, brass rail, stools, mirrored
back bar with 14 bottles = the only random parts, marble bistro tables with bentwood chairs, coat stand, chalkboard,
globe lamps, checkerboard floor). Chalkboard prop fixed: hinged at the top, chalk on the outside faces."""
from pathlib import Path
import re
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
d0 = s.index("def disp_cafe(name, seed):"); d1 = s.index("def _hat_g(")
assert d0 < d1
new = r'''def disp_cafe(name, seed):
    """Parisian cafe interior built once across the whole window (26 wide)."""
    rnd = random.Random(seed); o = Obj()
    W, D = 26.0, 4.5
    zf, zb = -D / 2, D / 2
    tt, po, ch, br, tr, st, ln = [], [], [], [], [], [], []
    # floor: cream slab with dark checker squares
    box(o, "Trim", (0, 0.04, 0), W, 0.08, D, tris_out=tt)
    for i in range(int(W)):
        for j in range(int(D)):
            if (i + j) % 2 == 0: box(o, "Post", (-W / 2 + 0.5 + i, 0.09, zf + 0.5 + j), 0.96, 0.02, 0.96, tris_out=po)
    # marble bistro tables along the glass, a bentwood chair either side
    def table(x, z):
        tube(o, "Trim", [ring((x, 0, z), 0.75, 2.15, 14), ring((x, 0, z), 0.75, 2.3, 14)], (x, 2.22, z), cap_top=True, cap_bottom=True, tris_out=tt)
        tube(o, "Post", [ring((x, 0, z), 0.1, 0.1, 6), ring((x, 0, z), 0.1, 2.15, 6)], (x, 1.1, z), tris_out=po)
        tube(o, "Post", [ring((x, 0, z), 0.5, 0.08, 10), ring((x, 0, z), 0.5, 0.18, 10)], (x, 0.13, z), cap_top=True, cap_bottom=True, tris_out=po)
        for sgn in (-1, 1):
            cx = x + sgn * 1.3
            box(o, "Chair", (cx, 1.3, z), 0.95, 0.1, 0.95, tris_out=ch)
            box(o, "Chair", (cx + sgn * 0.45, 2.05, z), 0.1, 1.5, 0.95, tris_out=ch)
            box(o, "Chair", (cx + sgn * 0.45, 2.6, z), 0.1, 0.1, 0.95, tris_out=ch)
            for dx in (-0.4, 0.4):
                for dz in (-0.4, 0.4): box(o, "Chair", (cx + dx, 0.65, z + dz), 0.08, 1.3, 0.08, tris_out=ch)
        tube(o, "Trim", [ring((x + 0.25, 0, z - 0.15), 0.14, 2.3, 8), ring((x + 0.25, 0, z - 0.15), 0.16, 2.55, 8)], (x + 0.25, 2.42, z - 0.15), cap_top=True, tris_out=tt)
    for x in (-10.0, -5.0, 0.0, 5.0, 10.0): table(x, zf + 1.3)
    # the zinc bar along the back with a brass foot rail and stools
    box(o, "Trunk", (0, 1.4, zb - 0.95), W - 2.0, 2.8, 1.5, tris_out=tr)
    box(o, "Stone", (0, 2.88, zb - 0.95), W - 1.6, 0.16, 1.8, tris_out=st)
    box(o, "Brass", (0, 0.45, zb - 1.9), W - 2.4, 0.08, 0.08, tris_out=br)
    for xx in range(-11, 12, 4): box(o, "Brass", (xx, 1.45, zb - 1.72), 1.6, 1.9, 0.03, tris_out=br)
    for xx in (-7.5, -2.5, 2.5, 7.5):
        tube(o, "Post", [ring((xx, 0, zb - 2.6), 0.06, 0.1, 6), ring((xx, 0, zb - 2.6), 0.06, 2.1, 6)], (xx, 1.1, zb - 2.6), tris_out=po)
        tube(o, "Post", [ring((xx, 0, zb - 2.6), 0.4, 0.05, 10), ring((xx, 0, zb - 2.6), 0.4, 0.12, 10)], (xx, 0.08, zb - 2.6), cap_top=True, cap_bottom=True, tris_out=po)
        tube(o, "Chair", [ring((xx, 0, zb - 2.6), 0.42, 2.1, 10), ring((xx, 0, zb - 2.6), 0.42, 2.3, 10)], (xx, 2.2, zb - 2.6), cap_top=True, cap_bottom=True, tris_out=ch)
    # mirrored back bar with shelves of bottles and glasses
    box(o, "Trunk", (0, 5.3, zb - 0.1), W - 2.0, 4.4, 0.2, tris_out=tr)
    for xx in (-9.0, 0.0, 9.0):
        box(o, "Brass", (xx, 5.5, zb - 0.22), 6.6, 3.6, 0.04, tris_out=br)
        box(o, "Trim", (xx, 5.5, zb - 0.25), 6.3, 3.3, 0.04, tris_out=tt)
    for y in (3.3, 4.6, 5.9): box(o, "Trunk", (0, y, zb - 0.5), W - 2.4, 0.08, 0.7, tris_out=tr)
    k = 0
    for (xx, y) in ((-10.5, 3.3), (-8.5, 3.3), (-6.5, 3.3), (-3.5, 3.3), (-1.5, 3.3), (0.5, 3.3), (3.0, 3.3), (5.0, 3.3), (7.5, 3.3), (9.5, 3.3),
                    (-9.5, 4.6), (-5.0, 4.6), (2.0, 4.6), (8.5, 4.6)):
        k += 1
        tube(o, f"Bottle{k}", [ring((xx, 0, zb - 0.5), 0.2, y + 0.05, 8), ring((xx, 0, zb - 0.5), 0.2, y + 0.85, 8), ring((xx, 0, zb - 0.5), 0.08, y + 1.05, 8), ring((xx, 0, zb - 0.5), 0.08, y + 1.3, 8)], (xx, y + 0.6, zb - 0.5), cap_bottom=True, cap_top=True)
    assert k == 14, k
    for xx in (-7.0, 0.0, 6.0):
        for i in range(4): tube(o, "Trim", [ring((xx + 0.45 * i, 0, zb - 0.5), 0.14, 4.65, 8), ring((xx + 0.45 * i, 0, zb - 0.5), 0.16, 5.0, 8)], (xx + 0.45 * i, 4.8, zb - 0.5), cap_top=True, tris_out=tt)
    # espresso machine (right), cups, cake under a dome (left)
    box(o, "Trim", (6.5, 3.65, zb - 0.9), 2.0, 1.5, 1.1, tris_out=tt)
    box(o, "Post", (6.5, 3.65, zb - 1.47), 2.0, 1.5, 0.06, tris_out=po)
    box(o, "Trim", (6.5, 4.48, zb - 0.9), 2.1, 0.14, 1.2, tris_out=tt)
    for dx in (-0.55, 0.55): box(o, "Brass", (6.5 + dx, 3.15, zb - 1.55), 0.12, 0.5, 0.2, tris_out=br)
    box(o, "Brass", (7.65, 4.0, zb - 1.2), 0.1, 0.8, 0.1, tris_out=br)
    for i in range(5): tube(o, "Trim", [ring((5.8 + 0.35 * i, 0, zb - 0.9), 0.15, 4.56, 8), ring((5.8 + 0.35 * i, 0, zb - 0.9), 0.17, 4.86, 8)], (5.8 + 0.35 * i, 4.7, zb - 0.9), cap_top=True, tris_out=tt)
    ct = []
    tube(o, "Trim", [ring((-6.5, 0, zb - 1.0), 0.8, 2.96, 12), ring((-6.5, 0, zb - 1.0), 0.8, 3.06, 12)], (-6.5, 3.0, zb - 1.0), cap_top=True, cap_bottom=True, tris_out=tt)
    tube(o, "Cake", [ring((-6.5, 0, zb - 1.0), 0.6, 3.06, 12), ring((-6.5, 0, zb - 1.0), 0.6, 3.7, 12)], (-6.5, 3.4, zb - 1.0), cap_top=True, tris_out=ct)
    o.add_flat("Cake", ct)
    dt = []
    icoblob(o, "GlassDoor", (-6.5, 3.75, zb - 1.0), 1.05, rnd, 0.02, (1.0, 0.85, 1.0), tris_out=dt)
    o.add_flat("GlassDoor", dt)
    # coat stand at the left end, chalkboard menu on the right end wall
    tube(o, "Post", [ring((-12.2, 0, zf + 2.0), 0.5, 0, 8), ring((-12.2, 0, zf + 2.0), 0.5, 0.1, 8)], (-12.2, 0.05, zf + 2.0), cap_top=True, cap_bottom=True, tris_out=po)
    tube(o, "Post", [ring((-12.2, 0, zf + 2.0), 0.07, 0.1, 6), ring((-12.2, 0, zf + 2.0), 0.07, 5.6, 6)], (-12.2, 2.8, zf + 2.0), tris_out=po)
    box(o, "Post", (-12.2, 5.35, zf + 2.0), 0.7, 0.08, 0.08, tris_out=po); box(o, "Post", (-12.2, 5.35, zf + 2.0), 0.08, 0.08, 0.7, tris_out=po)
    box(o, "Trim", (12.3, 4.6, zf + 2.2), 0.14, 2.4, 3.4, tris_out=tt)
    box(o, "Sign", (12.2, 4.6, zf + 2.2), 0.08, 2.1, 3.1)
    for i in range(4): box(o, "Trim", (12.15, 5.3 - 0.4 * i, zf + 2.1 - 0.1 * (i % 2)), 0.02, 0.07, 2.0 - 0.5 * (i % 3), tris_out=tt)
    # globe lamps
    for xx in (-9.0, -3.0, 3.0, 9.0):
        box(o, "Post", (xx, 7.2, zf + 2.0), 0.05, 1.6, 0.05, tris_out=po)
        icoblob(o, "Lantern", (xx, 6.0, zf + 2.0), 0.55, rnd, 0.02, tris_out=ln)
    o.add_flat("Trim", tt); o.add_flat("Post", po); o.add_flat("Chair", ch); o.add_flat("Brass", br)
    o.add_flat("Trunk", tr); o.add_flat("Stone", st); o.add_flat("Lantern", ln)
    return o.write(OUT / f"{name}.obj")

'''
s = s[:d0] + new + s[d1:]
# chalkboard: hinged at the top, chalk faces outward
c0 = s.index("def chalkboard(name, seed):"); c1 = s.index("def disp_hats(name, seed):")
assert c0 < c1
s = s[:c0] + r'''def chalkboard(name, seed):
    """A-frame chalk menu board for the pavement outside the cafe: two boards hinged at the top, feet apart,
    chalk faces on the OUTSIDE, about 3.6 studs tall."""
    o = Obj(); tt = []
    for sgn in (-1, 1):
        g = _Group()
        g.box("Plank", (0, 1.8, 0), 2.4, 3.6, 0.1)
        g.box("Sign", (0, 1.75, sgn * 0.07), 2.0, 2.8, 0.04)                                     # chalk face on the outer side
        for i in range(5): g.box("Trim", (-0.15 + 0.1 * (i % 2), 2.8 - 0.42 * i, sgn * 0.1), 1.3 - 0.35 * (i % 3), 0.06, 0.02)
        g.emit(o, (0, 3.6, 0), -sgn * math.radians(12))                                        # rotate about the top hinge
    box(o, "Post", (0, 3.62, 0), 2.5, 0.12, 0.3, tris_out=tt)
    o.add_flat("Post", tt)
    return o.write(OUT / f"{name}.obj")

''' + s[c1:]
p.write_text(s, encoding="utf-8")
# builder: kits wider than 8 studs are placed once per window
p = Path(__file__).parent / "make_village_scripts.py"
s = p.read_text(encoding="utf-8")
old = '''					local n = math.max(1, math.floor(g.Size.X / 6.2 + 0.3))
					local x0 = g.Position.X - g.Size.X / 2'''
new = '''					local n = math.max(1, math.floor(g.Size.X / 6.2 + 0.3))
					do local _, tsz = templates[kit]:GetBoundingBox(); if tsz.X > 8 then n = 1 end end   -- wide kits: one continuous interior
					local x0 = g.Position.X - g.Size.X / 2'''
if old in s:
    s = s.replace(old, new); p.write_text(s, encoding="utf-8")
print("cafe v3 + chalkboard written")
