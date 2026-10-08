"""gen_cliff_mesh.py - the Sandstone Climb's rock as a sculpted mesh.

Shannon (Sep 27 2026) sent two sandstone photos (a layered orange cliff; a pale golden, wind-rounded outcrop) and chose
"light golden" and "sculpted model": thin layers with rounded lips and deep grooves between them, overhanging caps,
pockets, a crack or two, in pale golden cream with a few soft orange bands.

The rock is one shell per chunk: for every column along the face (x), rows at FIXED heights (so each stratum lines up
from column to column) run up the face; the rows above the column's skyline fold over a rounded shoulder, across the
top, over a back shoulder and down the back. The face's relief comes from a table of strata (each with its own
thickness, how far it stands out, a wave along x, and a groove under it), plus a little erosion noise, pockets and two
cracks, kept gentle beside the way up (the ledges and trellises are Parts made by build_cliff.lua).

Writes, in domaine/cliff/:
  SandCliff.obj/.mtl + sandcliff.png - for Studio's Import 3D: 4 chunks (SandCliff_A..D) + boulders, each centred on
                                        its bounding box and pre-turned 180 deg (Import 3D maps x,y,z -> -x,y,-z)
  cliff_preview.obj/.mtl             - everything in world coordinates, plus stand-ins for the ledges, the summit slab,
                                        the garden wall and the cypresses, for the Blender check render
  cliff_data.lua                     - the skyline and face line (1-stud samples), the chunk centres and the collision
                                        boxes, pasted into build_cliff.lua
  cliff_data.json                    - the same for the render script
"""
import json, math, os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "cliff")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(2609)

# ---------------------------------------------------------------- the layout (world studs) ----
FACE, BACK = -253.0, -271.0
XA, XB = 440.0, 592.0
Y0, YMAX = -3.0, 100.0          # the rows: fixed heights from underground up to YMAX (rows above a column's skyline fold)
DY = 0.32
DX = 1.5
YV0, YV1 = -4.0, 84.0           # the texture's height range (its rows are the strata)
# the way up, as build_cliff.lua makes it (ledge tops from the build log, Sep 27): (x, top, width)
LEDGES = [(498.0, 8.5, 5.5), (505.2, 12.3, 5.5), (512.4, 16.1, 5.5), (519.6, 19.9, 5.5), (526.8, 23.7, 5.5),
          (534.0, 27.5, 5.5), (545.0, 30.5, 10.0), (544.0, 43.0, 6.0), (537.0, 46.6, 5.0), (530.0, 50.2, 5.0),
          (523.0, 53.8, 5.0), (516.0, 57.4, 5.0), (509.0, 61.0, 5.0), (499.5, 64.0, 8.0)]
TA = (549.0, 30.5, 43.5)         # (moved from 548 on Sep 27; the imported mesh was made with 548 - within a stud, fine)
TB = (496.5, 64.0, 74.0)
SUMY = 73.5
SX, SZ = 497.0, -260.0
PLATE = (SX - 13.0, SX + 13.0)  # the summit slab (a Part, 26 x 2 x 15, top at SUMY)
R0, R1 = 492.0, 554.0           # the stretch of face the way up uses
CUT0, CUT1 = 468.0, 566.0       # where the map edge is open (collision is only needed between these)


def smoothstep(e0, e1, x):
    t = np.clip((np.asarray(x, dtype=float) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# ---------------------------------------------------------------- the skyline ----
# a butte: big uneven steps down at the ends, the high top (the bell and the pine), a shoulder over the east half
MAIN = 72.8
LEVELS = [(-1e9, 12.0), (446, 30.0), (452, 46.0), (460, 58.0), (468, MAIN), (526, 58.0), (556, 44.0), (563, 31.0),
          (571, 19.0), (580, 10.0)]
PH = rng.uniform(0, 2 * math.pi, 4)


def top_at(x):
    x = np.asarray(x, dtype=float)
    h = np.full(x.shape, LEVELS[0][1])
    for k in range(1, len(LEVELS)):
        x0, lv = LEVELS[k]
        h = h + (lv - LEVELS[k - 1][1]) * smoothstep(x0 - 1.6, x0 + 1.6, x)
    wob = 0.7 * np.sin(x / 4.1 + PH[0]) + 0.5 * np.sin(x / 2.3 + PH[1]) + 0.45 * np.sin(x / 9.0 + PH[2])
    h = h + wob
    # nothing may stick out over the top: 7 above every ledge in front, and above the top of trellis A
    for lx, lt, lw in LEDGES:
        h = np.where(np.abs(x - lx) < lw / 2 + 6, np.maximum(h, lt + 7), h)
    h = np.where(np.abs(x - TA[0]) < 7, np.maximum(h, TA[2] + 7), h)
    # under the summit slab: just below its underside (71.5), so it sits on the rock like paving
    plate = (x >= PLATE[0] - 1) & (x <= PLATE[1] + 1)
    h = np.where(plate, SUMY - 2.1, h)
    return h


# ---------------------------------------------------------------- the face line (in plan) ----
def route_weight(x):            # 1 beside the way up, 0 away from it (smooth)
    return smoothstep(R0 - 5, R0, x) * (1 - smoothstep(R1, R1 + 5, x))


def face_at(x):
    x = np.asarray(x, dtype=float)
    bulge = (0.9 * np.sin(x / 8.3) + 0.5 * np.sin(x / 3.7 + 1.3)) * (1 - 0.7 * route_weight(x))
    recede = 8 * smoothstep(0, 1, (486 - x) / 42) + 8 * smoothstep(0, 1, (x - 556) / 34)
    return FACE + bulge - recede


# ---------------------------------------------------------------- the strata ----
CREAM, GOLD, SAND, HONEY, ORANGE, WHITE = (238, 224, 188), (228, 204, 150), (220, 190, 132), (212, 172, 112), (214, 152, 96), (242, 232, 205)
layers = []
y = YV0
while y < YV1 + 4:
    r = rng.random()
    if r < 0.13:
        t, kind = rng.uniform(0.35, 0.6), "seam"
    elif r < 0.31:
        t, kind = rng.uniform(2.0, 3.4), "thick"
    else:
        t, kind = rng.uniform(0.8, 1.8), "bed"
    p0 = {"seam": rng.uniform(-1.3, -0.7), "thick": rng.uniform(0.5, 1.6), "bed": rng.uniform(-0.4, 1.1)}[kind]
    c = rng.random()
    if kind == "seam":
        col = ORANGE if c < 0.55 else HONEY
    else:
        col = CREAM if c < 0.27 else GOLD if c < 0.58 else SAND if c < 0.84 else HONEY if c < 0.95 else WHITE
    layers.append(dict(y0=y, y1=y + t, p0=p0, fr=rng.uniform(5, 14), ph=rng.uniform(0, 2 * math.pi), amp=rng.uniform(0.2, 0.7),
                       col=col, kind=kind, g=rng.uniform(0.35, 0.95) + (0.35 if kind == "thick" else 0.0)))
    y += t
L_Y0 = np.array([l["y0"] for l in layers])
L_T = np.array([l["y1"] - l["y0"] for l in layers])
L_P0 = np.array([l["p0"] for l in layers])
L_FR = np.array([l["fr"] for l in layers])
L_PH = np.array([l["ph"] for l in layers])
L_AMP = np.array([l["amp"] for l in layers])
L_G = np.array([l["g"] for l in layers])
NL = len(layers)

# value noise for erosion (tileable is not needed: one texture spans the whole rock)
NG = rng.uniform(-1, 1, (64, 64))


def vnoise(u, v):
    u = np.asarray(u) % 63.0
    v = np.asarray(v) % 63.0
    i, j = np.floor(u).astype(int), np.floor(v).astype(int)
    fu, fv = u - i, v - j
    fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
    a, b = NG[i % 64, j % 64], NG[(i + 1) % 64, j % 64]
    c, d = NG[i % 64, (j + 1) % 64], NG[(i + 1) % 64, (j + 1) % 64]
    return (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv


def fbm(x, y):
    return 0.6 * vnoise(x / 2.6, y / 1.3) + 0.3 * vnoise(x / 1.1 + 17, y / 0.6 + 5) + 0.25 * vnoise(x / 7 + 3, y / 3 + 11)


# pockets (wind holes) and cracks, away from the way up
POCKETS = []
while len(POCKETS) < 26:
    px, py = rng.uniform(XA + 4, XB - 4), rng.uniform(6, 66)
    if R0 - 6 < px < R1 + 6:
        continue
    if py > float(top_at([px])[0]) - 4:
        continue
    POCKETS.append((px, py, rng.uniform(1.2, 2.4), rng.uniform(0.5, 1.1)))
CRACKS = [(471.5, 0.25, 0.92), (562.5, 0.2, 0.9), (583.0, 0.1, 0.85)]   # x, from and to (as parts of the column's height)
JOINTS = []                     # (x, groove depth); the blocks between them stand out by BLOCK_OFF
jx = XA + rng.uniform(4, 12)
while jx < XB - 4:
    JOINTS.append((jx, rng.uniform(0.7, 1.5)))
    jx += rng.uniform(10, 22)
BLOCK_OFF = rng.uniform(-0.9, 0.9, len(JOINTS) + 1)


def blocks(x):
    x = np.asarray(x, dtype=float)
    off = np.full(x.shape, BLOCK_OFF[0])
    for k, (jxk, _) in enumerate(JOINTS):
        off = off + (BLOCK_OFF[k + 1] - BLOCK_OFF[k]) * smoothstep(jxk - 1.2, jxk + 1.2, x)
    groove = np.zeros(x.shape)
    for jxk, dep in JOINTS:
        groove = groove + dep * np.exp(-((x - jxk) / 0.9) ** 2)
    return off - groove


def relief(x, y, T):
    """How far the stone stands out from the face line at (x, y), for columns whose skyline is T."""
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    i = np.clip(np.searchsorted(L_Y0, y, side="right") - 1, 0, NL - 1)
    u = np.clip((y - L_Y0[i]) / L_T[i], 0, 1)
    p = L_P0[i] + L_AMP[i] * np.sin(x / L_FR[i] + L_PH[i])
    ib, ia = np.clip(i - 1, 0, NL - 1), np.clip(i + 1, 0, NL - 1)
    pb = L_P0[ib] + L_AMP[ib] * np.sin(x / L_FR[ib] + L_PH[ib])
    pa = L_P0[ia] + L_AMP[ia] * np.sin(x / L_FR[ia] + L_PH[ia])
    zlow = np.minimum(p, pb) - L_G[i]          # the groove under this bed
    zhigh = np.minimum(p, pa) - L_G[ia]        # the groove over it
    s = lambda v: np.sin(np.clip(v, 0, 1) * math.pi / 2) ** 0.55
    z = np.where(u < 0.5, p - (p - zlow) * (1 - s(2 * u)), p - (p - zhigh) * (1 - s(2 * (1 - u))))
    z = z + 0.16 * fbm(x, y) + blocks(x) * (1 - smoothstep(T - 2.0, T - 0.5, y) * 0.6)
    # caps: the stone just under the skyline stands out, with a deeper groove below it
    z = z + 0.8 * smoothstep(T - 2.6, T - 1.2, y) - 0.7 * np.exp(-((y - (T - 3.2)) / 0.55) ** 2)
    for px, py, pr, pd in POCKETS:
        z = z - pd * np.exp(-(((x - px) ** 2) + ((y - py) * 1.3) ** 2) / (pr * pr))
    for cx, f0, f1 in CRACKS:
        band = smoothstep(f0 * T, f0 * T + 3, y) * (1 - smoothstep(f1 * T - 2, f1 * T, y))
        z = z - 2.4 * np.exp(-((x - cx) / 1.0) ** 2) * band
    # gentle beside the way up (the ledges stand out 4.8 from the face line; no stray footholds), flatter still behind
    # the two trellises (their wooden rails stand 1.65 out from the face line)
    z = z * (1 - 0.45 * route_weight(x))
    for tx in (TA[0], TB[0]):
        z = z * (1 - 0.65 * np.exp(-((x - tx) / 2.6) ** 4))
    return z


# ---------------------------------------------------------------- the shell ----
RR, RB = 1.4, 1.5               # the front and back shoulders' radii
NCOL = int(round((XB - XA) / DX))
XS = np.linspace(XA, XB, NCOL + 1)
ROWS = np.arange(Y0, YMAX + 1e-6, DY)
TOPS = top_at(XS)
FACES = face_at(XS)
P = np.zeros((len(XS), len(ROWS), 3))
V = np.zeros((len(XS), len(ROWS)))           # texture height for each vertex (as a world y)
for ci, x in enumerate(XS):
    T = TOPS[ci]
    yf = T - RR
    zr = relief(np.full(ROWS.shape, x), ROWS, T)
    zf_top = float(relief([x], [yf], T)[0]) + FACES[ci]
    for ri, yy in enumerate(ROWS):
        if yy <= yf:
            P[ci, ri] = (x, yy, FACES[ci] + zr[ri])
            V[ci, ri] = yy
            continue
        tau = (yy - yf) / (YMAX - yf)
        ztop0, ztop1 = zf_top - RR, BACK + RB
        if tau < 0.22:                       # the front shoulder
            th = (tau / 0.22) * (math.pi / 2)
            P[ci, ri] = (x, yf + RR * math.sin(th), zf_top - RR + RR * math.cos(th))
            V[ci, ri] = T
        elif tau < 0.62:                     # across the top (a hint of a dip and rise)
            f = (tau - 0.22) / 0.40
            zz = ztop0 + (ztop1 - ztop0) * f
            P[ci, ri] = (x, T + 0.25 * math.sin(f * math.pi) * float(vnoise([x / 3.0], [f * 4])[0]), zz)
            V[ci, ri] = min(T + 1.0 + 2.5 * f, YV1 - 0.5)
        elif tau < 0.72:                     # the back shoulder
            th = math.pi / 2 + ((tau - 0.62) / 0.10) * (math.pi / 2)
            P[ci, ri] = (x, T - RB + RB * math.sin(th), BACK + RB + RB * math.cos(th))
            V[ci, ri] = T - RB * (1 - math.sin(th))
        else:                                # down the back, to underground
            f = (tau - 0.72) / 0.28
            yy2 = (T - RB) + (Y0 - (T - RB)) * f
            P[ci, ri] = (x, yy2, BACK)
            V[ci, ri] = yy2


def normals(Pg):
    dx = np.zeros_like(Pg); dy = np.zeros_like(Pg)
    dx[1:-1] = Pg[2:] - Pg[:-2]; dx[0] = Pg[1] - Pg[0]; dx[-1] = Pg[-1] - Pg[-2]
    dy[:, 1:-1] = Pg[:, 2:] - Pg[:, :-2]; dy[:, 0] = Pg[:, 1] - Pg[:, 0]; dy[:, -1] = Pg[:, -1] - Pg[:, -2]
    n = np.cross(dx, dy)
    l = np.linalg.norm(n, axis=2, keepdims=True); l[l == 0] = 1
    return n / l


N = normals(P)

# ---------------------------------------------------------------- objects ----
class Obj:
    def __init__(self, name, mat="Sand"):
        self.name, self.mat = name, mat
        self.v, self.vt, self.vn, self.f = [], [], [], []

    def add_vert(self, p, uv, n):
        self.v.append(p); self.vt.append(uv); self.vn.append(n)
        return len(self.v)                   # 1-based within this object

    def tri(self, a, b, c):
        self.f.append((a, b, c))


UVX = (XA, XB)                  # the x range the current texture covers (set per chunk)


def uv_of(x, vy):
    return ((x - UVX[0]) / (UVX[1] - UVX[0]), (vy - YV0) / (YV1 - YV0))


def grid_obj(name, c0, c1):
    global UVX
    UVX = (float(XS[c0]), float(XS[c1]))
    o = Obj(name, "Sand_" + name[-1])
    o.uvx = UVX
    idx = {}
    for ci in range(c0, c1 + 1):
        for ri in range(len(ROWS)):
            idx[ci, ri] = o.add_vert(tuple(P[ci, ri]), uv_of(XS[ci], V[ci, ri]), tuple(N[ci, ri]))
    for ci in range(c0, c1):
        for ri in range(len(ROWS) - 1):
            a, b, c, d = idx[ci, ri], idx[ci + 1, ri], idx[ci + 1, ri + 1], idx[ci, ri + 1]
            o.tri(a, b, c); o.tri(a, c, d)
    return o


def cap_obj(o, ci, facing):
    """close the rock's end (its profile), facing -x (the west end) or +x (the east end)"""
    pts = [tuple(P[ci, ri]) for ri in range(len(ROWS))]
    cy = sum(p[1] for p in pts) / len(pts); cz = sum(p[2] for p in pts) / len(pts)
    n = (facing, 0.0, 0.0)
    c = o.add_vert((pts[0][0], cy, cz), uv_of(XS[ci], cy), n)
    ids = [o.add_vert(p, uv_of(XS[ci], V[ci, ri]), n) for ri, p in enumerate(pts)]
    ring = ids + [ids[0]]
    for k in range(len(ring) - 1):
        a, b = ring[k], ring[k + 1]
        pa, pb = o.v[a - 1], o.v[b - 1]
        # winding: the face normal must point along 'facing'
        cr = (pa[1] - cy) * (pb[2] - cz) - (pa[2] - cz) * (pb[1] - cy)   # x of (pa-c) x (pb-c)
        if cr * facing >= 0:
            o.tri(c, a, b)
        else:
            o.tri(c, b, a)


BOUNDS = [0, None, None, None, NCOL]
q = NCOL // 4
BOUNDS = [0, q, 2 * q, 3 * q, NCOL]
chunks = []
for k in range(4):
    o = grid_obj("SandCliff_" + "ABCD"[k], BOUNDS[k], BOUNDS[k + 1])
    if k == 0:
        cap_obj(o, 0, -1.0)
    if k == 3:
        cap_obj(o, NCOL, 1.0)
    chunks.append(o)


def icoblob(name, centre, radius, squash, seed):
    """a rounded, lumpy boulder"""
    r = np.random.default_rng(seed)
    t = (1 + 5 ** 0.5) / 2
    verts = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    verts = [np.array(v) / np.linalg.norm(v) for v in verts]
    faces = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
             (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    for _ in range(2):
        cache, nf = {}, []
        def mid(a, b):
            key = (min(a, b), max(a, b))
            if key not in cache:
                m = verts[a] + verts[b]; verts.append(m / np.linalg.norm(m)); cache[key] = len(verts) - 1
            return cache[key]
        for a, b, c in faces:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        faces = nf
    global UVX
    home = next(c for c in chunks if c.uvx[0] <= centre[0] <= c.uvx[1])     # the chunk (and texture) it stands in front of
    UVX = home.uvx
    o = Obj(name, home.mat)
    ids = []
    for v in verts:
        lump = 1 + 0.12 * r.uniform(-1, 1)
        p = np.array(centre) + v * radius * lump * np.array(squash)
        ids.append(o.add_vert(tuple(p), uv_of(p[0], 30 + p[1] * 0.3), tuple(v)))
    for a, b, c in faces:
        o.tri(ids[a], ids[b], ids[c])
    return o


BOULDERS = [(476, 1.1), (483, 0.9), (555, 1.0), (561, 1.2)]
boulders = []
for k, (bx, s) in enumerate(BOULDERS):
    gy = 4.0 + (bx - 460) * 0.03
    fz = float(face_at([bx])[0])
    boulders.append(icoblob("SandBoulder_%d" % (k + 1), (bx, gy + 1.2 * s, fz + 2.1 * s + 0.4), 2.3 * s, (1.25, 0.8, 0.95), 50 + k))

# ---------------------------------------------------------------- the textures (one per chunk) ----
TOPCREAM = (222, 194, 142)      # (240, 228, 196 read as snow on the top in the sun - Sep 27)


def make_texture(xa, xb, path):
  TW, TH = 1024, 1024
  xs = xa + (np.arange(TW) + 0.5) / TW * (xb - xa)
  ys = YV1 - (np.arange(TH) + 0.5) / TH * (YV1 - YV0)          # image row 0 = the top
  X2, Y2 = np.meshgrid(xs, ys)
  li = np.clip(np.searchsorted(L_Y0, Y2, side="right") - 1, 0, NL - 1)
  cols = np.array([l["col"] for l in layers], dtype=float)
  img = cols[li]
  # the colour drifts a little along each bed, grain, and soft streaks down the face
  img = img * (1 + 0.05 * vnoise(X2 / 9 + li * 0.37, li * 0.21)[..., None])
  img = img * (1 + 0.045 * vnoise(X2 * 2.9, Y2 * 5.3)[..., None] + 0.03 * vnoise(X2 * 7.7 + 5, Y2 * 13.1)[..., None]
               + 0.025 * vnoise(X2 * 19 + 2, Y2 * 21 + 7)[..., None])
  img = img * (1 - 0.05 * np.clip(vnoise(X2 / 1.7, Y2 / 30 + 3), 0, 1)[..., None])
  # shade the grooves and pockets (the relief at each texel, against the beds around it)
  Tpix = top_at(xs)[None, :].repeat(TH, axis=0)
  Rpix = relief(X2, Y2, Tpix)
  rn = np.clip((Rpix + 1.4) / 3.0, 0, 1)
  shade = 0.82 + 0.18 * rn
  img = img * np.stack([shade ** 0.75, shade ** 1.0, shade ** 1.4], axis=-1) * 1.05
  # above each column's skyline: the weathered top (the top rows of the mesh map here)
  top = Y2 > Tpix - 0.2
  tc = np.array(TOPCREAM, dtype=float)[None, None, :] * (1 + 0.06 * vnoise(X2 * 1.3, Y2 * 2.1)[..., None] + 0.035 * vnoise(X2 * 11, Y2 * 13)[..., None]
                                                         - 0.05 * np.clip(vnoise(X2 / 2.5 + 9, Y2 * 0.7), 0, 1)[..., None])
  img = np.where(top[..., None], tc, img)
  img = np.clip(img, 0, 255).astype(np.uint8)
  Image.fromarray(img, "RGB").filter(ImageFilter.GaussianBlur(0.5)).save(path)


for c in chunks:
    make_texture(c.uvx[0], c.uvx[1], os.path.join(OUT, "sandcliff_%s.png" % c.name[-1]))

# ---------------------------------------------------------------- writing ----
def bbox_centre(o):
    a = np.array(o.v)
    return (a.min(0) + a.max(0)) / 2, a.max(0) - a.min(0)


def write_obj(path, objs, mtlname, roblox):
    """roblox: each object centred on its box and turned 180 deg about y (Import 3D turns it back)"""
    lines = ["# generated by gen_cliff_mesh.py", "mtllib " + mtlname]
    vo = 0
    centres = {}
    for o in objs:
        c, size = bbox_centre(o)
        centres[o.name] = ([round(float(v), 4) for v in c], [round(float(v), 4) for v in size])
        lines.append("o " + o.name)
        lines.append("g " + o.name)          # (Import 3D splits by groups; with objects only it merged all into one "default")
        lines.append("usemtl " + o.mat)
        for p in o.v:
            if roblox:
                lines.append("v %.4f %.4f %.4f" % (-(p[0] - c[0]), p[1] - c[1], -(p[2] - c[2])))
            else:
                lines.append("v %.4f %.4f %.4f" % p)
        for t in o.vt:
            lines.append("vt %.5f %.5f" % t)
        for n in o.vn:
            if roblox:
                lines.append("vn %.4f %.4f %.4f" % (-n[0], n[1], -n[2]))
            else:
                lines.append("vn %.4f %.4f %.4f" % n)
        for a, b, cc in o.f:
            lines.append("f %d/%d/%d %d/%d/%d %d/%d/%d" % (a + vo, a + vo, a + vo, b + vo, b + vo, b + vo, cc + vo, cc + vo, cc + vo))
        vo += len(o.v)
    with open(path, "w", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    return centres


def write_mtl(path, extra=()):
    lines = []
    for k in "ABCD":
        lines += ["newmtl Sand_" + k, "Kd 1 1 1", "map_Kd sandcliff_%s.png" % k]
    for name, rgb in extra:
        lines += ["newmtl " + name, "Kd %.3f %.3f %.3f" % tuple(c / 255 for c in rgb)]
    with open(path, "w", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")


rock = chunks + boulders
centres = write_obj(os.path.join(OUT, "SandCliff.obj"), rock, "SandCliff.mtl", roblox=True)
write_mtl(os.path.join(OUT, "SandCliff.mtl"))

# the preview: the rock in world coordinates, and stand-ins for what stands round it
def box_obj(name, mat, cx, cy, cz, sx, sy, sz):
    o = Obj(name, mat)
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    corners = [(cx + dx * hx, cy + dy * hy, cz + dz * hz) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
    ids = [o.add_vert(c, (0, 0), (0, 1, 0)) for c in corners]
    quads = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    for a, b, c, d in quads:
        o.tri(ids[a], ids[b], ids[c]); o.tri(ids[a], ids[c], ids[d])
    return o


LD = 4.8
props = []
for k, (lx, lt, lw) in enumerate(LEDGES):
    props.append(box_obj("Ledge%02d" % (k + 1), "Ledge", lx, lt - 0.65, FACE + LD - (LD + 3) / 2, lw, 1.3, LD + 3))
props.append(box_obj("Plate", "Ledge", SX, SUMY - 1, SZ, 26, 2, 15))
for tx, y0t, y1t in (TA, TB):
    props.append(box_obj("Trellis", "Wood", tx, (y0t + y1t) / 2, FACE + 1.7, 2.2, y1t - y0t, 0.4))
props.append(box_obj("GardenWall", "Wall", 520, 5.2, -247.0, 170, 2.6, 1.4))
for cx in range(442, 600, 16):
    props.append(box_obj("Cypress", "Cypress", cx, 4 + 13, -242, 5, 26, 5))
props.append(box_obj("StartStone", "Ledge", 498, 4.9, -243.3, 8, 1, 5))
write_obj(os.path.join(OUT, "cliff_preview.obj"), rock + props, "cliff_preview.mtl", roblox=False)
write_mtl(os.path.join(OUT, "cliff_preview.mtl"), [("Ledge", (234, 208, 160)), ("Wood", (122, 86, 56)), ("Wall", (170, 160, 140)), ("Cypress", (50, 90, 70))])

# ---------------------------------------------------------------- data for build_cliff.lua ----
xi = np.arange(int(XA), int(XB) + 1)
TOP1 = top_at(xi)
FACE1 = face_at(xi)
LIP1 = []
for xv, tv in zip(xi, TOP1):
    yy = np.arange(2.0, tv - 1.0, 0.25)
    LIP1.append(float(relief(np.full(yy.shape, float(xv)), yy, tv).max()) if len(yy) else 0.0)
boxes = []
for x0 in np.arange(CUT0 - 2, CUT1 + 2, 2.0):
    xx = np.linspace(x0, x0 + 2, 5)
    tmin = float(top_at(xx).min()) - 0.3
    fmid = float(face_at([x0 + 1])[0]) + 0.2
    if x0 + 1 >= PLATE[0] - 1 and x0 + 1 <= PLATE[1] + 1:
        tmin = SUMY - 2.1
    boxes.append((x0 + 1, tmin, fmid))
data = {
    "x0": int(XA), "top": [round(float(v), 2) for v in TOP1], "face": [round(float(v), 2) for v in FACE1],
    "centres": centres, "boxes": boxes, "back": BACK,
    "tris": {o.name: len(o.f) for o in rock},
}
with open(os.path.join(OUT, "cliff_data.json"), "w") as fh:
    json.dump(data, fh)
L = ["-- cliff_data.lua: made by gen_cliff_mesh.py - the sculpted rock's skyline and face line (x " + str(int(XA)) + ".." + str(int(XB)) + ", 1 stud apart),",
     "-- where each imported chunk's centre goes, and the invisible collision boxes {x, top, front} (2 wide, back to z " + str(BACK) + ")",
     "local CLIFF = {",
     "\tx0 = %d," % int(XA),
     "\ttop = {" + ", ".join("%.2f" % v for v in TOP1) + "},",
     "\tface = {" + ", ".join("%.2f" % v for v in FACE1) + "},",
     "\tlip = {" + ", ".join("%.2f" % v for v in LIP1) + "},",
     "\tcentres = {" + ", ".join('%s = Vector3.new(%.4f, %.4f, %.4f)' % (k, v[0][0], v[0][1], v[0][2]) for k, v in centres.items()) + "},",
     "\tboxes = {" + ", ".join("{%.1f, %.2f, %.2f}" % b for b in boxes) + "},",
     "}"]
with open(os.path.join(OUT, "cliff_data.lua"), "w", newline="\n") as fh:
    fh.write("\n".join(L) + "\n")
print("layers", NL, "| columns", NCOL, "rows", len(ROWS), "| tris", data["tris"], "| boxes", len(boxes))
