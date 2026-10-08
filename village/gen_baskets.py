"""Bike basket fillers for the three village bicycles, in the village kit's low-poly flat-shaded style.
Kept out of gen_village.py so none of the approved kit files are regenerated.

Coordinates: kit studs, Y up, origin = centre of the basket floor's top surface on the bicycle kit
(bicycle.obj basket floor top at (1.75, 3.0, 0)); inside the basket x in +-0.41, z in +-0.46, rim at y 0.6.
The bikes stand at scale 0.85; the builder/placer scales these the same.

basket_flowers  a bunch of flower heads (Flower1..) on stems, two lavender sprigs (Lavender1..), leaves over the rim
basket_bread    a white paper bag (Trim) with three baguettes leaning out (Bread) and a round loaf
basket_mixed    two baguettes in a smaller bag on one side, flowers and leaves on the other

Writes basket_*.obj/.mtl, baskets_v1.obj/.mtl (merged "<kit>__<piece>" for one Import 3D) and baskets_v1.json
(each filler's bounds relative to the basket origin, used to seat it in the Roblox baskets).
Run: python gen_baskets.py"""
import json, math, random, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "forest"))
import gen_forest as F
from gen_forest import Obj, ring, tube, icoblob

OUT = Path(__file__).parent
F.GRAYS.update({"Flower": (0.90, 0.45, 0.55), "Lavender": (0.70, 0.55, 0.85), "Leaf": (0.45, 0.62, 0.40),
                "Bread": (0.85, 0.62, 0.35), "Trim": (0.95, 0.94, 0.90), "Bench": (0.50, 0.42, 0.36),
                "Flour": (0.97, 0.93, 0.80)})


def box(name, c, sx, sy, sz, out):
    x, y, z = c; hx, hy, hz = sx / 2, sy / 2, sz / 2
    P = [(x + dx, y + dy, z + dz) for dx in (-hx, hx) for dy in (-hy, hy) for dz in (-hz, hz)]
    def q(a, b, c2, d): return [(P[a], P[b], P[c2]), (P[a], P[c2], P[d])]
    for f in (q(0, 1, 3, 2), q(4, 6, 7, 5), q(0, 4, 5, 1), q(2, 3, 7, 6), q(0, 2, 6, 4), q(1, 5, 7, 3)):
        out += f


def rotate(p, rx=0.0, rz=0.0, ry=0.0):
    x, y, z = p
    c, s = math.cos(rx), math.sin(rx); y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(rz), math.sin(rz); x, y = x * c - y * s, x * s + y * c
    c, s = math.cos(ry), math.sin(ry); x, z = x * c + z * s, -x * s + z * c
    return (x, y, z)


def placed(tris, at, rx=0.0, rz=0.0, ry=0.0):
    """Triangles built around the origin, rotated, then moved to `at`."""
    return [tuple(F.add(at, rotate(p, rx, rz, ry)) for p in t) for t in tris]


class Filler:
    def __init__(self): self.pieces = {}
    def add(self, name, tris): self.pieces.setdefault(name, []).extend(tris)
    def blob(self, name, c, r, rnd, jitter=0.08, squash=(1, 1, 1)):
        t = []; icoblob(None, name, c, r, rnd, jitter, squash, tris_out=t); self.add(name, t)
    def stem(self, x0, z0, x1, y1, z1, r=0.028):
        t = []; tube(None, "Leaf", [ring((x0, 0, z0), r, 0.25, 5), ring((x1, 0, z1), r, y1, 5)], ((x0 + x1) / 2, y1 / 2, (z0 + z1) / 2), tris_out=t)
        # tube() only faces outward when it adds the faces itself: turn every triangle away from the stem's axis
        a, b = (x0, 0.25, z0), (x1, y1, z1)
        ab = F.sub(b, a); L2 = F.dot(ab, ab) or 1e-9
        fixed = []
        for (p0, p1, p2) in t:
            n = F.cross(F.sub(p1, p0), F.sub(p2, p0)); cen = F.mul(F.add(F.add(p0, p1), p2), 1 / 3)
            k = max(0.0, min(1.0, F.dot(F.sub(cen, a), ab) / L2))
            if F.dot(n, F.sub(cen, F.add(a, F.mul(ab, k)))) < 0: p1, p2 = p2, p1
            fixed.append((p0, p1, p2))
        self.add("Leaf", fixed)
    def baguette(self, bottom, length, rx, rz, rnd, ry=0.0, sleeve=False):
        """A baguette along Y with blunt rounded ends, slightly flattened; built at the origin, tilted, then moved
        so its bottom end sits at `bottom` (inside the paper bag)."""
        R, segs, sides = 0.15, 10, 8
        rings_ = []
        for i in range(segs + 1):
            u = -1 + 2 * i / segs
            prof = max(0.38, (1 - abs(u) ** 5) ** 0.5)
            r = R * prof * (1 + rnd.uniform(-0.04, 0.04))
            y = u * length / 2
            rings_.append([(r * math.cos(2 * math.pi * k / sides), y, 0.85 * r * math.sin(2 * math.pi * k / sides)) for k in range(sides)])
        raw = []
        tube(None, "Bread", rings_, (0, 0, 0), cap_bottom=True, cap_top=True, tris_out=raw)
        a, b = (0, -length / 2, 0), (0, length / 2, 0)
        ab = F.sub(b, a); L2 = F.dot(ab, ab)
        body = []
        for (p0, p1, p2) in raw:
            n = F.cross(F.sub(p1, p0), F.sub(p2, p0)); cen = F.mul(F.add(F.add(p0, p1), p2), 1 / 3)
            k = max(0.0, min(1.0, F.dot(F.sub(cen, a), ab) / L2))
            axis = F.add(a, F.mul(ab, k))
            if abs(k) < 1e-6 or abs(k - 1) < 1e-6: axis = (0, cen[1] - (0.2 if k < 0.5 else -0.2), 0)   # end caps face outward along Y
            if F.dot(n, F.sub(cen, axis)) < 0: p1, p2 = p2, p1
            body.append((p0, p1, p2))
        at = F.sub(bottom, rotate((0.0, -length / 2, 0.0), rx, rz, ry))
        self.add("Bread", placed(body, at, rx, rz, ry))
        if sleeve:     # bakery paper wrapped round the lower part: an open ring tube, faces on both sides
            y0, y1, rs = -length / 2 - 0.02, -length / 2 + 0.42 * length, R * 1.3
            r0 = [(rs * math.cos(2 * math.pi * k / sides), y0, 0.85 * rs * math.sin(2 * math.pi * k / sides)) for k in range(sides)]
            r1 = [(rs * math.cos(2 * math.pi * k / sides), y1, 0.85 * rs * math.sin(2 * math.pi * k / sides)) for k in range(sides)]
            sl = []
            for k in range(sides):
                j = (k + 1) % sides
                sl += [(r0[k], r1[j], r0[j]), (r0[k], r1[k], r1[j]), (r0[k], r0[j], r1[j]), (r0[k], r1[j], r1[k])]
            self.add("Trim", placed(sl, at, rx, rz, ry))
        # clearance: below the rim (y 0.62) the baguette must stay inside the wicker walls
        bad = []
        for i in range(21):
            q = F.add(at, rotate((0.0, -length / 2 + length * i / 20, 0.0), rx, rz, ry))
            if q[1] <= 0.62 and (abs(q[0]) > 0.41 - 0.14 or abs(q[2]) > 0.46 - 0.13):
                bad.append("(%.2f,%.2f,%.2f)" % q)
        if bad: print("  WARNING baguette crosses the basket wall at", " ".join(bad[:3]))
    def bounds(self):
        pts = [p for tris in self.pieces.values() for t in tris for p in t]
        return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]
    def write(self, name):
        o = Obj()
        for piece, tris in self.pieces.items(): o.add_flat(piece, tris)
        o.write(OUT / f"{name}.obj")


def flowers(f, rnd, xs=(-0.36, 0.36), zs=(-0.40, 0.40), heads=8, lavender=2, first=1):
    """Leaves filling the basket top, stems, round flower heads and tall lavender sprigs inside the x/z range."""
    cx, cz = (xs[0] + xs[1]) / 2, (zs[0] + zs[1]) / 2
    hw, hd = (xs[1] - xs[0]) / 2, (zs[1] - zs[0]) / 2
    for (u, v, y, r) in ((-0.55, -0.55, 0.46, 0.26), (0.55, -0.5, 0.48, 0.25), (-0.5, 0.55, 0.47, 0.25),
                         (0.5, 0.55, 0.45, 0.26), (0.0, 0.0, 0.55, 0.28)):
        f.blob("Leaf", (cx + u * hw, y, cz + v * hd), r * min(1.0, 1.4 * min(hw, hd) / 0.4), rnd, 0.14, (1.15, 0.7, 1.15))
    spots = [(-0.55, -0.5, 1.00), (0.5, -0.55, 1.08), (0.0, 0.05, 1.18), (-0.6, 0.45, 0.95), (0.55, 0.45, 1.02),
             (0.1, -0.85, 0.88), (-0.1, 0.85, 0.9), (0.85, 0.0, 0.92), (-0.85, 0.0, 0.96)]
    for k in range(heads):
        u, v, y = spots[k]
        x, z = cx + u * hw, cz + v * hd
        f.stem(cx + u * hw * 0.4, cz + v * hd * 0.4, x, y - 0.1, z)
        f.blob(f"Flower{first + k}", (x, y, z), rnd.uniform(0.15, 0.19), rnd, 0.1, (1.0, 0.8, 1.0))
    for k, (u, v) in enumerate(((-0.8, -0.1), (0.75, 0.75))[:lavender]):
        x, z = cx + u * hw, cz + v * hd
        f.stem(x * 0.5, z * 0.5, x, 1.0, z, 0.022)
        f.blob(f"Lavender{k + 1}", (x, 1.18, z), 0.26, rnd, 0.06, (0.32, 1.0, 0.32))


def bread_bag(f, cx, cz, w, d, h):
    """An open-topped paper bag: four thin walls and a floor, so the baguettes visibly stand inside it."""
    t = 0.035
    box("Trim", (cx, 0.02, cz), w, 0.04, d, f.pieces.setdefault("Trim", []))
    for sx in (-1, 1):
        box("Trim", (cx + sx * (w / 2 - t / 2), h / 2, cz), t, h, d, f.pieces["Trim"])
    for sz in (-1, 1):
        box("Trim", (cx, h / 2, cz + sz * (d / 2 - t / 2)), w, h, t, f.pieces["Trim"])
    # folded-over rim band a little proud of the walls
    for sx in (-1, 1):
        box("Trim", (cx + sx * (w / 2 + 0.01), h - 0.06, cz), 0.03, 0.12, d + 0.06, f.pieces["Trim"])
    for sz in (-1, 1):
        box("Trim", (cx, h - 0.06, cz + sz * (d / 2 + 0.01)), w + 0.06, 0.12, 0.03, f.pieces["Trim"])


meta = {}

rnd = random.Random(31)
f = Filler()
flowers(f, rnd)
f.write("basket_flowers"); meta["basket_flowers"] = f.bounds()

rnd = random.Random(47)
f = Filler()
# three baguettes planted at the front of the basket, all leaning back toward the rider (toward -X), fanned a little
for (bx, bz, rx, rz, L, sl) in ((0.2, -0.17, math.radians(-6), math.radians(28), 1.75, True),
                                (0.22, 0.0, math.radians(1), math.radians(33), 1.9, True),
                                (0.18, 0.17, math.radians(7), math.radians(24), 1.65, False)):
    f.baguette((bx, 0.05, bz), L, rx, rz, rnd, 0.0, sl)
f.blob("Bread", (-0.24, 0.18, 0.3), 0.2, rnd, 0.07, (1.0, 0.72, 1.0))
f.write("basket_bread"); meta["basket_bread"] = f.bounds()

rnd = random.Random(59)
f = Filler()
# two baguettes on the +X half, planted at one side and leaning across the bike (toward +Z), clear of the flowers
for (bx, bz, rx, rz, L, sl) in ((0.2, -0.28, math.radians(26), math.radians(-4), 1.7, True),
                                (0.24, -0.08, math.radians(20), math.radians(3), 1.8, False)):
    f.baguette((bx, 0.05, bz), L, rx, rz, rnd, 0.0, sl)
flowers(f, rnd, xs=(-0.38, 0.0), zs=(-0.40, 0.40), heads=5, lavender=1)
f.write("basket_mixed"); meta["basket_mixed"] = f.bounds()

# merge for one Import 3D (same pattern as merge_bakeryb_v1.py)
KIT = ["basket_flowers", "basket_bread", "basket_mixed"]
V, VT, VN, OBJS, MTL = [], [], [], [], []
x = 0.0
shift = {}
for k in KIT:
    lines = (OUT / f"{k}.obj").read_text().splitlines()
    v = [tuple(map(float, l.split()[1:])) for l in lines if l.startswith("v ")]
    xs = [p[0] for p in v]; w = max(xs) - min(xs)
    off = x - min(xs); shift[k] = off
    bv, bvt, bvn = len(V), len(VT), len(VN)
    V += [(p[0] + off, p[1], p[2]) for p in v]
    VT += [l for l in lines if l.startswith("vt ")]
    VN += [l for l in lines if l.startswith("vn ")]
    for l in lines:
        if l.startswith("o "):
            OBJS.append((f"{k}__{l[2:].strip()}", []))
        elif l.startswith("f "):
            parts = []
            for tok in l.split()[1:]:
                a, b, c = tok.split("/")
                parts.append(f"{int(a) + bv}/{int(b) + bvt}/{int(c) + bvn}")
            OBJS[-1][1].append("f " + " ".join(parts))
    MTL.append((OUT / f"{k}.mtl").read_text().replace("newmtl m_", f"newmtl m_{k}__"))
    x += w + 3.0
out = ["mtllib baskets_v1.mtl"] + [f"v {a:.4f} {b:.4f} {c:.4f}" for a, b, c in V] + VT + VN
for name, faces in OBJS:
    out += [f"o {name}", f"g {name}", f"usemtl m_{name}", "s off"] + faces
(OUT / "baskets_v1.obj").write_text("\n".join(out) + "\n")
(OUT / "baskets_v1.mtl").write_text("".join(MTL))
json.dump({k: {"min": meta[k][0], "max": meta[k][1], "merge_shift_x": shift[k]} for k in KIT},
          open(OUT / "baskets_v1.json", "w"), indent=1)
for k in KIT:
    mn, mx = meta[k]
    print(k, "bounds x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % (mn[0], mx[0], mn[1], mx[1], mn[2], mx[2]))
print("baskets_v1.obj:", len(V), "verts,", sum(len(fc) for _, fc in OBJS), "tris,", len(OBJS), "pieces")
