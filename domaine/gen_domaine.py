"""
Domaine des Écureuils kit for 1001 Squirrels: Provençal countryside (lavender field, vineyard, farm) in the same
low-poly flat-shaded untextured style as the forest and village kits. Every prop is one .obj; colour-able pieces are
separate objects named by material so the builder can tint them. Units are studs, Y up, every prop stands on y = 0
and faces -Z.

Batch 1 (vegetation): lavender_row_a/b, vine_row_a/b, cypress, olive_tree, sunflower_patch, boxwood, oleander
Run:  python gen_domaine.py
"""
import math, random, sys
from pathlib import Path
HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent / "village"))
sys.path.insert(0, str(HERE.parent / "forest"))
import gen_forest as F
from gen_forest import Obj, ring, tube, icoblob, trunk, add, mul, sub, norm, cross, dot
from gen_village import box, extrude, extrude_ring, arch_profile, rect_profile, thick_quad

OUT = HERE
F.GRAYS.update({
    # vegetation
    "Lav": (0.55, 0.40, 0.80), "Sage": (0.62, 0.70, 0.60), "Soil": (0.40, 0.30, 0.22),
    "VPost": (0.55, 0.42, 0.30), "Wire": (0.30, 0.30, 0.32), "VTrunk": (0.40, 0.30, 0.22), "VLeaf": (0.45, 0.62, 0.30),
    "GrapeG": (0.65, 0.75, 0.40), "Grape": (0.42, 0.25, 0.50),
    "Cypress": (0.20, 0.35, 0.22), "Olive": (0.60, 0.66, 0.52), "OTrunk": (0.45, 0.38, 0.30),
    "SStem": (0.35, 0.50, 0.25), "SLeaf": (0.40, 0.58, 0.28), "Petal": (0.95, 0.78, 0.15), "Seed": (0.35, 0.22, 0.12),
    "Boxwood": (0.30, 0.45, 0.25), "Oleander": (0.35, 0.50, 0.30), "Bloom": (0.98, 0.97, 0.95),
})


# ------------------------------------------------------------- small helpers ----
def basis(n):
    """Two unit vectors perpendicular to n (and to each other)."""
    n = norm(n)
    a = (1, 0, 0) if abs(n[0]) < 0.9 else (0, 1, 0)
    u = norm(cross(a, n)); v = cross(n, u)
    return u, v


def ring_n(center, normal, r, sides, phase=0.0):
    """A ring of points around `center` in the plane perpendicular to `normal`."""
    u, v = basis(normal)
    pts = []
    for i in range(sides):
        t = phase + 2 * math.pi * i / sides
        pts.append(add(center, add(mul(u, r * math.cos(t)), mul(v, r * math.sin(t)))))
    return pts


def disc(tris, center, normal, r, thick, sides):
    """A short cylinder (both caps) with its axis along `normal`, e.g. a sunflower head."""
    n = norm(normal)
    r0 = ring_n(sub(center, mul(n, thick / 2)), n, r, sides)
    r1 = ring_n(add(center, mul(n, thick / 2)), n, r, sides)
    body = []
    for i in range(sides):
        j = (i + 1) % sides
        body += [(r0[i], r0[j], r1[j]), (r0[i], r1[j], r1[i])]
    c0, c1 = sub(center, mul(n, thick / 2)), add(center, mul(n, thick / 2))
    for i in range(sides):
        j = (i + 1) % sides
        body += [(c1, r1[i], r1[j]), (c0, r0[j], r0[i])]
    # orient every triangle away from the centre
    for a, b, c in body:
        fn = cross(sub(b, a), sub(c, a)); cen = mul(add(add(a, b), c), 1 / 3)
        if dot(fn, sub(cen, center)) < 0: b, c = c, b
        tris.append((a, b, c))


def stem(tris, p0, p1, r0, r1, sides=4):
    """A thin tapered tube from p0 to p1 (no caps)."""
    d = sub(p1, p0)
    a = ring_n(p0, d, r0, sides); b = ring_n(p1, d, r1, sides)
    for i in range(sides):
        j = (i + 1) % sides
        tris += [(a[i], a[j], b[j]), (a[i], b[j], b[i])]
    # outward orientation about the stem axis
    out = []
    axis0, axis1 = p0, p1
    for t in tris[-2 * sides:]:
        pa, pb, pc = t
        cen = mul(add(add(pa, pb), pc), 1 / 3)
        # closest point on the axis
        ad = sub(axis1, axis0); L2 = dot(ad, ad) or 1e-9
        k = max(0.0, min(1.0, dot(sub(cen, axis0), ad) / L2))
        foot = add(axis0, mul(ad, k))
        fn = cross(sub(pb, pa), sub(pc, pa))
        out.append((pa, pc, pb) if dot(fn, sub(cen, foot)) < 0 else (pa, pb, pc))
    tris[-2 * sides:] = out


def blob(tris, center, r, rnd, jitter=0.16, squash=(1, 1, 1)):
    icoblob(None, "", center, r, rnd, jitter, squash, tris_out=tris)


def tube_out(tris, rings, p0, p1, cap_bottom=False, cap_top=False):
    """Stitch rings into a tube and orient every face away from the axis p0-p1 (rings may run either way)."""
    body = []
    tube(None, "", rings, p0, cap_bottom=cap_bottom, cap_top=cap_top, tris_out=body)
    ad = sub(p1, p0); L2 = dot(ad, ad) or 1e-9
    for a, b, c in body:
        cen = mul(add(add(a, b), c), 1 / 3)
        k = dot(sub(cen, p0), ad) / L2
        foot = add(p0, mul(ad, k))
        ref = sub(cen, foot)
        if k <= 0.001 or k >= 0.999:                    # a cap: face along the axis, away from the middle
            ref = mul(ad, -1) if k <= 0.001 else ad
        fn = cross(sub(b, a), sub(c, a))
        tris.append((a, c, b) if dot(fn, ref) < 0 else (a, b, c))


def cyl(tris, center, r_bot, r_top, h, sides, phase=0.0, cap_bottom=True, cap_top=True, rnd=None, jitter=0.0):
    """A vertical (tapered) cylinder standing on center.y."""
    x, y, z = center
    r0 = ring((x, y, z), r_bot, 0, sides, phase, jitter, rnd); r1 = ring((x, y, z), r_top, h, sides, phase, jitter, rnd)
    tube_out(tris, [r0, r1], (x, y, z), (x, y + h, z), cap_bottom, cap_top)


def beam(tris, p0, p1, w, h, roll=0.0):
    """A rectangular bar from p0 to p1 with cross-section w (sideways) x h (up)."""
    d = norm(sub(p1, p0))
    side = norm(cross((0, 1, 0), d)) if abs(d[1]) < 0.98 else (1, 0, 0)
    up = norm(cross(d, side))
    if roll:
        c, s = math.cos(roll), math.sin(roll)
        side, up = add(mul(side, c), mul(up, s)), add(mul(up, c), mul(side, -s))
    hs, hu = mul(side, w / 2), mul(up, h / 2)
    A = [add(add(p0, mul(hs, sx)), mul(hu, sy)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    B = [add(add(p1, mul(hs, sx)), mul(hu, sy)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    tube_out(tris, [A, B], p0, p1, True, True)


class Kit:
    """Collects triangles per piece name and writes one .obj."""
    def __init__(self): self.p = {}
    def t(self, name): return self.p.setdefault(name, [])
    def write(self, name):
        o = Obj()
        for k, v in self.p.items():
            if v: o.add_flat(k, v)
        return o.write(OUT / f"{name}.obj")


# ------------------------------------------------------------- lavender ----
def spike(tris, p1, d, length, r_mid, sides=4):
    """A slender lavender head: a tapered tube from p1 along d, pointed at the tip, faces outward."""
    rings = [ring_n(add(p1, mul(d, k * length / 3)), d, r, sides, 0.3) for k, r in enumerate((0.45 * r_mid, r_mid, 0.95 * r_mid, 0.4 * r_mid))]
    head = []
    tube(None, "", rings, p1, cap_top=False, cap_bottom=False, tris_out=head)
    tip = add(p1, mul(d, length + 0.08))
    last = rings[-1]
    for i in range(sides):
        head.append((tip, last[i], last[(i + 1) % sides]))
    for a, b, c in head:
        cen = mul(add(add(a, b), c), 1 / 3)
        k = dot(sub(cen, p1), d); foot = add(p1, mul(d, k))
        fn = cross(sub(b, a), sub(c, a))
        tris.append((a, c, b) if dot(fn, sub(cen, foot)) < 0 else (a, b, c))


def lavender_bush(lav, sage, cx, cz, rnd, spikes=36):
    """One mounded lavender bush ~3.2 studs wide, 2.4 tall. A low silvery foliage mound, a low violet filler blob, and a
    dense crowd of slender violet heads leaning outward from the top (the purple mass IS the heads, as in the
    reference renders); only the outer heads show a bit of stem."""
    blob(sage, (cx, 0.52, cz), 1.30, rnd, 0.05, (1.05, 0.40, 0.95))               # foliage: low, mostly hidden
    blob(lav, (cx, 1.05, cz), 1.48, rnd, 0.07, (1.08, 0.46, 0.98))                # the violet mass overhangs it
    R = 1.40
    for _ in range(spikes):
        ang = rnd.uniform(0, 2 * math.pi); rr = R * math.sqrt(rnd.random())
        x, z = cx + rr * math.cos(ang), cz + rr * math.sin(ang) * 0.92
        surf = 1.05 + 0.46 * 1.48 * math.sqrt(max(0.0, 1 - (rr / 1.55) ** 2))
        tilt = 0.42 * rr / R
        d = norm((tilt * math.cos(ang) + rnd.uniform(-0.08, 0.08), 1.0, tilt * math.sin(ang) + rnd.uniform(-0.08, 0.08)))
        base = (x, surf - 0.15 + rnd.uniform(0, 0.15), z)
        if rr > 0.75 * R:
            p0 = add(base, mul(d, -0.32))
            stem(sage, p0, base, 0.045, 0.04, 4)
        spike(lav, base, d, rnd.uniform(0.72, 0.98), 0.125)


def lavender_row(name, seed, n=8, pitch=2.6):
    rnd = random.Random(seed); o = Obj()
    lav, sage = [], []
    x0 = -(n - 1) * pitch / 2
    for k in range(n):
        lavender_bush(lav, sage, x0 + k * pitch + rnd.uniform(-0.25, 0.25), rnd.uniform(-0.25, 0.25), rnd)
    o.add_flat("Lav", lav); o.add_flat("Sage", sage)
    return o.write(OUT / f"{name}.obj")


# ------------------------------------------------------------- vines ----
def vine_row(name, seed, L=24.0, post_pitch=6.0, plant_pitch=3.0):
    """A trellis row: posts, three wires, gnarled trunks with arms along the bottom wire, a leafy wall, grape bunches."""
    rnd = random.Random(seed); o = Obj()
    posts, wires, trunks, leaves, grapes, grapesG = [], [], [], [], [], []
    nposts = int(round(L / post_pitch)) + 1
    for k in range(nposts):
        x = -L / 2 + k * post_pitch
        box(o, "VPost", (x, 2.6, 0), 0.36, 5.2, 0.36, tris_out=posts)
    for y in (2.0, 3.2, 4.4):
        box(o, "Wire", (0, y, 0), L, 0.06, 0.06, tris_out=wires)
    nplants = int(round(L / plant_pitch))
    for k in range(nplants):
        x = -L / 2 + plant_pitch / 2 + k * plant_pitch + rnd.uniform(-0.2, 0.2)
        lean = (rnd.uniform(-0.08, 0.08), rnd.uniform(-0.05, 0.05))
        trunk(o, "VTrunk", (x, 0, 0), 0.30, 0.17, 2.1, 6, rnd, lean=lean, flare=1.35)
        top = (x + lean[0] * 2.1, 2.1, lean[1] * 2.1)
        for sgn in (-1, 1):                                                    # arms tied along the bottom wire
            stem(trunks, top, (x + sgn * 1.45, 2.05, 0.0), 0.13, 0.08, 5)
        for i in range(5):                                                      # the leafy wall
            lx = x + rnd.uniform(-1.5, 1.5); ly = rnd.uniform(2.9, 4.3); lz = rnd.uniform(-0.35, 0.35)
            blob(leaves, (lx, ly, lz), rnd.uniform(0.80, 1.0), rnd, 0.24, (1.25, 0.85, 0.75))
        for i in range(3):                                                      # bunches hanging below the leaves
            gx = x + rnd.uniform(-1.2, 1.2); gy = rnd.uniform(2.25, 2.85); gz = rnd.choice((-1, 1)) * rnd.uniform(0.45, 0.62)
            blob(grapes if rnd.random() < 0.7 else grapesG, (gx, gy, gz), rnd.uniform(0.25, 0.31), rnd, 0.30, (0.78, 1.4, 0.78))   # bumpy: a bunch, not a potato
    o.add_flat("VPost", posts); o.add_flat("Wire", wires); o.add_flat("VTrunk", trunks)
    o.add_flat("VLeaf", leaves); o.add_flat("Grape", grapes); o.add_flat("GrapeG", grapesG)
    return o.write(OUT / f"{name}.obj")


# ------------------------------------------------------------- trees ----
def cypress(name, seed, height=21.0):
    """A slim faceted spire: one tube whose rings swell then taper, with a little jitter so it is not a cone."""
    rnd = random.Random(seed); o = Obj()
    trunk(o, "OTrunk", (0, 0, 0), 0.38, 0.28, 2.0, 6, rnd)
    prof = [(0.07, 0.55), (0.16, 1.35), (0.30, 1.95), (0.45, 2.15), (0.60, 2.0), (0.73, 1.65), (0.84, 1.2), (0.93, 0.7), (0.985, 0.25)]
    rings = [ring((rnd.uniform(-0.12, 0.12), 0, rnd.uniform(-0.12, 0.12)), r, height * t, 7, 0.25 * k, 0.09, rnd) for k, (t, r) in enumerate(prof)]
    fol = []
    tube(None, "", rings, (0, height * 0.5, 0), cap_bottom=True, cap_top=True, tris_out=fol)
    o.add_flat("Cypress", fol, (0, height * 0.5, 0))
    return o.write(OUT / f"{name}.obj")


def olive_tree(name, seed):
    rnd = random.Random(seed); o = Obj()
    trunk(o, "OTrunk", (0, 0, 0), 0.75, 0.42, 4.6, 7, rnd, lean=(0.06, 0.03), flare=1.45)
    limbs = []
    top = (0.06 * 4.6, 4.6, 0.03 * 4.6)
    for ang in (0.4, 2.3, 4.1, 5.6):
        end = (top[0] + 2.4 * math.cos(ang), 6.3 + rnd.uniform(-0.4, 0.5), top[2] + 2.4 * math.sin(ang))
        stem(limbs, top, end, 0.30, 0.16, 5)
    o.add_flat("OTrunk", limbs)
    fol = []
    for ang, r, y in ((0.4, 2.1, 7.2), (2.3, 2.3, 7.5), (4.1, 2.0, 7.0), (5.6, 2.2, 7.4), (0.0, 2.4, 8.4)):
        c = (top[0] + 1.6 * math.cos(ang) * (0 if ang == 0.0 else 1), y, top[2] + 1.6 * math.sin(ang) * (0 if ang == 0.0 else 1))
        blob(fol, c, r, rnd, 0.22, (1.2, 0.8, 1.1))
    o.add_flat("Olive", fol)
    return o.write(OUT / f"{name}.obj")


# ------------------------------------------------------------- sunflowers ----
def sunflower(stems, leaves, petals, seeds, x, z, rnd, h):
    lean = (rnd.uniform(-0.05, 0.05), rnd.uniform(-0.04, 0.04))
    top = (x + lean[0] * h, h, z + lean[1] * h)
    stem(stems, (x, 0, z), top, 0.14, 0.10, 5)
    for ly, side in ((0.36, -1), (0.58, 1)):
        p = (x + lean[0] * h * ly, h * ly, z + lean[1] * h * ly)
        ang = rnd.uniform(0, 2 * math.pi)
        d = (math.cos(ang), 0.25, math.sin(ang))
        tipp = add(p, mul(d, 1.35)); mid_l = add(add(p, mul(d, 0.7)), mul((-d[2], 0, d[0]), 0.48)); mid_r = add(add(p, mul(d, 0.7)), mul((d[2], 0, -d[0]), 0.48))
        thick_quad(leaves, p, mid_l, tipp, mid_r, 0.05)                        # a diamond leaf on a short stalk
    # the head faces the front (-z) and tips down a little, like a heavy flower
    n = norm((0.0, -0.42, -1.0))
    hc = add(top, mul(n, 0.25))
    disc(seeds, hc, n, 0.78, 0.26, 10)
    u, v = basis(n)
    for i in range(14):
        t = 2 * math.pi * i / 14 + rnd.uniform(-0.08, 0.08)
        rad = add(mul(u, math.cos(t)), mul(v, math.sin(t))); tan = add(mul(u, -math.sin(t)), mul(v, math.cos(t)))
        base = add(hc, mul(rad, 0.70)); tip = add(hc, mul(rad, 1.55 + rnd.uniform(-0.08, 0.08)))
        A = add(base, mul(tan, 0.17)); B = add(base, mul(tan, -0.17)); C = add(tip, mul(tan, -0.06)); D = add(tip, mul(tan, 0.06))
        thick_quad(petals, A, B, C, D, 0.05)


def sunflower_patch(name, seed, n=7, w=7.0):
    rnd = random.Random(seed); o = Obj()
    stems, leaves, petals, seeds = [], [], [], []
    spots = [(-2.4, -2.2), (0.2, -2.6), (2.5, -2.0), (-1.4, 0.2), (1.6, 0.5), (-2.6, 2.4), (0.6, 2.6), (2.7, 2.6)]
    for k in range(n):
        x, z = spots[k]
        sunflower(stems, leaves, petals, seeds, x + rnd.uniform(-0.3, 0.3), z + rnd.uniform(-0.3, 0.3), rnd, rnd.uniform(5.2, 7.0))
    o.add_flat("SStem", stems); o.add_flat("SLeaf", leaves); o.add_flat("Petal", petals); o.add_flat("Seed", seeds)
    return o.write(OUT / f"{name}.obj")


# ------------------------------------------------------------- shrubs ----
def boxwood(name, seed):
    rnd = random.Random(seed); o = Obj()
    b = []
    blob(b, (0, 1.15, 0), 1.3, rnd, 0.06, (1.0, 0.88, 1.0))
    o.add_flat("Boxwood", b)
    return o.write(OUT / f"{name}.obj")


def oleander(name, seed):
    rnd = random.Random(seed); o = Obj()
    g, w = [], []
    for c, r in (((-1.3, 1.6, 0.3), 1.35), ((1.3, 1.7, -0.4), 1.4), ((0.0, 2.7, 0.2), 1.3), ((0.2, 1.3, 0.9), 1.2), ((-0.4, 1.4, -1.0), 1.2), ((0.9, 2.6, 0.6), 1.1), ((-1.0, 2.5, -0.5), 1.1)):
        blob(g, c, r, rnd, 0.14, (1.15, 0.95, 1.05))
    for _ in range(11):
        ang = rnd.uniform(0, 2 * math.pi); el = rnd.uniform(0.15, 1.2)
        c = (2.1 * math.cos(ang) * math.cos(el), 2.0 + 2.2 * math.sin(el), 1.9 * math.sin(ang) * math.cos(el))
        blob(w, c, rnd.uniform(0.32, 0.42), rnd, 0.1)
    o.add_flat("Oleander", g); o.add_flat("Bloom", w)
    return o.write(OUT / f"{name}.obj")


if __name__ == "__main__":
    counts = {}
    counts["lavender_row_a"] = lavender_row("lavender_row_a", 101)
    counts["lavender_row_b"] = lavender_row("lavender_row_b", 102)
    counts["vine_row_a"] = vine_row("vine_row_a", 111)
    counts["vine_row_b"] = vine_row("vine_row_b", 112)
    counts["cypress"] = cypress("cypress", 121)
    counts["olive_tree"] = olive_tree("olive_tree", 122)
    counts["sunflower_patch"] = sunflower_patch("sunflower_patch", 131)
    counts["boxwood"] = boxwood("boxwood", 141)
    counts["oleander"] = oleander("oleander", 142)
    for k, v in counts.items():
        print(f"{k:16s} {v:6d} tris")
