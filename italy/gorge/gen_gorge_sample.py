"""gen_gorge_sample.py - a PREVIEW section of the south gorge for 1001 Squirrels (Sep 30 2026), made for Shannon's OK
before anything is built in Studio.

Shannon's picks on the reference board: the Pont du Gard (both photos) for the aqueduct; the Ardeche gorge (canoes and
the natural arch) for the cliffs, in the Sandstone Climb's cream layered rock; maybes: the Gravina aqueduct, the
Ardeche at water level, Zion Narrows. Not: Spoleto, Verdon. No haze.

Local coordinates: the river runs along z (downstream = -z, as in the game), its centre line near x = 0, the water
surface at y = -0.9 (the game's WATER_Y). The gorge opens into a basin round z = 0, where the aqueduct crosses in three
tiers like the Pont du Gard: one big arch over the river with two side arches over little beaches, the same again on
the middle tier, and a small arcade with the covered water channel on top, running into the rock at both ends. Past
the basin the gorge narrows and bends away, so nobody can see its ends.

Cliffs: the same strata recipe and colours as domaine/gen_cliff_mesh.py (the Sandstone Climb), so the rock matches;
the beds line up on both sides of the river, with an undercut notch at the waterline (Ardeche) and grass on top.

Writes, in this folder: gorge_sample.obj/.mtl, cliff_L.png / cliff_R.png (strata), masonry.png (the aqueduct's
blocks), trees.json (kit trees for the render: file, position, scale, yaw).
"""
import json, math, os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
rng = np.random.default_rng(3009)
WATER_Y = -0.9
Z0, Z1 = -170.0, 170.0
DZ = 1.5
Y0, YMAX, DY = -6.0, 110.0, 0.4
YV0, YV1 = -6.0, 50.0            # the strata texture's height range
RR = 1.4                          # the rim's rounded lip


def smoothstep(e0, e1, x):
    t = np.clip((np.asarray(x, dtype=float) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# ---------------------------------------------------------------- the gorge in plan ----
def centre_x(z):                  # the river's centre line: straight through the basin, bending away at both ends
    z = np.asarray(z, dtype=float)
    return -24.0 * smoothstep(34.0, 96.0, np.abs(z)) ** 1.3


def basin(z):
    return np.exp(-(np.abs(np.asarray(z, dtype=float)) / 24.0) ** 4)


def base_off(z, s):               # centre line -> the foot of the cliff (before relief)
    narrow = 12.8 if s < 0 else 14.6                # the left drops straight into the water; the right keeps a thin beach
    b = basin(z)
    return narrow + (30.0 - narrow) * b + 0.9 * np.sin(np.asarray(z) / 17.0 + 1.7 * s) * (1 - b)


def top_at(z, s):
    z = np.asarray(z, dtype=float)
    t = 41.0 + 3.2 * np.sin(z / 29.0 + 1.3 * s) + 1.3 * np.sin(z / 11.0 + 0.7 * s)
    w = np.exp(-(z / 14.0) ** 2)                    # level at the aqueduct, so its top runs out onto the ground
    return t * (1 - w) + 40.6 * w


def lean(y):
    return 0.22 * np.clip(np.asarray(y, dtype=float), 0, None)


def undercut(y):                  # the notch the river has worn at the waterline
    return 1.3 * np.exp(-((np.asarray(y, dtype=float) - 2.2) / 2.0) ** 2)


# ---------------------------------------------------------------- strata (as gen_cliff_mesh.py) ----
CREAM, GOLD, SAND, HONEY, ORANGE, WHITE = (238, 224, 188), (228, 204, 150), (220, 190, 132), (212, 172, 112), (214, 152, 96), (242, 232, 205)
TOPCREAM = (222, 194, 142)
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
        col = CREAM if c < 0.17 else GOLD if c < 0.53 else SAND if c < 0.82 else HONEY if c < 0.96 else WHITE
    layers.append(dict(y0=y, y1=y + t, p0=p0, fr=rng.uniform(5, 14), ph=rng.uniform(0, 2 * math.pi), amp=rng.uniform(0.2, 0.7),
                       col=col, kind=kind, g=rng.uniform(0.35, 0.95) + (0.35 if kind == "thick" else 0.0)))
    y += t
L_Y0 = np.array([l["y0"] for l in layers]); L_T = np.array([l["y1"] - l["y0"] for l in layers])
L_P0 = np.array([l["p0"] for l in layers]); L_FR = np.array([l["fr"] for l in layers])
L_PH = np.array([l["ph"] for l in layers]); L_AMP = np.array([l["amp"] for l in layers])
L_G = np.array([l["g"] for l in layers]); NL = len(layers)
NG = rng.uniform(-1, 1, (64, 64))


def vnoise(u, v):
    u = np.asarray(u, dtype=float) % 63.0; v = np.asarray(v, dtype=float) % 63.0
    i, j = np.floor(u).astype(int), np.floor(v).astype(int)
    fu, fv = u - i, v - j
    fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
    a, b = NG[i % 64, j % 64], NG[(i + 1) % 64, j % 64]
    c, d = NG[i % 64, (j + 1) % 64], NG[(i + 1) % 64, (j + 1) % 64]
    return (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv


def fbm(x, y):
    return 0.6 * vnoise(x / 2.6, y / 1.3) + 0.3 * vnoise(x / 1.1 + 17, y / 0.6 + 5) + 0.25 * vnoise(x / 7 + 3, y / 3 + 11)


def side_features(s):
    r = np.random.default_rng(71 if s < 0 else 72)
    pockets = []
    while len(pockets) < 34:
        pz, py = r.uniform(Z0 + 6, Z1 - 6), r.uniform(5, 36)
        if abs(pz) < 12:
            continue
        pockets.append((pz, py, r.uniform(1.2, 2.6), r.uniform(0.5, 1.2)))
    joints = []
    jz = Z0 + r.uniform(3, 10)
    while jz < Z1 - 3:
        joints.append((jz, r.uniform(0.9, 1.9)))
        jz += r.uniform(9, 20)
    off = r.uniform(-1.5, 1.5, len(joints) + 1)
    cracks = [(float(r.uniform(-80, -30)), 0.2, 0.9), (float(r.uniform(30, 80)), 0.15, 0.85)]
    return dict(pockets=pockets, joints=joints, off=off, cracks=cracks)


FEAT = {-1: side_features(-1), 1: side_features(1)}
SHELVES = [(-1, 30, 17), (-1, -38, 24), (-1, 58, 12), (1, 34, 21), (1, -30, 15), (1, -62, 26), (-1, -70, 9), (1, 70, 14)]
SHELF_OUT = 2.4


def blocks(z, s):
    f = FEAT[s]; z = np.asarray(z, dtype=float)
    off = np.full(z.shape, f["off"][0])
    for k, (jzk, _) in enumerate(f["joints"]):
        off = off + (f["off"][k + 1] - f["off"][k]) * smoothstep(jzk - 1.2, jzk + 1.2, z)
    groove = np.zeros(z.shape)
    for jzk, dep in f["joints"]:
        groove = groove + dep * np.exp(-((z - jzk) / 0.9) ** 2)
    return off - groove


def relief(z, y, T, s):
    """How far the stone stands out (toward the river) from the face line at (z, y), for a column whose rim is T."""
    z = np.asarray(z, dtype=float); y = np.asarray(y, dtype=float)
    zz = z + 37.0 * s                                   # the two sides' waves differ; the beds (heights) are shared
    i = np.clip(np.searchsorted(L_Y0, y, side="right") - 1, 0, NL - 1)
    u = np.clip((y - L_Y0[i]) / L_T[i], 0, 1)
    p = L_P0[i] + L_AMP[i] * np.sin(zz / L_FR[i] + L_PH[i])
    ib, ia = np.clip(i - 1, 0, NL - 1), np.clip(i + 1, 0, NL - 1)
    pb = L_P0[ib] + L_AMP[ib] * np.sin(zz / L_FR[ib] + L_PH[ib])
    pa = L_P0[ia] + L_AMP[ia] * np.sin(zz / L_FR[ia] + L_PH[ia])
    zlow = np.minimum(p, pb) - L_G[i]
    zhigh = np.minimum(p, pa) - L_G[ia]
    sq = lambda v: np.sin(np.clip(v, 0, 1) * math.pi / 2) ** 0.55
    rl = 0.8 * (p - (p - zlow) * (1 - smoothstep(0.0, 0.28, u)) - 0.35 * smoothstep(0.82, 1.0, u))
    rl = rl + 0.16 * fbm(zz, y) + blocks(z, s) * (1 - smoothstep(T - 2.0, T - 0.5, y) * 0.6)
    rl = rl + 0.45 * smoothstep(T - 2.6, T - 1.2, y) - 0.6 * np.exp(-((y - (T - 3.2)) / 0.55) ** 2)
    for pz, py, pr, pd in FEAT[s]["pockets"]:
        rl = rl - pd * np.exp(-(((z - pz) ** 2) + ((y - py) * 1.3) ** 2) / (pr * pr))
    for cz, f0, f1 in FEAT[s]["cracks"]:
        band = smoothstep(f0 * T, f0 * T + 3, y) * (1 - smoothstep(f1 * T - 2, f1 * T, y))
        rl = rl - 2.4 * np.exp(-((z - cz) / 1.0) ** 2) * band
    for ss, sz, sy in SHELVES:                          # ledges where a bush has taken hold (a bed standing well out)
        if ss == s:
            rl = rl + SHELF_OUT * np.exp(-((z - sz) / 3.2) ** 4) * smoothstep(sy - 2.6, sy - 0.4, y) * (1 - smoothstep(sy, sy + 0.4, y))
    return rl * (1 - 0.5 * np.exp(-(z / 9.0) ** 2))     # calmer where the aqueduct is built into the rock


def face_d(z, y, s):
    """distance from the centre line to the rock face at (z, y)"""
    T = float(top_at(z, s))
    return base_off(z, s) + lean(y) + undercut(y) - relief(np.full(np.shape(y), z), y, T, s)


# ---------------------------------------------------------------- mesh objects ----
class Mesh:
    def __init__(self, name, mat, smooth=False):
        self.name, self.mat, self.smooth = name, mat, smooth
        self.v, self.vt, self.vn, self.f = [], [], [], []

    def vert(self, p, uv=(0.0, 0.0), n=(0.0, 1.0, 0.0)):
        self.v.append(tuple(float(c) for c in p)); self.vt.append(tuple(float(c) for c in uv)); self.vn.append(tuple(float(c) for c in n))
        return len(self.v)

    def tri_flat(self, a, b, c, uvf=None):
        a, b, c = (np.asarray(q, dtype=float) for q in (a, b, c))
        n = np.cross(b - a, c - a); ln = np.linalg.norm(n)
        if ln < 1e-9:
            return
        n = n / ln
        ids = [self.vert(q, uvf(q, n) if uvf else (0, 0), n) for q in (a, b, c)]
        self.f.append(tuple(ids))

    def quad_flat(self, a, b, c, d, uvf=None):
        self.tri_flat(a, b, c, uvf); self.tri_flat(a, c, d, uvf)


MESHES = []


def mesh(name, mat, smooth=False):
    m = Mesh(name, mat, smooth); MESHES.append(m); return m


# ---------------------------------------------------------------- the cliffs ----
ZS = np.arange(Z0, Z1 + 1e-6, DZ)
ROWS = np.arange(Y0, YMAX + 1e-6, DY)
RIM = {}                                   # s -> list of (z, rim distance, T) per column
for s in (-1, 1):
    P = np.zeros((len(ZS), len(ROWS), 3)); V = np.zeros((len(ZS), len(ROWS)))
    rim = []
    for ci, z in enumerate(ZS):
        T = float(top_at(z, s)); yf = T - RR
        xc = float(centre_x(z))
        dface = base_off(z, s) + lean(ROWS) + undercut(ROWS) - relief(np.full(ROWS.shape, z), ROWS, T, s)
        df = float(base_off(z, s) + lean(yf) + undercut(yf) - relief([z], [yf], T, s)[0])
        rim.append((float(z), df + RR, T))
        for ri, yy in enumerate(ROWS):
            if yy <= yf:
                P[ci, ri] = (xc + s * dface[ri], yy, z); V[ci, ri] = yy
                continue
            tau = (yy - yf) / (YMAX - yf)
            if tau < 0.25:                                   # the rounded lip
                th = (tau / 0.25) * (math.pi / 2)
                d = df + RR - RR * math.cos(th); P[ci, ri] = (xc + s * d, yf + RR * math.sin(th), z); V[ci, ri] = T
            else:                                            # the top, out over the ridge
                f = (tau - 0.25) / 0.75
                d = df + RR + f * 300.0; P[ci, ri] = (xc + s * d, T, z); V[ci, ri] = min(T + 1.0 + 2.5 * f, YV1 - 0.5)
    RIM[s] = rim
    dx = np.zeros_like(P); dy = np.zeros_like(P)
    dx[1:-1] = P[2:] - P[:-2]; dx[0] = P[1] - P[0]; dx[-1] = P[-1] - P[-2]
    dy[:, 1:-1] = P[:, 2:] - P[:, :-2]; dy[:, 0] = P[:, 1] - P[:, 0]; dy[:, -1] = P[:, -1] - P[:, -2]
    N = np.cross(dx, dy); ln = np.linalg.norm(N, axis=2, keepdims=True); ln[ln == 0] = 1; N = N / ln
    if s < 0:
        N = -N
    m = mesh("Cliff" + ("L" if s < 0 else "R"), "Cliff" + ("L" if s < 0 else "R"), smooth=True)
    idx = np.zeros((len(ZS), len(ROWS)), dtype=int)
    for ci in range(len(ZS)):
        for ri in range(len(ROWS)):
            idx[ci, ri] = m.vert(P[ci, ri], ((ZS[ci] - Z0) / (Z1 - Z0), (V[ci, ri] - YV0) / (YV1 - YV0)), N[ci, ri])
    for ci in range(len(ZS) - 1):
        for ri in range(len(ROWS) - 1):
            a, b, c, d = idx[ci, ri], idx[ci + 1, ri], idx[ci + 1, ri + 1], idx[ci, ri + 1]
            if s > 0:
                m.f.append((a, b, c)); m.f.append((a, c, d))
            else:
                m.f.append((a, c, b)); m.f.append((a, d, c))


def make_strata_texture(s, path):
    TW, TH = 4096, 1024
    zs = Z0 + (np.arange(TW) + 0.5) / TW * (Z1 - Z0)
    ys = YV1 - (np.arange(TH) + 0.5) / TH * (YV1 - YV0)
    Z2, Y2 = np.meshgrid(zs, ys)
    zz = Z2 + 37.0 * s
    li = np.clip(np.searchsorted(L_Y0, Y2, side="right") - 1, 0, NL - 1)
    cols = np.array([l["col"] for l in layers], dtype=float)
    img = cols[li]
    img = img * (1 + 0.05 * vnoise(zz / 9 + li * 0.37, li * 0.21)[..., None])
    img = img * (1 + 0.045 * vnoise(zz * 2.9, Y2 * 5.3)[..., None] + 0.03 * vnoise(zz * 7.7 + 5, Y2 * 13.1)[..., None]
                 + 0.025 * vnoise(zz * 19 + 2, Y2 * 21 + 7)[..., None])
    img = img * (1 - 0.05 * np.clip(vnoise(zz / 1.7, Y2 / 30 + 3), 0, 1)[..., None])
    Tpix = np.array([float(top_at(z, s)) for z in zs])[None, :].repeat(TH, axis=0)
    Rpix = np.zeros_like(Z2)
    for k in range(TW):
        Rpix[:, k] = relief(np.full(TH, zs[k]), ys, Tpix[0, k], s)
    rn = np.clip((Rpix + 1.4) / 3.0, 0, 1)
    shade = 0.82 + 0.18 * rn
    img = img * np.stack([shade ** 0.75, shade ** 1.0, shade ** 1.4], axis=-1) * 1.05
    # a faint darker wet band just above the waterline, where the river splashes
    wet = np.exp(-((Y2 - (WATER_Y + 0.6)) / 0.7) ** 2)[..., None]
    img = img * (1 - 0.22 * wet)
    top = Y2 > Tpix - 0.2
    tc = np.array(TOPCREAM, dtype=float)[None, None, :] * (1 + 0.06 * vnoise(zz * 1.3, Y2 * 2.1)[..., None] + 0.035 * vnoise(zz * 11, Y2 * 13)[..., None]
                                                            - 0.05 * np.clip(vnoise(zz / 2.5 + 9, Y2 * 0.7), 0, 1)[..., None])
    img = np.where(top[..., None], tc, img)
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.5)).save(path)


# grass on the ridge tops (a strip following each rim, set back from the lip)
for s in (-1, 1):
    g = mesh("Grass" + ("L" if s < 0 else "R"), "Grass")
    rim = RIM[s]
    DS = [2.2, 5.0, 12.0, 24.0, 60.0, 300.0]
    for k in range(len(rim) - 1):
        (z0, d0, t0), (z1, d1, t1) = rim[k], rim[k + 1]
        for j in range(len(DS) - 1):
            e0 = DS[j] + (0.8 * math.sin(z0 / 5.0) if j == 0 else 0); e1 = DS[j] + (0.8 * math.sin(z1 / 5.0) if j == 0 else 0)
            q = [(float(centre_x(z0)) + s * (d0 + e0), t0 + 0.15, z0), (float(centre_x(z1)) + s * (d1 + e1), t1 + 0.15, z1),
                 (float(centre_x(z1)) + s * (d1 + DS[j + 1]), t1 + 0.15, z1), (float(centre_x(z0)) + s * (d0 + DS[j + 1]), t0 + 0.15, z0)]
            if s > 0:
                g.quad_flat(q[0], q[1], q[2], q[3])
            else:
                g.quad_flat(q[0], q[3], q[2], q[1])

# ---------------------------------------------------------------- water, beaches ----
w = mesh("Water", "Water")
w.quad_flat((-70, WATER_Y, 175), (70, WATER_Y, 175), (70, WATER_Y, -175), (-70, WATER_Y, -175))

sand, mud = mesh("Sand", "Sand"), mesh("Mud", "Mud")
for s in (-1, 1):
    for k in range(len(ZS) - 1):
        z0, z1 = ZS[k], ZS[k + 1]
        b0, b1 = float(base_off(z0, s)), float(base_off(z1, s))
        if max(b0, b1) < 13.6:
            continue
        def prof(z, b):
            ramp = float(smoothstep(13.6, 16.5, b))
            ds = [10.6, 12.2, 13.4, 15.5, 19.0, 24.0, b + 2.5]
            ds = sorted(set([dd for dd in ds if dd <= b + 2.5]))
            out = []
            for dd in ds:
                h = WATER_Y - 1.2 if dd <= 10.7 else (WATER_Y + 0.25 if dd <= 12.3 else 0.12 + 0.06 * math.sin(z / 3.1 + dd))
                if dd > 13.4:
                    h = 0.2 + 0.1 * math.sin(z / 4.3 + dd * 0.7) + 0.02 * (dd - 13.4)
                out.append((dd, (WATER_Y - 0.5) + (h - (WATER_Y - 0.5)) * ramp))
            return out
        p0, p1 = prof(z0, b0), prof(z1, b1)
        n = min(len(p0), len(p1))
        for j in range(n - 1):
            (da, ha), (db, hb) = p0[j], p0[j + 1]
            (dc, hc), (dd_, hd) = p1[j], p1[j + 1]
            xa0, xa1 = float(centre_x(z0)), float(centre_x(z1))
            q = [(xa0 + s * da, ha, z0), (xa1 + s * dc, hc, z1), (xa1 + s * dd_, hd, z1), (xa0 + s * db, hb, z0)]
            tgt = mud if db <= 13.4 else sand
            if s > 0:
                tgt.quad_flat(q[0], q[1], q[2], q[3])
            else:
                tgt.quad_flat(q[0], q[3], q[2], q[1])

# ---------------------------------------------------------------- boulders ----
def icoblob(m, centre, radius, squash, seed):
    r = np.random.default_rng(seed)
    t = (1 + 5 ** 0.5) / 2
    verts = [np.array(v, dtype=float) / np.linalg.norm(v) for v in [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t),
                                                                     (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]]
    faces = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
             (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    cache = {}
    nf = []
    def mid(a, b):
        key = (min(a, b), max(a, b))
        if key not in cache:
            mm = verts[a] + verts[b]; verts.append(mm / np.linalg.norm(mm)); cache[key] = len(verts) - 1
        return cache[key]
    for a, b, c in faces:
        ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
        nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
    ids = []
    for v in verts:
        p = np.array(centre) + v * radius * (1 + 0.14 * r.uniform(-1, 1)) * np.array(squash)
        ids.append(m.vert(p, (0, 0), v))
    for a, b, c in nf:
        m.f.append((ids[a], ids[b], ids[c]))


boulders = mesh("Boulders", "Boulder", smooth=True)
brng = np.random.default_rng(12)
BOULDER_AT = [(-1, 13.0, 19), (-1, 14.5, -22), (1, 12.8, 16), (1, 15.5, -27), (1, 13.2, 31), (-1, 12.2, 44), (1, 13.6, -58),
              (-1, 11.6, -66), (1, 16.5, 9.5), (-1, 17.5, -11)]
for k, (s, d, z) in enumerate(BOULDER_AT):
    rad = float(brng.uniform(1.4, 2.3))
    yc = WATER_Y + 0.3 if d < 14 else 0.35
    icoblob(boulders, (float(centre_x(z)) + s * d, yc, z), rad, (1.25, 0.72, 1.0), 40 + k)

# ---------------------------------------------------------------- the aqueduct ----
TILE_U, TILE_V = 12.0, 6.0


def uv_masonry(p, n):
    ax = int(np.argmax(np.abs(n)))
    if ax == 1:
        return (p[0] / TILE_U, p[2] / TILE_V)
    if ax == 0:
        return (p[2] / TILE_U, p[1] / TILE_V)
    return (p[0] / TILE_U, p[1] / TILE_V)


stone = mesh("AqStone", "Masonry")
archm = mesh("AqArch", "AqArch")
ledge = mesh("AqLedge", "AqLedge")
cap = mesh("AqCap", "AqCap")
knob = mesh("AqKnob", "AqKnob")


def box(m, x0, x1, y0, y1, z0, z1, uvf=None, skip=()):
    A = (x0, y0, z0); B = (x1, y0, z0); C = (x1, y1, z0); D = (x0, y1, z0)
    E = (x0, y0, z1); F = (x1, y0, z1); G = (x1, y1, z1); H = (x0, y1, z1)
    faces = {"-z": (A, D, C, B), "+z": (E, F, G, H), "-x": (A, E, H, D), "+x": (B, C, G, F), "-y": (A, B, F, E), "+y": (D, H, G, C)}
    for k, q in faces.items():
        if k not in skip:
            m.quad_flat(*q, uvf=uvf)


def arch_pts(xc, r, ys, n):
    return [(xc + r * math.cos(math.pi - math.pi * k / n), ys + r * math.sin(math.pi - math.pi * k / n)) for k in range(n + 1)]


def spandrel(xc, r, ys, top, z0, z1, n=16):
    """the wall over an arch opening: front and back faces between the arch and the top, and the arch's underside"""
    pts = arch_pts(xc, r, ys, n)
    for k in range(n):
        (xa, ya), (xb, yb) = pts[k], pts[k + 1]
        stone.quad_flat((xa, ya, z1), (xb, yb, z1), (xb, top, z1), (xa, top, z1), uv_masonry)      # front (+z)
        stone.quad_flat((xa, ya, z0), (xa, top, z0), (xb, top, z0), (xb, yb, z0), uv_masonry)      # back (-z)
        stone.quad_flat((xa, ya, z0), (xb, yb, z0), (xb, yb, z1), (xa, ya, z1), uv_masonry)        # underside, facing the opening


def voussoirs(xc, r, ys, t, zface, out, n):
    """the ring of arch stones standing proud of the wall face (out = +1 on the +z face, -1 on the -z face)"""
    for k in range(n):
        a0, a1 = math.pi - math.pi * k / n + 0.004, math.pi - math.pi * (k + 1) / n - 0.004
        key = (k == n // 2)
        tt = t + (0.45 if key else 0.0)
        pr = 0.30 if key else (0.22 if k % 2 == 0 else 0.15)
        z0, z1 = (zface - 0.02, zface + pr) if out > 0 else (zface - pr, zface + 0.02)
        pi0 = (xc + r * math.cos(a0), ys + r * math.sin(a0)); pi1 = (xc + r * math.cos(a1), ys + r * math.sin(a1))
        po0 = (xc + (r + tt) * math.cos(a0), ys + (r + tt) * math.sin(a0)); po1 = (xc + (r + tt) * math.cos(a1), ys + (r + tt) * math.sin(a1))
        zo, zi = (z1, z0) if out > 0 else (z0, z1)
        F = [(pi0[0], pi0[1], zo), (pi1[0], pi1[1], zo), (po1[0], po1[1], zo), (po0[0], po0[1], zo)]
        Bk = [(pi0[0], pi0[1], zi), (pi1[0], pi1[1], zi), (po1[0], po1[1], zi), (po0[0], po0[1], zi)]
        if out > 0:
            archm.quad_flat(F[0], F[1], F[2], F[3])
        else:
            archm.quad_flat(F[0], F[3], F[2], F[1])
        # the edges of the stone (inner, outer, both sides); winding checked against the stone's own centre
        cen = np.mean(np.array(F + Bk), axis=0)
        for a, b in ((0, 1), (1, 2), (2, 3), (3, 0)):
            q = [F[a], F[b], Bk[b], Bk[a]]
            nrm = np.cross(np.subtract(q[1], q[0]), np.subtract(q[2], q[0]))
            if np.dot(nrm, np.mean(q, axis=0) - cen) < 0:
                q = q[::-1]
            archm.quad_flat(*q)


def knobs(xs, y, zface, out):
    for x in xs:
        z0, z1 = (zface - 0.05, zface + 0.55) if out > 0 else (zface - 0.55, zface + 0.05)
        box(knob, x - 0.35, x + 0.35, y - 0.3, y + 0.3, z0, z1)


def cutwater(xl, xr, zface, ext, y0, yc):
    xc = (xl + xr) / 2
    L0, R0, N0 = (xl, y0, zface), (xr, y0, zface), (xc, y0, zface + ext)
    L1, R1, N1 = (xl, yc, zface), (xr, yc, zface), (xc, yc, zface + ext)
    Pk = (xc, yc + ext * 0.85, zface)
    stone.quad_flat(L0, N0, N1, L1, uv_masonry)
    stone.quad_flat(N0, R0, R1, N1, uv_masonry)
    stone.tri_flat(L1, N1, Pk, uv_masonry)
    stone.tri_flat(N1, R1, Pk, uv_masonry)


# tier 1: the big arch over the river, a side arch over each beach, abutments running into the rock
T1B, T1T, D1 = -7.0, 19.2, 5.0
for x0, x1 in ((-38, -26), (-14, -10), (10, 14), (26, 38)):
    box(stone, x0, x1, T1B, T1T, -D1, D1, uv_masonry)
spandrel(0, 10, 6.0, T1T, -D1, D1)
spandrel(-20, 6, 8.2, T1T, -D1, D1, 12)
spandrel(20, 6, 8.2, T1T, -D1, D1, 12)
for zf, out in ((D1, 1), (-D1, -1)):
    voussoirs(0, 10, 6.0, 1.6, zf, out, 15)
    voussoirs(-20, 6, 8.2, 1.3, zf, out, 9)
    voussoirs(20, 6, 8.2, 1.3, zf, out, 9)
box(ledge, -38, 38, T1T, T1T + 0.8, -D1 - 0.4, D1 + 0.4)
for xl, xr in ((-14, -10), (10, 14)):
    cutwater(xl, xr, D1, 3.0, T1B, 3.2)                 # upstream (+z) noses on the river piers, capped below the arch
    knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 13.0, D1, 1)
    knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 6.0, -D1, -1)
    knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 13.0, -D1, -1)

# tier 2: the same arches again, a little narrower front to back
T2B, T2T, D2 = T1T + 0.8, 34.0, 4.0
for x0, x1 in ((-44, -26), (-14, -10), (10, 14), (26, 44)):
    box(stone, x0, x1, T2B, T2T, -D2, D2, uv_masonry)
spandrel(0, 10, 22.4, T2T, -D2, D2)
spandrel(-20, 6, 26.0, T2T, -D2, D2, 12)
spandrel(20, 6, 26.0, T2T, -D2, D2, 12)
for zf, out in ((D2, 1), (-D2, -1)):
    voussoirs(0, 10, 22.4, 1.3, zf, out, 15)
    voussoirs(-20, 6, 26.0, 1.1, zf, out, 9)
    voussoirs(20, 6, 26.0, 1.1, zf, out, 9)
    for xl, xr in ((-14, -10), (10, 14)):
        knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 22.4, zf, out)
box(ledge, -44, 44, T2T, T2T + 0.8, -D2 - 0.4, D2 + 0.4)

# tier 3: the little arcade, the covered channel and its capstones, running out onto the ground at both ends
T3B, D3 = T2T + 0.8, 3.0
PITCH, SPAN = 3.8, 2.6
xs = np.arange(-50.0, 50.0 + 1e-6, PITCH)
for k in range(len(xs) - 1):
    xa, xb = xs[k], xs[k + 1]
    box(stone, xa, xa + (PITCH - SPAN) / 2, T3B, 38.6, -D3, D3, uv_masonry)
    box(stone, xb - (PITCH - SPAN) / 2, xb, T3B, 38.6, -D3, D3, uv_masonry)
    spandrel((xa + xb) / 2, SPAN / 2, 36.0, 38.6, -D3, D3, 8)
box(stone, -50, 50, 38.6, 40.6, -D3, D3, uv_masonry)                     # the channel (covered)
for sx in (-1, 1):
    xa, xb = (50.0, 53.6) if sx > 0 else (-53.6, -50.0)
    box(stone, xa, xb, 38.2, 42.6, -3.6, 3.6, uv_masonry)
    apex = ((xa + xb) / 2, 44.3, 0.0)
    for q in (((xa, 42.6, -3.6), (xb, 42.6, -3.6)), ((xb, 42.6, -3.6), (xb, 42.6, 3.6)), ((xb, 42.6, 3.6), (xa, 42.6, 3.6)), ((xa, 42.6, 3.6), (xa, 42.6, -3.6))):
        cap.tri_flat(q[1], q[0], apex)
xcap = -50.0
while xcap < 50.0 - 0.5:
    box(cap, xcap + 0.06, min(xcap + 2.9, 50.0) - 0.06, 40.6, 41.4, -D3 - 0.3, D3 + 0.3)
    xcap += 2.9

# ---------------------------------------------------------------- kit trees for the render ----
trees = []
trng = np.random.default_rng(5)
KIT = {"pine_tall": ("forest/pine_tall.obj", (1.2, 1.6)), "pine_squat": ("forest/pine_squat.obj", (1.2, 1.5)),
       "olive": ("domaine/olive_tree.obj", (1.0, 1.25)), "cypress": ("domaine/cypress.obj", (0.85, 1.0)),
       "boxwood": ("domaine/boxwood.obj", (1.2, 1.6)), "bush": ("forest/bush_small.obj", (1.2, 1.7))}


def add_tree(kind, x, y, z, scale=None):
    f, (a, b) = KIT[kind]
    trees.append(dict(file=f, x=float(x), y=float(y), z=float(z), scale=float(scale or trng.uniform(a, b)), yaw=float(trng.uniform(0, 360))))


for s in (-1, 1):
    for (z, d, T) in RIM[s][::5]:
        if abs(z) < 11:
            continue
        kind = str(trng.choice(["pine_tall", "pine_tall", "pine_squat", "olive", "olive", "boxwood"]))
        add_tree(kind, float(centre_x(z)) + s * (d + trng.uniform(3.2, 9.0)), T + 0.1, z + trng.uniform(-1.2, 1.2))
        if trng.random() < 0.55:
            add_tree("bush", float(centre_x(z)) + s * (d + trng.uniform(2.6, 4.0)), T + 0.1, z + trng.uniform(-2, 2))
    zc = 8.6
    for zz in (zc, -zc):
        d, T = next((dd, tt) for (z2, dd, tt) in RIM[s] if abs(z2 - zz) < DZ)
        add_tree("cypress", s * (d + 7.5), T + 0.1, zz, 0.95)
# bushes at the foot of the cliffs on the beaches
for s, z in ((-1, 16), (-1, -18), (1, 22), (1, -20), (1, 40), (1, -44)):
    d = float(base_off(z, s)) - 1.2
    add_tree("bush", float(centre_x(z)) + s * d, 0.25, z)
# a bush on each ledge in the face (the Ardeche's green tucked into the rock)
for k, (s_, z, y) in enumerate(SHELVES):
    d = float(face_d(z, np.array([y - 0.2]), s_)[0])
    add_tree("boxwood" if k % 2 else "bush", float(centre_x(z)) + s_ * (d + 0.9), y + 0.05, z)

# ---------------------------------------------------------------- textures ----
make_strata_texture(-1, os.path.join(HERE, "cliff_L.png"))
make_strata_texture(1, os.path.join(HERE, "cliff_R.png"))


def masonry_texture(path):
    PX = 64                                          # pixels per stud
    W, H = int(TILE_U * PX), int(TILE_V * PX)
    img = np.zeros((H, W, 3))
    base = np.array([214, 174, 116], dtype=float)
    mortar = np.array([168, 132, 88], dtype=float)
    r = np.random.default_rng(8)
    course_h = 1.5
    for c in range(int(TILE_V / course_h)):
        y0, y1 = int(c * course_h * PX), int((c + 1) * course_h * PX)
        o = r.uniform(0.0, 3.0)                      # each course starts somewhere else: no joint lines up round the tile
        joints = [o]
        while joints[-1] + 3.6 < o + TILE_U - 1.6:
            joints.append(joints[-1] + r.uniform(2.2, 3.6))
        joints.append(o + TILE_U)
        for k in range(len(joints) - 1):
            xa, xb = int(round(joints[k] * PX)), int(round(joints[k + 1] * PX))
            cols = np.arange(xa, xb) % W
            tint = base * (1 + r.uniform(-0.07, 0.06)) * np.array([1.0, 1 + r.uniform(-0.02, 0.02), 1 + r.uniform(-0.05, 0.04)])
            yy, kk = np.mgrid[y0:y1, 0:(xb - xa)]
            e = np.minimum.reduce([kk, (xb - xa) - 1 - kk, yy - y0, y1 - 1 - yy]).astype(float)
            block = tint[None, None, :] * (0.90 + 0.10 * np.clip(e / 9.0, 0, 1))[..., None]
            block[:, :5] = mortar                    # the vertical joint at the block's left end
            img[y0:y1, cols] = block
        img[y0:y0 + 5, :] = mortar                   # the bed joint
    yy, xx = np.mgrid[0:H, 0:W]
    img *= (1 + 0.035 * vnoise(xx / 23.0, yy / 23.0) + 0.02 * vnoise(xx / 5.0 + 3, yy / 5.0 + 7))[..., None]
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.6)).save(path)


masonry_texture(os.path.join(HERE, "masonry.png"))

# ---------------------------------------------------------------- write ----
MATS = {
    "CliffL": ("tex", "cliff_L.png"), "CliffR": ("tex", "cliff_R.png"), "Masonry": ("tex", "masonry.png"),
    "Grass": ("col", (96, 146, 78)), "Water": ("col", (40, 128, 140)), "Sand": ("col", (226, 206, 160)), "Mud": ("col", (132, 108, 82)),
    "Boulder": ("col", (224, 204, 164)), "AqArch": ("col", (198, 156, 100)), "AqLedge": ("col", (228, 198, 148)),
    "AqCap": ("col", (206, 186, 150)), "AqKnob": ("col", (192, 150, 98)),
}
lines = ["# gen_gorge_sample.py - preview only", "mtllib gorge_sample.mtl"]
vo = 0
for m in MESHES:
    if not m.f:
        continue
    lines += ["o " + m.name, "g " + m.name, "usemtl " + m.mat, "s 1" if m.smooth else "s off"]
    lines += ["v %.4f %.4f %.4f" % p for p in m.v]
    lines += ["vt %.5f %.5f" % t for t in m.vt]
    lines += ["vn %.4f %.4f %.4f" % n for n in m.vn]
    lines += ["f %d/%d/%d %d/%d/%d %d/%d/%d" % (a + vo, a + vo, a + vo, b + vo, b + vo, b + vo, c + vo, c + vo, c + vo) for a, b, c in m.f]
    vo += len(m.v)
with open(os.path.join(HERE, "gorge_sample.obj"), "w", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
ml = []
for k, (kind, val) in MATS.items():
    ml.append("newmtl " + k)
    if kind == "tex":
        ml += ["Kd 1 1 1", "map_Kd " + val]
    else:
        ml.append("Kd %.4f %.4f %.4f" % tuple(c / 255 for c in val))
with open(os.path.join(HERE, "gorge_sample.mtl"), "w", newline="\n") as fh:
    fh.write("\n".join(ml) + "\n")
with open(os.path.join(HERE, "trees.json"), "w") as fh:
    json.dump(dict(root=ROOT, trees=trees, colours={"Foliage": (72, 120, 74), "Trunk": (104, 78, 56), "Olive": (152, 170, 132),
                                                    "OTrunk": (108, 88, 66), "Boxwood": (72, 116, 62), "Cypress": (54, 88, 58),
                                                    "Leaf": (84, 132, 76)}), fh)
print("tris:", {m.name: len(m.f) for m in MESHES}, "| trees", len(trees), "| layers", NL)
