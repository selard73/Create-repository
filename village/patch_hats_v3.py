"""Hat shop v3: hats rest on tilted display steps so their crowns and brims read from the street; smoother (24-side)
shapes, curled brims, no head forms. Hat boxes stay."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
d0 = s.index("def _hat(o, k, x, y, z, style, rnd):")
d1 = s.index("def pot(name, seed):")
assert d0 < d1
s = s[:d0] + r'''def _hat_g(g, k, x, y, z, style, rnd, N=24):
    """A hat with its brim at height y, centred on (x, z), written into _Group g as Hat<k> / Band<k>."""
    c = (x, 0, z)
    H, B = f"Hat{k}", f"Band{k}"
    def crown(rings): g.tube(H, rings, (x, y + 0.6, z), cap_top=True)
    def flat_brim(r, t=0.07): g.tube(H, [ring(c, r, y, N), ring(c, r, y + t, N)], (x, y + t / 2, z), cap_top=True, cap_bottom=True)
    def cone_brim(r_in, r_out, drop, t=0.07):
        # brim that droops from the crown outward (sun hat, cloche) or curls up (bowler: negative drop)
        g.tube(H, [ring(c, r_out, y - drop, N), ring(c, r_in, y, N)], (x, y - drop / 2, z))
        g.tube(H, [ring(c, r_in, y + t, N), ring(c, r_out, y - drop + t, N)], (x, y - drop / 2 + t, z))
        g.tube(H, [ring(c, r_out, y - drop, N), ring(c, r_out, y - drop + t, N)], (x, y - drop, z))
    def band(r, y0, h=0.24): g.tube(B, [ring(c, r, y0, N), ring(c, r, y0 + h, N)], (x, y0 + h / 2, z))
    if style == "top":
        cone_brim(0.72, 1.15, -0.1)
        crown([ring(c, 0.7, y + 0.02, N), ring(c, 0.66, y + 0.8, N), ring(c, 0.74, y + 1.55, N)])
        band(0.72, y + 0.1)
    elif style == "boater":
        flat_brim(1.45)
        crown([ring(c, 0.85, y + 0.05, N), ring(c, 0.85, y + 0.62, N)])
        band(0.87, y + 0.1, 0.26)
    elif style == "cloche":
        cone_brim(0.8, 1.05, 0.22)
        crown([ring(c, 0.8, y + 0.02, N), ring(c, 0.82, y + 0.45, N), ring(c, 0.66, y + 0.85, N), ring(c, 0.3, y + 1.08, N)])
        band(0.83, y + 0.1, 0.22)
    elif style == "sun":
        cone_brim(0.85, 1.95, 0.3)
        crown([ring(c, 0.85, y + 0.02, N), ring(c, 0.8, y + 0.5, N), ring(c, 0.5, y + 0.78, N)])
        band(0.87, y + 0.1, 0.24)
        g.blob(B, (x + 0.8, y + 0.28, z + 0.45), 0.2, rnd, 0.08)
        g.blob(B, (x + 1.05, y + 0.28, z + 0.15), 0.2, rnd, 0.08)
    elif style == "bowler":
        cone_brim(0.78, 1.12, -0.16)
        crown([ring(c, 0.78, y + 0.02, N), ring(c, 0.78, y + 0.4, N), ring(c, 0.6, y + 0.78, N), ring(c, 0.22, y + 0.95, N)])
        band(0.8, y + 0.1, 0.22)
    elif style == "fedora":
        cone_brim(0.82, 1.35, 0.08)
        crown([ring(c, 0.82, y + 0.02, N), ring(c, 0.78, y + 0.6, N), ring(c, 0.7, y + 1.05, N), ring(c, 0.5, y + 1.15, N)])
        band(0.84, y + 0.1, 0.26)
    else:  # beret
        g.blob(H, (x, y + 0.24, z), 1.0, rnd, 0.04, (1.0, 0.3, 1.0))
        g.box(H, (x, y + 0.62, z), 0.08, 0.22, 0.08)

def _hat_box(o, k, x, y, z, r, h, N=24):
    tube(o, f"Wrap{k}", [ring((x, 0, z), r, y, N), ring((x, 0, z), r, y + h, N)], (x, y + h / 2, z), cap_top=True, cap_bottom=True)
    tube(o, f"Wrap{k + 1}", [ring((x, 0, z), r + 0.05, y + h - 0.18, N), ring((x, 0, z), r + 0.05, y + h + 0.02, N)], (x, y + h, z), cap_top=True)

def disp_hats(name, seed):
    """Chapelier: six hats on three tilted display steps at the glass, three upright on the shelf, hat boxes."""
    rnd = random.Random(seed); o = Obj(); pt = []
    pitch = -math.radians(32)
    W, D = 5.4, 2.2
    box(o, "Plank", (0, 0.5, -0.6), W, 1.0, 3.6, tris_out=pt)                              # plinth
    steps = [(-1.55, 1.0, ("sun", "top")), (-0.55, 1.75, ("fedora", "cloche")), (0.45, 2.5, ("boater", "bowler"))]
    k = 0
    for si, (zc, top, pair) in enumerate(steps):
        if si > 0: box(o, "Plank", (0, (1.0 + top) / 2, zc), W, top - 1.0, 1.0, tris_out=pt)
        g = _Group()
        g.box("Trim", (0, top + 0.05, zc), W, 0.1, D)                                         # cream tray, tilted with the hats
        for j, st in enumerate(pair):
            k += 1
            _hat_g(g, k, -1.4 + 2.8 * j, top + 0.1, zc, st, rnd)
        g.emit(o, (0, top, zc - D / 2), pitch)
    # hat boxes on the floor at both ends
    _hat_box(o, 21, -2.45, 0.0, 1.5, 0.62, 0.7); _hat_box(o, 23, -2.4, 0.72, 1.55, 0.52, 0.55)
    _hat_box(o, 25, 2.45, 0.0, 1.5, 0.58, 0.62)
    # back shelf with three upright hats and boxes under it
    _shelf_unit(o, pt, w=5.6, d=1.2, z=2.0, levels=(4.2,), top=5.4, name="Plank")
    g = _Group()
    for j, st in enumerate(("beret", "fedora", "boater")):
        k += 1
        _hat_g(g, k, -1.9 + 1.9 * j, 4.26, 2.0, st, rnd)
    g.emit(o, (0, 0, 0), 0.0)
    _hat_box(o, 27, -0.9, 0.0, 2.0, 0.6, 0.6); _hat_box(o, 29, 0.9, 0.0, 2.0, 0.55, 0.5); _hat_box(o, 31, 0.0, 0.62, 2.0, 0.5, 0.45)
    o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

''' + s[d1:]
p.write_text(s, encoding="utf-8"); print("hats v3 written")
