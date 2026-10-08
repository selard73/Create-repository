"""v4: a real shop door (proud frame, panelled leaf, glass upper half with a cross, brass handle + kick plate,
threshold, transom) and see-through display windows with a lit interior box behind them, plus six window-display
kits (bakery, dress shop, shelves, flowers, cafe counter, hats) the builder places behind the glass by shop."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)

# ---- shop front bays: interior boxes, numbered glass, the new door -------------------------------------
b0 = s.index("    for (a, b, kind) in bays:")
b1 = s.index('    o.add_flat("Shopfront", sf)\n') + len('    o.add_flat("Shopfront", sf)\n')
s = s[:b0] + r'''    gt, br, ii = [], [], []          # glass, brass, interior
    nglass = 0
    for (a, b, kind) in bays:
        if kind == "glass":
            nglass += 1
            box(o, "Shopfront", ((a + b) / 2, riser / 2, zf - 0.3), b - a, riser, 0.6, tris_out=sf)          # stall riser
            # the pane, its own piece so the builder can find the bay and put a display behind it
            box(o, f"Glass{nglass}", ((a + b) / 2, riser + hw / 2, zf - 0.02), b - a, hw, 0.2)
            nsub = max(1, int(round((b - a) / 5.5)))
            for k in range(1, nsub):
                box(o, "Shopfront", (a + (b - a) * k / nsub, riser + hw / 2, zf - 0.2), 0.3, hw, 0.4, tris_out=sf)
            box(o, "Shopfront", ((a + b) / 2, riser + hw + 0.0, zf - 0.2), b - a, 0.3, 0.4, tris_out=sf)      # head rail
            # a shallow lit room behind the glass: floor, back wall, sides, ceiling (inside the wall's volume)
            zi0, zi1 = zf + 0.25, zf + 5.4; zc = (zi0 + zi1) / 2; dep = zi1 - zi0
            box(o, "Interior", ((a + b) / 2, riser + 0.05, zc), b - a, 0.1, dep, tris_out=ii)
            box(o, "Interior", ((a + b) / 2, riser + hw / 2, zi1 - 0.05), b - a, hw, 0.1, tris_out=ii)
            box(o, "Interior", ((a + b) / 2, bay_top - 0.05, zc), b - a, 0.1, dep, tris_out=ii)
            for xx in (a + 0.05, b - 0.05):
                box(o, "Interior", (xx, riser + hw / 2, zc), 0.1, hw, dep, tris_out=ii)
        else:
            # arched shop door in a brick surround (after Shannon's low-poly bakery references)
            dh = 7.0; cxd = (a + b) / 2
            hr = dh - dwid / 2                                                       # rectangle height under the arch
            opening = arch_profile(cxd, 0.0, dwid, hr)
            brick = []
            extrude_ring(o, "Brick", rect_profile_n(cxd, -0.1, dwid + 1.6, bay_top + 0.1), opening, "z", zf - 0.55, zf + 0.05, tris_out=brick)
            extrude_ring(o, "Brick", arch_profile(cxd, -0.1, dwid + 0.9, hr), opening, "z", zf - 0.85, zf - 0.5, tris_out=brick)
            o.add_flat("Brick", brick)
            # the leaf: a wooden arch with a glass opening (leaf = ring between the two profiles)
            lw = dwid - 0.2; leaf = arch_profile(cxd, 0.0, lw, hr - 0.1)
            gw, gy0 = 2.4, 3.0; ghr = (dh - 0.4) - gy0 - gw / 2
            glass = arch_profile(cxd, gy0, gw, ghr)
            extrude_ring(o, "DoorShop", leaf, glass, "z", zf - 0.2, zf + 0.05)
            box(o, "DoorShop", (cxd, 1.5, zf - 0.26), lw - 0.8, 2.0, 0.12)                                # raised lower panel
            box(o, "DoorShop", (cxd, gy0 - 0.15, zf - 0.26), lw - 0.3, 0.3, 0.12)                          # glazing rail
            extrude(o, "GlassDoor", glass, "z", zf - 0.12, zf - 0.06, tris_out=gt)
            # iron scroll grille in the glass
            for dx in (-1.0, -0.5, 0.0, 0.5, 1.0):
                ytop = gy0 + ghr + math.sqrt(max((gw / 2) ** 2 - dx * dx, 0.0)) - 0.12
                box(o, "Iron", (cxd + dx, (gy0 + ytop) / 2, zf - 0.19), 0.08, ytop - gy0, 0.08, tris_out=it)
            for yy in (gy0 + 1.1, gy0 + 2.2):
                box(o, "Iron", (cxd, yy, zf - 0.19), gw, 0.08, 0.08, tris_out=it)
            for dx in (-0.75, -0.25, 0.25, 0.75):
                box(o, "Iron", (cxd + dx, gy0 + 0.5, zf - 0.19), 0.34, 0.34, 0.06, tris_out=it)
                box(o, "Iron", (cxd + dx, gy0 + 0.5, zf - 0.19), 0.2, 0.2, 0.09, tris_out=it)
            # brass handle and plate
            box(o, "Brass", (cxd + lw * 0.36, 3.6, zf - 0.42), 0.14, 1.2, 0.14, tris_out=br)
            box(o, "Brass", (cxd + lw * 0.36, 3.6, zf - 0.3), 0.34, 0.6, 0.1, tris_out=br)
            box(o, "Trim", (cxd, 0.08, zf - 0.7), dwid + 0.8, 0.16, 1.3, tris_out=tt)                     # threshold
            # a little of the shop behind the door glass
            zi0, zi1 = zf + 0.1, zf + 4.0; zc = (zi0 + zi1) / 2; dep = zi1 - zi0
            box(o, "Interior", (cxd, 0.05, zc), dwid, 0.1, dep, tris_out=ii)
            box(o, "Interior", (cxd, dh / 2, zi1 - 0.05), dwid, dh, 0.1, tris_out=ii)
            box(o, "Interior", (cxd, dh - 0.05, zc), dwid, 0.1, dep, tris_out=ii)
            for xx in (cxd - dwid / 2 + 0.05, cxd + dwid / 2 - 0.05):
                box(o, "Interior", (xx, dh / 2, zc), 0.1, dh, dep, tris_out=ii)
        box(o, "Shopfront", (b, gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)        # post between bays
    for sgn in (-1, 1):
        box(o, "Shopfront", (sgn * (fw / 2 - 1.1), gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)
    o.add_flat("Shopfront", sf); o.add_flat("GlassDoor", gt); o.add_flat("Brass", br); o.add_flat("Interior", ii)
''' + s[b1:]

rep('''def rect_profile(cu, y0, w, h):
    return [(cu - w / 2, y0), (cu + w / 2, y0), (cu + w / 2, y0 + h), (cu - w / 2, y0 + h)]''',
'''def rect_profile(cu, y0, w, h):
    return [(cu - w / 2, y0), (cu + w / 2, y0), (cu + w / 2, y0 + h), (cu - w / 2, y0 + h)]

def rect_profile_n(cu, y0, w, h, n=8):
    """Rectangle with its top edge subdivided so it has as many points as arch_profile(n): a ring can join them."""
    pts = [(cu - w / 2, y0), (cu + w / 2, y0), (cu + w / 2, y0 + h)]
    for k in range(1, n):
        pts.append((cu + w / 2 - w * k / n, y0 + h))
    pts.append((cu - w / 2, y0 + h))
    return pts''')

# ---- window-display kits -------------------------------------------------------------------------------
d0 = s.index("def pot(name, seed):")
s = s[:d0] + r'''# ---- window displays (6 wide, stand on y = 0, front toward -Z; the builder puts copies behind each Glass pane) ----
def _shelf_unit(o, pt, w=5.6, d=1.2, z=1.6, levels=(1.3, 2.8, 4.3), top=5.0):
    box(o, "Plank", (0, top / 2, z + d / 2), w, top, 0.12, tris_out=pt)
    for sgn in (-1, 1): box(o, "Plank", (sgn * (w / 2 - 0.06), top / 2, z), 0.12, top, d, tris_out=pt)
    for y in levels: box(o, "Plank", (0, y, z), w, 0.12, d, tris_out=pt)

def _cake(o, x, z, k, rnd, ct, tt, r=0.7, y=0.0):
    """A cake on a stand, standing on height y."""
    c = (x, y, z)
    box(o, "Trim", (x, y + 0.05, z), 1.8, 0.1, 1.8, tris_out=tt)
    tube(o, "Trim", [ring(c, 0.12, 0.1, 6), ring(c, 0.12, 0.7, 6)], (x, y + 0.4, z), tris_out=tt)
    tube(o, "Trim", [ring(c, r + 0.2, 0.7, 10), ring(c, r + 0.2, 0.8, 10)], (x, y + 0.75, z), cap_top=True, cap_bottom=True, tris_out=tt)
    tube(o, "Cake", [ring(c, r, 0.8, 10), ring(c, r, 1.5, 10)], (x, y + 1.15, z), tris_out=ct)
    ic = []
    tube(o, f"Icing{k}", [ring(c, r + 0.04, 1.45, 10), ring(c, r + 0.04, 1.7, 10)], (x, y + 1.6, z), cap_top=True, tris_out=ic)
    icoblob(o, f"Icing{k}", (x, y + 1.85, z), 0.22, rnd, 0.05, tris_out=ic)
    o.add_flat(f"Icing{k}", ic)

def disp_bakery(name, seed):
    rnd = random.Random(seed); o = Obj(); pt, bt, wt, tt, ct = [], [], [], [], []
    _shelf_unit(o, pt, z=1.5, levels=(1.3, 2.8, 4.3), top=5.0)
    for y in (1.3, 2.8, 4.3):
        for i in range(5):
            icoblob(o, "Bread", (-2.2 + 1.1 * i, y + 0.4, 1.5 + rnd.uniform(-0.15, 0.15)), 0.42, rnd, 0.1, (1.0, 0.75, 1.25), tris_out=bt)
    # basket of baguettes, front left
    box(o, "Bench", (-1.9, 0.6, -0.5), 1.4, 1.2, 1.4, tris_out=wt)
    for i in range(5):
        a = 2 * math.pi * i / 5
        icoblob(o, "Bread", (-1.9 + 0.35 * math.cos(a), 1.6, -0.5 + 0.35 * math.sin(a)), 0.95, rnd, 0.06, (0.2, 1.0, 0.2), tris_out=bt)
    _cake(o, 1.7, -0.4, 1, rnd, ct, tt, r=0.75)
    o.add_flat("Plank", pt); o.add_flat("Bread", bt); o.add_flat("Bench", wt); o.add_flat("Trim", tt); o.add_flat("Cake", ct)
    return o.write(OUT / f"{name}.obj")

def _mannequin(o, x, z, k, rnd, post, head):
    dt = []
    tube(o, "Post", [ring((x, 0, z), 0.6, 0, 8), ring((x, 0, z), 0.6, 0.12, 8)], (x, 0.06, z), cap_top=True, cap_bottom=True, tris_out=post)
    tube(o, "Post", [ring((x, 0, z), 0.08, 0.1, 6), ring((x, 0, z), 0.08, 1.6, 6)], (x, 0.8, z), tris_out=post)
    tube(o, f"Dress{k}", [ring((x, 0, z), 1.0, 1.5, 10), ring((x, 0, z), 0.5, 3.0, 10)], (x, 2.2, z), cap_bottom=True, tris_out=dt)
    tube(o, f"Dress{k}", [ring((x, 0, z), 0.5, 3.0, 10), ring((x, 0, z), 0.42, 3.6, 10), ring((x, 0, z), 0.56, 4.3, 10)], (x, 3.6, z), cap_top=True, tris_out=dt)
    o.add_flat(f"Dress{k}", dt)
    tube(o, "Head", [ring((x, 0, z), 0.15, 4.3, 6), ring((x, 0, z), 0.15, 4.6, 6)], (x, 4.45, z), tris_out=head)
    icoblob(o, "Head", (x, 5.05, z), 0.45, rnd, 0.03, tris_out=head)

def disp_dress(name, seed):
    rnd = random.Random(seed); o = Obj(); post, head = [], []
    _mannequin(o, -1.5, -0.3, 1, rnd, post, head)
    _mannequin(o, 1.5, 0.1, 2, rnd, post, head)
    # clothes rail at the back with hanging dresses
    box(o, "Post", (0, 4.9, 2.0), 5.4, 0.1, 0.1, tris_out=post)
    for sgn in (-1, 1): box(o, "Post", (sgn * 2.6, 2.6, 2.0), 0.1, 4.7, 0.1, tris_out=post)
    for i in range(4):
        x = -2.0 + 1.33 * i
        box(o, "Post", (x, 4.75, 2.0), 0.6, 0.06, 0.06, tris_out=post)
        box(o, f"Dress{3 + i}", (x, 3.5, 2.0), 0.9, 2.4, 0.12)
    o.add_flat("Post", post); o.add_flat("Head", head)
    return o.write(OUT / f"{name}.obj")

def disp_shelves(name, seed):
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.4, levels=(1.2, 2.6, 4.0), top=5.0)
    k = 0
    for y in (1.2, 2.6, 4.0):
        x = -2.5
        while x < 2.3:
            k += 1
            r = rnd.random()
            if r < 0.35:      # jar
                tube(o, f"Jar{k}", [ring((x + 0.3, 0, 1.4), 0.28, y + 0.06, 8), ring((x + 0.3, 0, 1.4), 0.28, y + 0.7, 8), ring((x + 0.3, 0, 1.4), 0.18, y + 0.85, 8)], (x + 0.3, y + 0.4, 1.4), cap_bottom=True, cap_top=True)
                x += 0.7
            elif r < 0.6:     # box
                box(o, f"Box{k}", (x + 0.4, y + 0.5, 1.4), 0.75, 0.85, 0.6)
                x += 0.9
            elif r < 0.8:     # round (cheese wheel / tin)
                tube(o, f"Round{k}", [ring((x + 0.45, 0, 1.4), 0.42, y + 0.06, 10), ring((x + 0.45, 0, 1.4), 0.42, y + 0.4, 10)], (x + 0.45, y + 0.25, 1.4), cap_top=True, cap_bottom=True)
                x += 1.0
            else:             # a run of books
                for j in range(4):
                    k += 1
                    box(o, f"Book{k}", (x + 0.1 + 0.2 * j, y + 0.06 + 0.45, 1.4), 0.16, 0.9 - 0.1 * (j % 2), 0.7)
                x += 0.95
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def disp_flowers(name, seed):
    rnd = random.Random(seed); o = Obj(); st, lt, pl = [], [], []
    k = 0
    for (x, z, h) in ((-1.9, -0.4, 1.4), (0.0, 0.2, 1.1), (1.9, -0.5, 1.5)):
        tube(o, "Stone", [ring((x, 0, z), 0.5, 0, 8), ring((x, 0, z), 0.62, h, 8)], (x, h / 2, z), cap_bottom=True, cap_top=True, tris_out=st)
        for i in range(6):
            k += 1
            a = 2 * math.pi * i / 6
            ft = []
            icoblob(o, f"Flower{k}", (x + 0.38 * math.cos(a), h + 1.2 + rnd.uniform(-0.15, 0.15), z + 0.38 * math.sin(a)), 0.34, rnd, 0.1, tris_out=ft)
            o.add_flat(f"Flower{k}", ft)
        icoblob(o, "Leaf", (x, h + 0.7, z), 0.55, rnd, 0.15, (1.2, 0.6, 1.2), tris_out=lt)
    # tall plant in a pot at the back
    tube(o, "Planter", [ring((0, 0, 1.9), 0.6, 0, 8), ring((0, 0, 1.9), 0.75, 1.2, 8)], (0, 0.6, 1.9), cap_bottom=True, cap_top=True, tris_out=pl)
    tube(o, "Trunk", [ring((0, 0, 1.9), 0.08, 1.1, 6), ring((0, 0, 1.9), 0.08, 3.4, 6)], (0, 2.2, 1.9), tris_out=lt)
    for (dx, dy, dz) in ((0, 3.9, 0), (0.6, 3.4, 0.2), (-0.6, 3.5, -0.2), (0.1, 3.3, 0.6)):
        icoblob(o, "Leaf", (dx, dy, 1.9 + dz), 0.62, rnd, 0.15, tris_out=lt)
    o.add_flat("Stone", st); o.add_flat("Leaf", lt); o.add_flat("Planter", pl)
    return o.write(OUT / f"{name}.obj")

def disp_cafe(name, seed):
    rnd = random.Random(seed); o = Obj(); pt, tt, ct, po, ln = [], [], [], [], []
    box(o, "Plank", (0, 1.4, 0.6), 5.4, 2.8, 1.6, tris_out=pt)                         # counter
    box(o, "Trim", (0, 2.85, 0.6), 5.7, 0.14, 1.9, tris_out=tt)                        # counter top
    _cake(o, -1.6, 0.5, 1, rnd, ct, tt, r=0.6, y=2.92)
    _cake(o, 0.0, 0.5, 2, rnd, ct, tt, r=0.5, y=2.92)
    box(o, "Post", (1.7, 3.55, 0.7), 1.2, 1.2, 1.0, tris_out=po)                       # coffee machine
    box(o, "Trim", (1.7, 4.2, 0.7), 1.3, 0.12, 1.1, tris_out=tt)
    box(o, "Brass", (1.7, 3.2, 0.1), 0.5, 0.12, 0.3)                                   # spouts
    for i in range(3):
        tube(o, "Trim", [ring((1.2 + 0.35 * i, 0, 1.15), 0.12, 2.92, 6), ring((1.2 + 0.35 * i, 0, 1.15), 0.14, 3.2, 6)], (1.2 + 0.35 * i, 3.05, 1.15), cap_top=True, tris_out=tt)   # cups
    # chalkboard menu on the back wall, framed
    box(o, "Trim", (-1.2, 4.6, 2.05), 2.6, 1.9, 0.12, tris_out=tt)
    box(o, "Sign", (-1.2, 4.6, 1.97), 2.3, 1.6, 0.08)
    # two pendant lamps
    for x in (-1.6, 1.4):
        box(o, "Post", (x, 6.0, 0.5), 0.05, 1.6, 0.05, tris_out=po)
        tube(o, "Lantern", [ring((x, 0, 0.5), 0.2, 5.2, 8), ring((x, 0, 0.5), 0.55, 4.7, 8)], (x, 4.95, 0.5), cap_bottom=True, tris_out=ln)
    o.add_flat("Plank", pt); o.add_flat("Trim", tt); o.add_flat("Cake", ct); o.add_flat("Post", po); o.add_flat("Lantern", ln)
    return o.write(OUT / f"{name}.obj")

def disp_hats(name, seed):
    rnd = random.Random(seed); o = Obj(); po, pt = [], []
    k = 0
    def hat(x, y, z, k, crown=0.7, r=0.55, brim=0.95):
        ht = []
        tube(o, f"Hat{k}", [ring((x, 0, z), brim, y, 10), ring((x, 0, z), brim, y + 0.08, 10)], (x, y + 0.04, z), cap_top=True, cap_bottom=True, tris_out=ht)
        tube(o, f"Hat{k}", [ring((x, 0, z), r, y + 0.08, 10), ring((x, 0, z), r * 0.92, y + 0.08 + crown, 10)], (x, y + crown / 2, z), cap_top=True, tris_out=ht)
        o.add_flat(f"Hat{k}", ht)
    for (x, z, h) in ((-1.7, -0.3, 3.2), (0.1, 0.3, 3.9), (1.8, -0.4, 2.7)):
        k += 1
        tube(o, "Post", [ring((x, 0, z), 0.55, 0, 8), ring((x, 0, z), 0.55, 0.1, 8)], (x, 0.05, z), cap_top=True, cap_bottom=True, tris_out=po)
        tube(o, "Post", [ring((x, 0, z), 0.07, 0.1, 6), ring((x, 0, z), 0.07, h, 6)], (x, h / 2, z), tris_out=po)
        icoblob(o, "Post", (x, h + 0.1, z), 0.3, rnd, 0.02, tris_out=po)
        hat(x, h - 0.1, z, k, crown=0.6 + 0.3 * rnd.random(), r=0.5 + 0.1 * rnd.random(), brim=0.8 + 0.3 * rnd.random())
    _shelf_unit(o, pt, w=5.6, d=1.0, z=2.0, levels=(4.4,), top=5.0)
    for i in range(3):
        k += 1
        hat(-1.8 + 1.8 * i, 4.5, 2.0, k, crown=0.55, r=0.45, brim=0.75)
    o.add_flat("Post", po); o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

''' + s[d0:]

rep('''    counts["pot"] = pot("pot", 15)
    counts["crates"] = crates("crates", 16)''',
'''    counts["pot"] = pot("pot", 15)
    counts["crates"] = crates("crates", 16)
    counts["disp_bakery"] = disp_bakery("disp_bakery", 21)
    counts["disp_dress"] = disp_dress("disp_dress", 22)
    counts["disp_shelves"] = disp_shelves("disp_shelves", 23)
    counts["disp_flowers"] = disp_flowers("disp_flowers", 24)
    counts["disp_cafe"] = disp_cafe("disp_cafe", 25)
    counts["disp_hats"] = disp_hats("disp_hats", 26)''')
rep('''    "Bread": (0.85, 0.62, 0.35),
})''', '''    "Bread": (0.85, 0.62, 0.35), "Glass": (0.78, 0.86, 0.92), "Interior": (0.93, 0.88, 0.80), "Brass": (0.84, 0.70, 0.36),
    "Cake": (0.98, 0.96, 0.92), "Icing": (0.94, 0.66, 0.74), "Dress": (0.90, 0.47, 0.55), "Head": (0.92, 0.84, 0.78),
    "Jar": (0.78, 0.55, 0.35), "Box": (0.60, 0.42, 0.30), "Round": (0.94, 0.82, 0.47), "Book": (0.55, 0.35, 0.35), "Hat": (0.25, 0.22, 0.2),
})''')
p.write_text(s, encoding="utf-8"); print("townhouse v4 written")
