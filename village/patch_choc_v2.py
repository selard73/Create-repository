"""Chocolatier v2: a stepped display case behind the glass, every tray tilted up toward the street so the bars,
truffle boxes and pralines show their tops (Shannon: 'arranged display by the window ... tilting up slightly')."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
d0 = s.index("def disp_chocolate(name, seed):")
d1 = s.index("def disp_flowers(name, seed):")
s = s[:d0] + r'''class _Group:
    """Collects box/blob triangles per piece name so a whole arrangement can be tilted together."""
    def __init__(self): self.lists = {}
    def L(self, name): return self.lists.setdefault(name, [])
    def box(self, name, c, sx, sy, sz): box(None, name, c, sx, sy, sz, tris_out=self.L(name))
    def blob(self, name, c, r, rnd, jitter=0.06, squash=(1, 1, 1)): icoblob(None, name, c, r, rnd, jitter, squash, tris_out=self.L(name))
    def tube(self, name, rings, c, **kw): tube(None, name, rings, c, tris_out=self.L(name), **kw)
    def emit(self, o, pivot, pitch):
        """Rotate everything about the X axis through pivot (positive pitch lifts the back edge) and add to o."""
        for name, tris in self.lists.items():
            out = []
            for tri in tris:
                out.append(tuple(F.add(pivot, F.rot_x(F.sub(pt, pivot), pitch)) for pt in tri))
            o.add_flat(name, out)

def _choc_item(g, k, kind, x, y, z, rnd):
    """One item lying flat on a tray at (x, y, z): a bar with its grid, an open truffle box, or pralines on a doily."""
    if kind == "bar":
        w, d, t = 1.25, 0.75, 0.14
        g.box(f"Wrap{k}" if rnd.random() < 0.4 else f"Choc{k}", (x, y + t / 2, z), w, t, d)
        for i in range(4):
            for j in range(2):
                g.box(f"Choc{k}", (x - w / 2 + w * (i + 0.5) / 4, y + t + 0.03, z - d / 2 + d * (j + 0.5) / 2), w / 4 - 0.08, 0.06, d / 2 - 0.08)
    elif kind == "box":
        w, d = 1.3, 0.95
        g.box(f"Wrap{k}", (x, y + 0.04, z), w, 0.08, d)
        for sgn in (-1, 1):
            g.box(f"Wrap{k}", (x + sgn * (w / 2 - 0.03), y + 0.18, z), 0.06, 0.28, d)
            g.box(f"Wrap{k}", (x, y + 0.18, z + sgn * (d / 2 - 0.03)), w, 0.28, 0.06)
        for i in range(3):
            for j in range(2):
                g.blob(f"Choc{k * 10 + i * 2 + j}", (x - 0.4 + 0.4 * i, y + 0.25, z - 0.22 + 0.44 * j), 0.16, rnd)
    else:
        g.tube("Cake", [ring((x, 0, z), 0.62, y, 10), ring((x, 0, z), 0.62, y + 0.04, 10)], (x, y + 0.02, z), cap_top=True, cap_bottom=True)
        for i in range(5):
            a = 2 * math.pi * i / 5
            g.blob(f"Choc{k * 10 + i}", (x + 0.32 * math.cos(a), y + 0.2, z + 0.32 * math.sin(a)), 0.17, rnd)
        g.blob(f"Choc{k * 10 + 7}", (x, y + 0.24, z), 0.18, rnd)

def disp_chocolate(name, seed):
    """Chocolatier: wrapped bars on the back shelves and a stepped display case at the glass, trays tilted 18 deg."""
    rnd = random.Random(seed); o = Obj(); pt = []
    _shelf_unit(o, pt, z=1.5, levels=(1.4, 2.9, 4.4), top=5.0)
    k = 0
    for y in (1.4, 2.9, 4.4):
        x = -2.3
        while x < 2.3:
            k += 1
            _choc_bar(o, k, x, y + 0.06, 1.65 + rnd.uniform(-0.05, 0.05), w=1.3, d=0.75, standing=True, wrap=(rnd.random() < 0.7))
            x += 0.95
    # the case: three steps rising toward the back, each tray tilted so its top faces the street
    pitch = math.radians(18)
    W, D = 5.4, 1.15
    steps = [(-1.55, 1.9), (-0.45, 2.55), (0.65, 3.2)]           # (z centre, top height) of each step
    box(o, "Plank", (0, 0.95, -0.45), W, 1.9, 3.35, tris_out=pt)  # the plinth under the steps
    kinds = ["bar", "box", "doily", "bar", "box"]
    for si, (zc, top) in enumerate(steps):
        if si > 0: box(o, "Plank", (0, (1.9 + top) / 2, zc), W, top - 1.9, D, tris_out=pt)   # riser under the tray
        g = _Group()
        g.box("Trim", (0, top + 0.05, zc), W, 0.1, D)                  # the tray (cream)
        g.box("Plank", (0, top + 0.13, zc + D / 2 - 0.05), W, 0.16, 0.1)  # back lip
        n = 5 if si < 2 else 4
        for i in range(n):
            k += 1
            x = -W / 2 + W * (i + 0.5) / n
            _choc_item(g, k, kinds[(i + si) % len(kinds)], x, top + 0.1, zc, rnd)
        g.emit(o, (0, top, zc - D / 2), pitch)
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

''' + s[d1:]
p.write_text(s, encoding="utf-8"); print("chocolate v2 written")
