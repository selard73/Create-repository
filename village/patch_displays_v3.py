"""Displays v3: chocolate trays tilt toward the glass (the rot_x sign was backwards), plus a grocery display
(produce crates on a tilted stand, sacks, stocked shelves) and a pharmacy display (white shelves of medicine boxes
and bottles, a counter, a green cross)."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)

# the sign: rot_x lowers +z points for a positive angle, so a negative pitch lifts the back edge
rep('''    pitch = math.radians(18)
    W, D = 5.4, 1.15''', '''    pitch = -math.radians(18)          # negative = back edge up = tray top faces the street
    W, D = 5.4, 1.15''')
rep('''def _shelf_unit(o, pt, w=5.6, d=1.2, z=1.6, levels=(1.3, 2.8, 4.3), top=5.0):
    box(o, "Plank", (0, top / 2, z + d / 2), w, top, 0.12, tris_out=pt)
    for sgn in (-1, 1): box(o, "Plank", (sgn * (w / 2 - 0.06), top / 2, z), 0.12, top, d, tris_out=pt)
    for y in levels: box(o, "Plank", (0, y, z), w, 0.12, d, tris_out=pt)''',
'''def _shelf_unit(o, pt, w=5.6, d=1.2, z=1.6, levels=(1.3, 2.8, 4.3), top=5.0, name="Plank"):
    box(o, name, (0, top / 2, z + d / 2), w, top, 0.12, tris_out=pt)
    for sgn in (-1, 1): box(o, name, (sgn * (w / 2 - 0.06), top / 2, z), 0.12, top, d, tris_out=pt)
    for y in levels: box(o, name, (0, y, z), w, 0.12, d, tris_out=pt)''')

d1 = s.index("def disp_flowers(name, seed):")
s = s[:d1] + r'''def _stock_row(o, g, k0, y, z, rnd, x0=-2.5, x1=2.4, kinds=("jar", "box", "bottle")):
    """A row of jars / boxes / bottles along a shelf; g is a _Group or None (then straight into o)."""
    k = k0; x = x0
    def B(name, c, sx, sy, sz):
        if g: g.box(name, c, sx, sy, sz)
        else: box(o, name, c, sx, sy, sz)
    def T(name, rings, c):
        if g: g.tube(name, rings, c, cap_bottom=True, cap_top=True)
        else: tube(o, name, rings, c, cap_bottom=True, cap_top=True)
    while x < x1:
        k += 1
        kind = kinds[rnd.randrange(len(kinds))]
        if kind == "jar":
            T(f"Jar{k}", [ring((x + 0.3, 0, z), 0.28, y + 0.06, 8), ring((x + 0.3, 0, z), 0.28, y + 0.7, 8), ring((x + 0.3, 0, z), 0.18, y + 0.85, 8)], (x + 0.3, y + 0.4, z))
            x += 0.68
        elif kind == "box":
            B(f"Box{k}", (x + 0.4, y + 0.48, z), 0.7, 0.85, 0.55)
            x += 0.85
        elif kind == "bottle":
            T(f"Bottle{k}", [ring((x + 0.22, 0, z), 0.2, y + 0.06, 8), ring((x + 0.22, 0, z), 0.2, y + 0.8, 8), ring((x + 0.22, 0, z), 0.08, y + 1.0, 8), ring((x + 0.22, 0, z), 0.08, y + 1.2, 8)], (x + 0.22, y + 0.6, z))
            x += 0.5
        else:  # pill box: small, upright, lots of them
            B(f"Pill{k}", (x + 0.24, y + 0.36, z), 0.42, 0.6, 0.3)
            x += 0.5
    return k

def disp_grocery(name, seed):
    """Grand Marche / epicerie: tilted produce crates at the glass, sacks on the floor, stocked shelves behind."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.5, levels=(1.4, 2.9, 4.4), top=5.0)
    k = 0
    for y in (1.4, 2.9, 4.4):
        k = _stock_row(o, None, k, y + 0.06, 1.5, rnd)
    # two-step produce stand, trays tilted toward the street, each holding crates heaped with one kind of produce
    pitch = -math.radians(16)
    W, D = 5.4, 1.3
    box(o, "Plank", (0, 0.6, -0.95), W, 1.2, 2.7, tris_out=pt)
    for si, (zc, top) in enumerate(((-1.55, 1.2), (-0.35, 1.95))):
        if si > 0: box(o, "Plank", (0, (1.2 + top) / 2, zc), W, top - 1.2, D, tris_out=pt)
        g = _Group()
        g.box("Plank", (0, top + 0.05, zc), W, 0.1, D)
        for i in range(4):
            k += 1
            x = -W / 2 + W * (i + 0.5) / 4
            cw, cd, ch = 1.2, 1.05, 0.45
            g.box("Bench", (x, top + 0.1 + 0.03, zc), cw, 0.06, cd)                      # crate floor (wicker colour)
            for sgn in (-1, 1):
                g.box("Bench", (x + sgn * (cw / 2 - 0.03), top + 0.1 + ch / 2, zc), 0.06, ch, cd)
                g.box("Bench", (x, top + 0.1 + ch / 2, zc + sgn * (cd / 2 - 0.03)), cw, ch, 0.06)
            rr = 0.19 + 0.04 * rnd.random()
            for j in range(9):
                gx = x - 0.35 + 0.35 * (j % 3); gz = zc - 0.3 + 0.3 * (j // 3)
                g.blob(f"Fruit{k * 10 + j}", (gx + rnd.uniform(-0.05, 0.05), top + 0.1 + ch - 0.1 + (0.12 if j == 4 else 0), gz), rr, rnd, 0.08)
        g.emit(o, (0, top, zc - D / 2), pitch)
    # sacks on the floor at the sides
    st = []
    for (x, z) in ((-2.4, -1.6), (2.4, -1.5)):
        icoblob(o, "Sack", (x, 0.55, z), 0.62, rnd, 0.1, (1.0, 0.85, 1.0), tris_out=st)
        icoblob(o, "Sack", (x + 0.1, 1.25, z), 0.42, rnd, 0.1, (1.0, 0.7, 1.0), tris_out=st)
    o.add_flat("Sack", st); o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def disp_pharmacy(name, seed):
    """Pharmacie: white shelves of small medicine boxes and bottles in neat rows, a counter, a green cross."""
    rnd = random.Random(seed); o = Obj(); tt = []
    _shelf_unit(o, tt, z=1.5, levels=(1.3, 2.5, 3.7, 4.9), top=5.5, name="Trim")
    k = 0
    for y in (1.3, 2.5, 3.7, 4.9):
        k = _stock_row(o, None, k, y + 0.06, 1.5, rnd, kinds=("pill", "pill", "pill", "bottle"))
    # green cross plaque on the back board
    cr = []
    box(o, "Cross", (0, 5.15, 1.6 + 0.62), 0.9, 0.28, 0.08, tris_out=cr)
    box(o, "Cross", (0, 5.15, 1.6 + 0.62), 0.28, 0.9, 0.08, tris_out=cr)
    o.add_flat("Cross", cr)
    # white counter at the glass with a few boxes on it
    box(o, "Trim", (0, 1.15, -1.2), 5.2, 2.3, 1.3, tris_out=tt)
    box(o, "Trim", (0, 2.36, -1.2), 5.5, 0.12, 1.55, tris_out=tt)
    k = _stock_row(o, None, k, 2.42, -1.35, rnd, x0=-2.0, x1=0.3, kinds=("pill", "bottle"))
    box(o, "Post", (1.6, 2.7, -1.2), 0.9, 0.55, 0.5)                                     # a small scale
    box(o, "Trim", (1.6, 3.0, -1.2), 0.7, 0.05, 0.4, tris_out=tt)
    o.add_flat("Trim", tt)
    return o.write(OUT / f"{name}.obj")

''' + s[d1:]
rep('''    counts["disp_chocolate"] = disp_chocolate("disp_chocolate", 28)''',
    '''    counts["disp_chocolate"] = disp_chocolate("disp_chocolate", 28)
    counts["disp_grocery"] = disp_grocery("disp_grocery", 29)
    counts["disp_pharmacy"] = disp_pharmacy("disp_pharmacy", 30)''')
rep('''    "Cheese": (0.94, 0.80, 0.40), "Choc": (0.26, 0.15, 0.10), "Wrap": (0.85, 0.70, 0.35),''',
    '''    "Cheese": (0.94, 0.80, 0.40), "Choc": (0.26, 0.15, 0.10), "Wrap": (0.85, 0.70, 0.35),
    "Fruit": (0.90, 0.50, 0.20), "Sack": (0.72, 0.60, 0.45), "Bottle": (0.85, 0.88, 0.90), "Pill": (0.95, 0.95, 0.95), "Cross": (0.20, 0.80, 0.40),''')
p.write_text(s, encoding="utf-8"); print("displays v3 written")
