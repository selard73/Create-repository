"""Displays v2: a front table right behind the glass in the shelf-type kits, plus dedicated cheese and chocolate
window displays (Shannon: 'too far back', 'does not look like chocolate', 'fromage means cheese')."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)

d0 = s.index("def disp_shelves(name, seed):")
d1 = s.index("def disp_flowers(name, seed):")
s = s[:d0] + r'''def _front_table(o, pt, w=5.2, d=1.5, z=-1.15, h=2.3):
    """Low display table right behind the glass; returns its top height."""
    box(o, "Plank", (0, h - 0.06, z), w, 0.12, d, tris_out=pt)
    box(o, "Plank", (0, h - 0.35, z), w - 0.2, 0.5, d - 0.3, tris_out=pt)
    for sx in (-1, 1):
        for sz in (-1, 1):
            box(o, "Plank", (sx * (w / 2 - 0.15), h / 2, z + sz * (d / 2 - 0.15)), 0.14, h, 0.14, tris_out=pt)
    return h

def _quad_dir(tris, A, B, C, D, want):
    """Quad ABCD with its normal turned toward direction `want`."""
    n = F.cross(F.sub(B, A), F.sub(C, A))
    if F.dot(n, want) < 0: A, B, C, D = A, D, C, B
    tris += [(A, B, C), (A, C, D)]

def _wheel(o, name, cx, y0, cz, r, h, a0=0.0, a1=2 * math.pi, n=14):
    """Cheese wheel (or a wedge of one) standing on y0, spanning angles a0..a1; cut faces where it is not a full circle."""
    tris = []
    full = abs((a1 - a0) - 2 * math.pi) < 1e-6
    segs = max(3, int(round(n * (a1 - a0) / (2 * math.pi))))
    pts0 = [(cx + r * math.cos(a0 + (a1 - a0) * k / segs), y0, cz + r * math.sin(a0 + (a1 - a0) * k / segs)) for k in range(segs + 1)]
    pts1 = [(x, y0 + h, z) for (x, _, z) in pts0]
    cb, ct = (cx, y0, cz), (cx, y0 + h, cz)
    for k in range(segs):
        out = F.sub(F.mul(F.add(pts0[k], pts0[k + 1]), 0.5), cb)
        _quad_dir(tris, pts0[k], pts0[k + 1], pts1[k + 1], pts1[k], out)
        tris.append((ct, pts1[k], pts1[k + 1]) if F.cross(F.sub(pts1[k], ct), F.sub(pts1[k + 1], ct))[1] > 0 else (ct, pts1[k + 1], pts1[k]))
        tris.append((cb, pts0[k + 1], pts0[k]) if F.cross(F.sub(pts0[k + 1], cb), F.sub(pts0[k], cb))[1] < 0 else (cb, pts0[k], pts0[k + 1]))
    if not full:
        for (idx, ang, sgn) in ((0, a0, -1), (segs, a1, 1)):
            want = (sgn * -math.sin(ang), 0, sgn * math.cos(ang))
            _quad_dir(tris, cb, pts0[idx], pts1[idx], ct, want)
    o.add_flat(name, tris)

def disp_shelves(name, seed):
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.4, levels=(1.2, 2.6, 4.0), top=5.0)
    k = 0
    def items(y, z, x0=-2.5, x1=2.3):
        nonlocal k
        x = x0
        while x < x1:
            k += 1
            r = rnd.random()
            if r < 0.35:      # jar
                tube(o, f"Jar{k}", [ring((x + 0.3, 0, z), 0.28, y + 0.06, 8), ring((x + 0.3, 0, z), 0.28, y + 0.7, 8), ring((x + 0.3, 0, z), 0.18, y + 0.85, 8)], (x + 0.3, y + 0.4, z), cap_bottom=True, cap_top=True)
                x += 0.7
            elif r < 0.6:     # box
                box(o, f"Box{k}", (x + 0.4, y + 0.5, z), 0.75, 0.85, 0.6)
                x += 0.9
            elif r < 0.8:     # round tin
                tube(o, f"Round{k}", [ring((x + 0.45, 0, z), 0.42, y + 0.06, 10), ring((x + 0.45, 0, z), 0.42, y + 0.4, 10)], (x + 0.45, y + 0.25, z), cap_top=True, cap_bottom=True)
                x += 1.0
            else:             # a run of books
                for j in range(4):
                    k += 1
                    box(o, f"Book{k}", (x + 0.1 + 0.2 * j, y + 0.06 + 0.45, z), 0.16, 0.9 - 0.1 * (j % 2), 0.7)
                x += 0.95
    for y in (1.2, 2.6, 4.0): items(y, 1.4)
    h = _front_table(o, pt)
    items(h, -1.15, -2.2, 2.0)
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def disp_cheese(name, seed):
    """Fromagerie: stacked wheels on the shelves, a big cut wheel with its wedge on the front table."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.4, levels=(1.2, 2.7, 4.2), top=5.0)
    k = 0
    for y in (1.2, 2.7, 4.2):
        x = -2.4
        while x < 2.2:
            k += 1
            r = rnd.uniform(0.45, 0.8); hh = rnd.uniform(0.28, 0.5)
            stack = rnd.randint(1, 3)
            for j in range(stack):
                k += 1
                _wheel(o, f"Cheese{k}", x + r, y + 0.06 + j * hh, 1.4, r * (1 - 0.05 * j), hh)
            x += 2 * r + 0.3
    h = _front_table(o, pt)
    _wheel(o, "Cheese91", -1.4, h, -1.15, 1.05, 0.55, a0=math.radians(60), a1=math.radians(360))       # big wheel, wedge cut out
    _wheel(o, "Cheese92", 0.35, h, -0.75, 1.05, 0.55, a0=math.radians(0), a1=math.radians(52))        # the wedge beside it
    _wheel(o, "Cheese93", 1.7, h, -1.3, 0.6, 0.4)
    _wheel(o, "Cheese94", 1.7, h + 0.4, -1.3, 0.55, 0.35)
    box(o, "Trim", (0.4, h + 0.03, -1.55), 1.4, 0.06, 0.5)                                            # a little board
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

def _choc_bar(o, k, x, y, z, w=1.4, d=0.8, t=0.14, standing=False, wrap=False):
    """A chocolate bar with its grid of squares; standing=True leans it upright against the shelf back."""
    name = f"Wrap{k}" if wrap else f"Choc{k}"
    if standing:
        box(o, name, (x, y + w / 2, z), d, w, t)
        if not wrap:
            for i in range(2):
                for j in range(4):
                    box(o, f"Choc{k}", (x - d / 2 + d * (i + 0.5) / 2, y + w * (j + 0.5) / 4, z - t / 2 - 0.03), d / 2 - 0.08, w / 4 - 0.08, 0.06)
        else:
            box(o, f"Choc{k}", (x, y + w * 0.5, z - t / 2 - 0.02), d + 0.02, w * 0.28, 0.04)             # dark band on the wrapper
    else:
        box(o, name, (x, y + t / 2, z), w, t, d)
        if not wrap:
            for i in range(4):
                for j in range(2):
                    box(o, f"Choc{k}", (x - w / 2 + w * (i + 0.5) / 4, y + t + 0.03, z - d / 2 + d * (j + 0.5) / 2), w / 4 - 0.08, 0.06, d / 2 - 0.08)
        else:
            box(o, f"Choc{k}", (x, y + t + 0.02, z), w * 0.28, 0.04, d + 0.02)

def disp_chocolate(name, seed):
    """Chocolatier: wrapped bars standing on the shelves, bare bars and open boxes of truffles on the front table."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.4, levels=(1.2, 2.7, 4.2), top=5.0)
    k = 0
    for y in (1.2, 2.7, 4.2):
        x = -2.3
        while x < 2.3:
            k += 1
            _choc_bar(o, k, x, y + 0.06, 1.55 + rnd.uniform(-0.05, 0.05), w=1.3, d=0.75, standing=True, wrap=(rnd.random() < 0.7))
            x += 0.95
    h = _front_table(o, pt)
    _choc_bar(o, 90, -1.7, h, -1.35, w=1.5, d=0.85)
    _choc_bar(o, 91, -1.4, h + 0.14, -0.85, w=1.5, d=0.85)
    # open boxes of truffles
    for (bx, bz, kk) in ((0.6, -1.2, 92), (1.9, -0.9, 93)):
        box(o, f"Wrap{kk}", (bx, h + 0.05, bz), 1.3, 0.1, 1.0)
        for sgn in (-1, 1):
            box(o, f"Wrap{kk}", (bx + sgn * 0.62, h + 0.2, bz), 0.06, 0.3, 1.0)
            box(o, f"Wrap{kk}", (bx, h + 0.2, bz + sgn * 0.47), 1.3, 0.3, 0.06)
        for i in range(3):
            for j in range(2):
                k += 1
                icoblob(o, f"Choc{k}", (bx - 0.4 + 0.4 * i, h + 0.28, bz - 0.2 + 0.4 * j), 0.17, rnd, 0.06)
    # a lid leaning behind one box
    box(o, "Wrap94", (0.6, h + 0.6, -0.6), 1.3, 1.0, 0.06)
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

''' + s[d1:]
rep('''    counts["disp_hats"] = disp_hats("disp_hats", 26)''',
    '''    counts["disp_hats"] = disp_hats("disp_hats", 26)
    counts["disp_cheese"] = disp_cheese("disp_cheese", 27)
    counts["disp_chocolate"] = disp_chocolate("disp_chocolate", 28)''')
rep('''    "Jar": (0.78, 0.55, 0.35), "Box": (0.60, 0.42, 0.30), "Round": (0.94, 0.82, 0.47), "Book": (0.55, 0.35, 0.35), "Hat": (0.25, 0.22, 0.2),''',
    '''    "Jar": (0.78, 0.55, 0.35), "Box": (0.60, 0.42, 0.30), "Round": (0.94, 0.82, 0.47), "Book": (0.55, 0.35, 0.35), "Hat": (0.25, 0.22, 0.2),
    "Cheese": (0.94, 0.80, 0.40), "Choc": (0.26, 0.15, 0.10), "Wrap": (0.85, 0.70, 0.35),''')
p.write_text(s, encoding="utf-8"); print("displays v2 written")
