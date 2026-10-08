"""
Forest kit for Chasing Rainbows: low-poly, flat-shaded, UNTEXTURED props in grays so the game's own colouring
system can tint them (MeshPart.Color). Every prop is one .obj; the pieces that should take different colours are
separate objects inside it (Trunk / Foliage, Cap / Stem ...), each with its own material, so Studio's Import 3D
keeps them as separate MeshParts when "Merge Meshes" is OFF.

Units are studs (OBJ imports 1:1). Y is up. Every prop stands on y = 0.

Outputs (in this folder):  pine_tall.obj, pine_mid.obj, pine_squat.obj, round_tree.obj, stump.obj, log_fallen.obj,
  log_hollow.obj, bush_big.obj, bush_small.obj, rock_big.obj, rock_cluster.obj, mushrooms.obj  (+ .mtl each)
Run:  python gen_forest.py
"""
import math
import random
from pathlib import Path

OUT = Path(__file__).parent

# ------------------------------------------------------------- vec ----
def add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def mul(a, s): return (a[0] * s, a[1] * s, a[2] * s)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def length(a): return math.sqrt(dot(a, a))
def norm(a):
    l = length(a) or 1.0
    return (a[0] / l, a[1] / l, a[2] / l)
def rot_y(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c + p[2] * s, p[1], -p[0] * s + p[2] * c)
def rot_x(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0], p[1] * c - p[2] * s, p[1] * s + p[2] * c)
def rot_z(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c, p[2])

# ------------------------------------------------------------- obj ----
GRAYS = {   # piece-name prefix -> Kd. Light = takes colour well when tinted; the builder script also sets these.
    "Foliage": (0.86, 0.87, 0.89),
    "Canopy":  (0.84, 0.86, 0.88),
    "Trunk":   (0.46, 0.45, 0.44),
    "Wood":    (0.52, 0.50, 0.48),
    "Rings":   (0.70, 0.68, 0.66),
    "Rock":    (0.62, 0.63, 0.65),
    "Leaf":    (0.80, 0.82, 0.84),
    "Cap":     (0.78, 0.76, 0.76),
    "Stem":    (0.92, 0.91, 0.90),
    "Spots":   (0.96, 0.96, 0.96),
}

class Obj:
    def __init__(self):
        self.v, self.vn, self.objects = [], [], []
    def add_flat(self, name, tris, center=None):
        """tris: list of (p0, p1, p2). If center is given, each triangle is flipped to face away from it."""
        verts, normals, faces = [], [], []
        for p0, p1, p2 in tris:
            fn = cross(sub(p1, p0), sub(p2, p0))
            if center is not None:
                cen = mul(add(add(p0, p1), p2), 1 / 3)
                if dot(fn, sub(cen, center)) < 0:
                    p1, p2 = p2, p1; fn = mul(fn, -1)
            if length(fn) < 1e-9:
                continue
            n = norm(fn); b = len(verts)
            verts += [p0, p1, p2]; normals += [n, n, n]
            faces.append((b, b + 1, b + 2))
        base = len(self.v)
        self.v += verts; self.vn += normals
        self.objects.append((name, [(a + base, b + base, c + base) for a, b, c in faces]))
    def write(self, path):
        lines = [f"mtllib {Path(path).with_suffix('.mtl').name}"]
        lines += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.v]
        lines += ["vt 0 0"]
        lines += [f"vn {x:.4f} {y:.4f} {z:.4f}" for x, y, z in self.vn]
        for name, faces in self.objects:
            lines += [f"o {name}", f"g {name}", f"usemtl m_{name}", "s off"]
            lines += [f"f {a+1}/1/{a+1} {b+1}/1/{b+1} {c+1}/1/{c+1}" for a, b, c in faces]
        Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")
        mtl = ""
        for name, _ in self.objects:
            kd = (0.8, 0.8, 0.8)
            for k, v in GRAYS.items():
                if name.startswith(k): kd = v
            mtl += f"newmtl m_{name}\nKd {kd[0]:.3f} {kd[1]:.3f} {kd[2]:.3f}\nKa 1 1 1\nKs 0 0 0\nd 1\nillum 1\n\n"
        Path(path).with_suffix(".mtl").write_text(mtl, encoding="utf-8")
        return sum(len(f) for _, f in self.objects)

# ------------------------------------------------------------- shapes ----
def ring(center, r, y, sides, yaw=0.0, jitter=0.0, rnd=None, tilt=(0.0, 0.0)):
    pts = []
    for i in range(sides):
        a = yaw + 2 * math.pi * i / sides
        rr = r * (1 + (rnd.uniform(-jitter, jitter) if rnd and jitter else 0))
        x, z = rr * math.cos(a), rr * math.sin(a)
        pts.append((center[0] + x, center[1] + y + x * tilt[0] + z * tilt[1], center[2] + z))
    return pts

def tube(o, name, rings, center, cap_bottom=False, cap_top=False, tris_out=None):
    """Stitch a list of rings (same vertex count) into flat-shaded quads (2 tris each) plus optional caps."""
    tris = tris_out if tris_out is not None else []
    n = len(rings[0])
    for k in range(len(rings) - 1):
        a, b = rings[k], rings[k + 1]
        for i in range(n):
            j = (i + 1) % n
            tris.append((a[i], a[j], b[j])); tris.append((a[i], b[j], b[i]))
    def cap(rg, up):
        c = mul(sum_pts(rg), 1 / n)
        c = (c[0], c[1] + (0.001 if up else -0.001), c[2])
        for i in range(n):
            j = (i + 1) % n
            tris.append((c, rg[j], rg[i]) if up else (c, rg[i], rg[j]))
    if cap_bottom: cap(rings[0], False)
    if cap_top: cap(rings[-1], True)
    if tris_out is None:
        o.add_flat(name, tris, center)
    return tris

def sum_pts(ps):
    s = (0.0, 0.0, 0.0)
    for p in ps: s = add(s, p)
    return s

def cone_tier(o, name, center, r, y0, h, sides, yaw, rnd, skirt=0.08, tris_out=None):
    """A pine tier: a wide ring at y0, a slightly smaller ring a bit below (the underside skirt) and an apex."""
    base = ring(center, r, y0, sides, yaw, 0.08, rnd)
    apex = (center[0] + rnd.uniform(-0.08, 0.08) * r, center[1] + y0 + h, center[2] + rnd.uniform(-0.08, 0.08) * r)
    tris = tris_out if tris_out is not None else []
    for i in range(sides):
        j = (i + 1) % sides
        tris.append((base[i], base[j], apex))
    c = mul(sum_pts(base), 1 / sides); c = (c[0], c[1] - 0.001, c[2])      # flat underside, nothing hanging below
    for i in range(sides):
        j = (i + 1) % sides
        tris.append((c, base[i], base[j]))
    if tris_out is None:
        o.add_flat(name, tris, (center[0], center[1] + y0 + h * 0.3, center[2]))
    return tris

def trunk(o, name, center, r_bot, r_top, h, sides, rnd, lean=(0.0, 0.0), y0=0.0, flare=1.0):
    rings = []
    steps = 3
    for k in range(steps + 1):
        t = k / steps
        r = r_bot + (r_top - r_bot) * t
        if k == 0: r *= flare
        c = (center[0] + lean[0] * t * h, center[1], center[2] + lean[1] * t * h)
        rings.append(ring(c, r, y0 + h * t, sides, 0.2 * k, 0.07, rnd))
    tube(o, name, rings, (center[0], center[1] + y0 + h * 0.5, center[2]), cap_bottom=True, cap_top=True)

def icoblob(o, name, center, radius, rnd, jitter=0.16, squash=(1.0, 1.0, 1.0), tris_out=None):
    """Low-poly faceted blob: icosahedron subdivided once (80 faces) with jittered vertex radii."""
    t = (1 + 5 ** 0.5) / 2
    base = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
            (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    faces = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
             (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    verts = [norm(p) for p in base]
    cache = {}
    def mid(a, b):
        k = (min(a, b), max(a, b))
        if k not in cache:
            cache[k] = len(verts); verts.append(norm(mul(add(verts[a], verts[b]), 0.5)))
        return cache[k]
    f2 = []
    for a, b, c in faces:
        ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
        f2 += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
    yaw = rnd.uniform(0, 6.28)
    pts = []
    for p in verts:
        rr = radius * (1 + rnd.uniform(-jitter, jitter))
        q = rot_y(p, yaw)
        pts.append((center[0] + q[0] * rr * squash[0], center[1] + q[1] * rr * squash[1], center[2] + q[2] * rr * squash[2]))
    tris = tris_out if tris_out is not None else []
    for a, b, c in f2:
        tris.append((pts[a], pts[b], pts[c]))
    if tris_out is None:
        o.add_flat(name, tris, center)
    return tris

def slab(center, radius, height, sides, rnd, taper=0.85, sx=1.0, sz=1.0, tilt=0.0, yaw=0.0):
    """Angular stone: irregular convex polygon extruded with a flat top (the look Shannon liked on the rocks)."""
    angs = [2 * math.pi * i / sides + rnd.uniform(-0.18, 0.18) for i in range(sides)]
    rad = [radius * rnd.uniform(0.85, 1.12) for _ in range(sides)]
    def rg(scale, y, shift):
        pts = []
        for a_, r in zip(angs, rad):
            x, z = r * scale * math.cos(a_) * sx, r * scale * math.sin(a_) * sz
            x, z = x * math.cos(yaw) - z * math.sin(yaw), x * math.sin(yaw) + z * math.cos(yaw)
            pts.append((center[0] + x + shift[0], center[1] + y + z * math.tan(tilt), center[2] + z + shift[1]))
        return pts
    shift = (rnd.uniform(-0.12, 0.12) * radius, rnd.uniform(-0.12, 0.12) * radius)
    bot, top = rg(1.0, 0.0, (0, 0)), rg(taper, height, shift)
    tris = []
    for i in range(sides):
        j = (i + 1) % sides
        tris.append((bot[i], bot[j], top[j])); tris.append((bot[i], top[j], top[i]))
    tc = mul(sum_pts(top), 1 / sides)
    for i in range(sides):
        j = (i + 1) % sides
        tris.append((tc, top[i], top[j]))
    bc = (center[0], center[1] - 0.01, center[2])
    for i in range(sides):
        j = (i + 1) % sides
        tris.append((bc, bot[j], bot[i]))
    return tris, (center[0], center[1] + height * 0.5, center[2])

# ------------------------------------------------------------- props ----
def pine(name, tiers, seed, height, sides=7):
    """tiers: list of (radius, tier_height) bottom -> top. Trunk shows under the lowest tier."""
    rnd = random.Random(seed); o = Obj()
    n = len(tiers)
    tier_gap = height / (n + 0.9)
    trunk_h = tier_gap * 1.15
    trunk(o, "Trunk", (0, 0, 0), 0.55 * height / 12, 0.30 * height / 12, trunk_h + 0.6, sides, rnd, lean=(rnd.uniform(-0.01, 0.01), rnd.uniform(-0.01, 0.01)))
    y = trunk_h
    for i, (r, th) in enumerate(tiers):
        # each tier is oriented against its own centre, so its sides face out and its flat bottom faces down
        cone_tier(o, "Foliage", (rnd.uniform(-0.06, 0.06), 0, rnd.uniform(-0.06, 0.06)), r, y, th, sides, rnd.uniform(0, 6.28), rnd)
        y += tier_gap
    return o.write(OUT / f"{name}.obj")

def round_tree(name, seed, height=11.0):
    rnd = random.Random(seed); o = Obj()
    sides = 7
    trunk(o, "Trunk", (0, 0, 0), 0.75, 0.5, height * 0.5, sides, rnd, lean=(0.02, -0.01))
    # two branch stubs up into the canopy
    for ang, h0 in ((0.8, height * 0.34), (3.6, height * 0.42)):
        d = (math.cos(ang), 0, math.sin(ang))
        rings = [ring((d[0] * 0.2, h0, d[2] * 0.2), 0.32, 0, 5, 0, 0.05, rnd),
                 ring((d[0] * 1.9, h0 + 2.4, d[2] * 1.9), 0.18, 0, 5, 0.3, 0.05, rnd)]
        tube(o, "Trunk", rings, (d[0] * 1.0, h0 + 1.2, d[2] * 1.0), cap_top=True)
    tris = []
    cy = height * 0.68
    blobs = [((0, cy, 0), height * 0.30, (1.15, 0.95, 1.15)),
             ((1.9, cy - 0.8, 1.1), height * 0.22, (1.1, 0.9, 1.05)),
             ((-1.8, cy - 0.5, -1.2), height * 0.21, (1.0, 0.9, 1.1)),
             ((0.6, cy + 1.6, -1.6), height * 0.19, (1.0, 1.0, 1.0)),
             ((-1.0, cy + 1.4, 1.7), height * 0.18, (1.0, 1.0, 1.0))]
    for c, r, sq in blobs:
        icoblob(o, "Canopy", c, r, rnd, 0.12, sq, tris_out=tris)
    o.add_flat("Canopy", tris)     # trust icosphere winding (CCW outward)
    return o.write(OUT / f"{name}.obj")

def stump(name, seed):
    rnd = random.Random(seed); o = Obj()
    sides = 9
    rings = []
    for k, (r, y) in enumerate(((1.75, 0.0), (1.35, 0.35), (1.25, 1.6), (1.3, 2.3))):
        rings.append(ring((0, 0, 0), r, y, sides, 0.15 * k, 0.09, rnd, tilt=(0.06, -0.03) if k == 3 else (0, 0)))
    tube(o, "Wood", rings, (0, 1.1, 0), cap_bottom=True)
    # root flares
    for i in range(4):
        a = i * 1.57 + 0.4
        d = (math.cos(a), 0, math.sin(a))
        r0 = ring((d[0] * 1.2, 0.0, d[2] * 1.2), 0.5, 0, 5, a, 0.1, rnd)
        r1 = ring((d[0] * 2.3, 0.0, d[2] * 2.3), 0.22, 0.15, 5, a, 0.1, rnd)
        tube(o, "Wood", [r0, r1], (d[0] * 1.7, 0.2, d[2] * 1.7), cap_top=True)
    # top: growth rings disc (separate colour), slightly tilted like the top ring
    top = rings[-1]
    c = mul(sum_pts(top), 1 / sides); c = (c[0], c[1] + 0.04, c[2])
    tris = []
    for i in range(sides):
        j = (i + 1) % sides
        tris.append((c, (top[j][0], top[j][1] + 0.04, top[j][2]), (top[i][0], top[i][1] + 0.04, top[i][2])))
    o.add_flat("Rings", tris, (0, 0, 0))
    return o.write(OUT / f"{name}.obj")

def log_fallen(name, seed, L=10.0):
    rnd = random.Random(seed); o = Obj()
    sides = 8
    rings = []
    for k in range(5):
        t = k / 4
        r = 1.25 - 0.35 * t
        rings.append([(p[0], p[1], p[2]) for p in ring_x((-L / 2 + L * t, r, 0), r, sides, 0.2 * k, 0.08, rnd)])
    tube(o, "Wood", rings, (0, 1.0, 0), cap_bottom=True, cap_top=True)
    # end rings discs
    for rg, dx in ((rings[0], -0.03), (rings[-1], 0.03)):
        c = mul(sum_pts(rg), 1 / sides); c = (c[0] + dx, c[1], c[2])
        tris = []
        for i in range(sides):
            j = (i + 1) % sides
            tris.append((c, (rg[j][0] + dx, rg[j][1], rg[j][2]), (rg[i][0] + dx, rg[i][1], rg[i][2])))
        o.add_flat("Rings", tris, (0, 1.0, 0))
    # branch stubs
    for x, ang, ln in ((-1.5, 1.1, 1.8), (2.2, -0.9, 1.4), (0.4, 2.4, 1.2)):
        d = (0, math.cos(ang), math.sin(ang))
        r0 = ring_dir((x, 1.0 + d[1] * 0.8, d[2] * 0.8), d, 0.35, 5, rnd)
        r1 = ring_dir((x + 0.3, 1.0 + d[1] * (0.8 + ln), d[2] * (0.8 + ln)), d, 0.16, 5, rnd)
        tube(o, "Wood", [r0, r1], (x, 1.0 + d[1] * 1.2, d[2] * 1.2), cap_top=True)
    return o.write(OUT / f"{name}.obj")

def ring_x(center, r, sides, yaw, jitter, rnd):
    """Ring in the YZ plane (for logs lying along X)."""
    pts = []
    for i in range(sides):
        a = yaw + 2 * math.pi * i / sides
        rr = r * (1 + rnd.uniform(-jitter, jitter))
        pts.append((center[0], center[1] + rr * math.cos(a), center[2] + rr * math.sin(a)))
    return pts

def ring_dir(center, d, r, sides, rnd):
    d = norm(d)
    u = norm(cross(d, (1, 0, 0))) if abs(d[0]) < 0.9 else norm(cross(d, (0, 1, 0)))
    w = cross(d, u)
    pts = []
    for i in range(sides):
        a = 2 * math.pi * i / sides
        rr = r * (1 + rnd.uniform(-0.08, 0.08))
        pts.append(add(center, add(mul(u, rr * math.cos(a)), mul(w, rr * math.sin(a)))))
    return pts

def log_hollow(name, seed, L=7.5, r_out=2.15, r_in=1.55):
    """Open-ended hollow log lying along X; a squirrel fits inside (inner radius > 1.2 studs of headroom)."""
    rnd = random.Random(seed); o = Obj()
    sides = 9
    outer = [ring_x((-L / 2 + L * k / 3, r_out, 0), r_out * (1 + 0.04 * math.sin(k * 2.1)), sides, 0.15 * k, 0.07, rnd) for k in range(4)]
    inner = [ring_x((-L / 2 + L * k / 3, r_out, 0), r_in, sides, 0.15 * k, 0.03, rnd) for k in range(4)]
    tris = []
    tube(o, "Wood", outer, (0, r_out, 0), tris_out=tris)
    # inner wall (faces inward)
    n = sides
    for k in range(3):
        a, b = inner[k], inner[k + 1]
        for i in range(n):
            j = (i + 1) % n
            tris.append((a[j], a[i], b[j])); tris.append((b[j], a[i], b[i]))
    # end faces between outer and inner rings (the wood ring), both ends
    for (ro, ri, flip) in ((outer[0], inner[0], True), (outer[-1], inner[-1], False)):
        for i in range(n):
            j = (i + 1) % n
            if flip:
                tris.append((ro[i], ri[j], ro[j])); tris.append((ro[i], ri[i], ri[j]))
            else:
                tris.append((ro[i], ro[j], ri[j])); tris.append((ro[i], ri[j], ri[i]))
    o.add_flat("Wood", tris)    # winding trusted
    # a flattened bottom: the log sinks a little so it doesn't wobble
    return o.write(OUT / f"{name}.obj")

def bush(name, seed, blobs):
    rnd = random.Random(seed); o = Obj()
    tris = []
    for c, r, sq in blobs:
        icoblob(o, "Leaf", c, r, rnd, 0.14, sq, tris_out=tris)
    o.add_flat("Leaf", tris)
    return o.write(OUT / f"{name}.obj")

def rocks(name, seed, stones):
    rnd = random.Random(seed); o = Obj()
    for i, (c, r, h, sides, sx, sz) in enumerate(stones):
        tris, cen = slab(c, r, h, sides, rnd, taper=rnd.uniform(0.8, 0.95), sx=sx, sz=sz, tilt=rnd.uniform(-0.15, 0.15), yaw=rnd.uniform(0, 3.1))
        o.add_flat(f"Rock{i + 1}", tris, cen)
    return o.write(OUT / f"{name}.obj")

def mushrooms(name, seed, shrooms):
    rnd = random.Random(seed); o = Obj()
    for i, (c, r_cap, h, lean) in enumerate(shrooms):
        sides = 8
        # stem
        rings = [ring(c, r_cap * 0.36, 0, sides, 0, 0.05, rnd), ring((c[0] + lean[0] * h, c[1], c[2] + lean[1] * h), r_cap * 0.3, h, sides, 0.2, 0.05, rnd)]
        tube(o, f"Stem{i + 1}", rings, (c[0], c[1] + h * 0.5, c[2]), cap_bottom=True, cap_top=True)
        top = (c[0] + lean[0] * h, c[1] + h, c[2] + lean[1] * h)
        # cap: dome from a wide rim ring up to an apex, plus a flat underside
        rim = ring(top, r_cap, -0.15 * r_cap, sides + 2, 0.4, 0.05, rnd)
        mid_ = ring(top, r_cap * 0.78, 0.45 * r_cap, sides + 2, 0.4, 0.04, rnd)
        apex = (top[0] + rnd.uniform(-0.05, 0.05), top[1] + 0.85 * r_cap, top[2] + rnd.uniform(-0.05, 0.05))
        tris = []
        n = sides + 2
        for k in range(n):
            j = (k + 1) % n
            tris.append((rim[k], rim[j], mid_[j])); tris.append((rim[k], mid_[j], mid_[k]))
            tris.append((mid_[k], mid_[j], apex))
        cc = (top[0], top[1] - 0.15 * r_cap - 0.01, top[2])
        for k in range(n):
            j = (k + 1) % n
            tris.append((cc, rim[j], rim[k]))
        o.add_flat(f"Cap{i + 1}", tris, (top[0], top[1] + 0.3 * r_cap, top[2]))
        # spots: little flat hexagons sitting on the cap
        sp = []
        for s in range(4):
            a = rnd.uniform(0, 6.28); dist = rnd.uniform(0.25, 0.7) * r_cap
            px, pz = top[0] + dist * math.cos(a), top[2] + dist * math.sin(a)
            # height on the dome approx (rim..apex interpolation)
            t = dist / r_cap
            py = top[1] + (0.85 * r_cap) * (1 - t * t) - 0.05 * r_cap + 0.03
            rs = r_cap * rnd.uniform(0.12, 0.2)
            hexes = [(px + rs * math.cos(a2), py, pz + rs * math.sin(a2)) for a2 in [2 * math.pi * q / 6 for q in range(6)]]
            for q in range(6):
                sp.append(((px, py, pz), hexes[(q + 1) % 6], hexes[q]))
        o.add_flat(f"Spots{i + 1}", sp, (top[0], top[1] - 1.0, top[2]))
    return o.write(OUT / f"{name}.obj")

if __name__ == "__main__":
    counts = {}
    counts["pine_tall"] = pine("pine_tall", [(3.6, 3.4), (3.1, 3.2), (2.5, 3.0), (1.8, 2.8), (1.1, 2.4)], 1, 15.0)
    counts["pine_mid"] = pine("pine_mid", [(3.2, 3.0), (2.5, 2.8), (1.7, 2.5), (1.0, 2.2)], 2, 11.0)
    counts["pine_squat"] = pine("pine_squat", [(3.6, 2.6), (2.7, 2.4), (1.6, 2.2)], 3, 7.5, sides=8)
    counts["round_tree"] = round_tree("round_tree", 4)
    counts["stump"] = stump("stump", 5)
    counts["log_fallen"] = log_fallen("log_fallen", 6)
    counts["log_hollow"] = log_hollow("log_hollow", 7)
    counts["bush_big"] = bush("bush_big", 8, [((0, 1.5, 0), 1.9, (1.2, 0.85, 1.2)), ((1.6, 1.1, 0.8), 1.4, (1.1, 0.8, 1.1)),
                                              ((-1.5, 1.0, 0.6), 1.3, (1.0, 0.85, 1.1)), ((0.3, 1.2, -1.6), 1.35, (1.1, 0.8, 1.0)),
                                              ((-0.4, 2.3, 0.3), 1.2, (1.0, 0.9, 1.0))])
    counts["bush_small"] = bush("bush_small", 9, [((0, 1.0, 0), 1.25, (1.2, 0.85, 1.2)), ((0.9, 0.8, 0.5), 0.9, (1.1, 0.8, 1.0)),
                                                  ((-0.8, 0.7, -0.4), 0.85, (1.0, 0.8, 1.1))])
    counts["rock_big"] = rocks("rock_big", 10, [((0, 0, 0), 2.6, 2.2, 7, 1.15, 0.9), ((0.4, 2.0, -0.2), 1.9, 1.5, 6, 1.0, 1.0),
                                                ((2.4, 0, 1.3), 1.2, 1.0, 6, 1.0, 1.0)])
    counts["rock_cluster"] = rocks("rock_cluster", 11, [((0, 0, 0), 1.3, 1.1, 6, 1.1, 0.9), ((1.9, 0, 0.6), 0.9, 0.7, 5, 1.0, 1.0),
                                                        ((-1.5, 0, 1.0), 1.0, 0.8, 6, 0.9, 1.1), ((0.6, 0, -1.7), 0.7, 0.5, 5, 1.0, 1.0)])
    counts["mushrooms"] = mushrooms("mushrooms", 12, [((0, 0, 0), 1.1, 1.6, (0.05, 0.02)), ((1.6, 0, 0.5), 0.8, 1.1, (-0.08, 0.05)),
                                                      ((-1.1, 0, 0.9), 0.65, 0.8, (0.03, -0.1))])
    for k, v in counts.items():
        print(f"{k:14s} {v:5d} tris")
