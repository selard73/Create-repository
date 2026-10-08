"""gen_gorge_real.py - the south gorge for the real place (game coordinates), from gorge_shape.py.

Writes, in this folder:
  rock_roblox.obj/.mtl   the rock walls in chunks (SouthRock_W01.., SouthRock_E01..), each centred on its box and turned
                         180 deg about y (Studio's Import 3D turns it back, as for the Sandstone Climb), sharing ONE
                         tiling strata texture (strata.png: 48 studs along the river per repeat)
  aqueduct_roblox.obj/.mtl  the aqueduct pieces (AqStone with masonry.png, AqArch, AqLedge, AqCap, AqKnob), same way
  preview_world.obj/.mtl the rock, the aqueduct, the hills (terrain heightfield), water, beaches and some context, all
                         in world coordinates, for render_gorge_real.py
  gorge_data.json        chunk and piece centres (world), the tree list, and the shape samples for the terrain writer
"""
import json, math, os, shutil
import numpy as np
from PIL import Image, ImageFilter
import gorge_shape as G

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DZC, DY = 1.5, 0.5
Y0 = -8.0
U_TILE = 48.0                                   # studs of river per repeat of the strata texture


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


# ================================================================ the rock walls ================
ZS = np.arange(G.Z_START, G.Z_END - 1e-6, -DZC)          # north to south
V_TOP0 = G.YV1 - 3.0                                     # texture band kept for the weathered top


N_FACE, N_LIP, N_STRIP = 104, 6, 5                        # every column has the same rows: the face from Y0 to the lip's
                                                          # foot, the lip, the top strip - so neighbouring columns always
                                                          # connect like with like (fixed-height rows stretched stray
                                                          # triangles from one column's lip to the next column's face
                                                          # wherever the rim climbs: the dark holes Shannon found, Sep 30)


def column(z, s):
    """the wall's profile at z: N_FACE+1 face rows from Y0 up to the lip's foot (the strata come from the real heights,
    so the beds still line up from column to column), N_LIP rows round the lip, N_STRIP rows back along the top strip,
    dipping under the grass"""
    T = float(G.top_at(z, s)); yf = T - G.RR
    xc = float(G.centre_x(z))
    ys = Y0 + (yf - Y0) * (np.arange(N_FACE + 1) / N_FACE)
    d = G.face_d(z, ys, s)
    pts = [(xc + s * dd, yy, z) for yy, dd in zip(ys, d)]; vs = [float(v) for v in ys]
    df = float(d[-1])
    for k in range(1, N_LIP + 1):
        th = (k / N_LIP) * (math.pi / 2)
        dd = df + G.RR - G.RR * math.cos(th)
        pts.append((xc + s * dd, yf + G.RR * math.sin(th), z)); vs.append(V_TOP0 + 0.3 * k / N_LIP)
    for k in range(1, N_STRIP + 1):
        f = k / N_STRIP
        dd = df + G.RR + f * G.TOP_STRIP
        pts.append((xc + s * dd, T - 2.5 * f * f, z)); vs.append(V_TOP0 + 0.3 + 2.5 * f)
    return pts, vs


def build_side(s):
    cols = [column(z, s) for z in ZS]
    P = np.array([c[0] for c in cols], dtype=float); V = np.array([c[1] for c in cols], dtype=float)
    dx = np.zeros_like(P); dy = np.zeros_like(P)
    dx[1:-1] = P[2:] - P[:-2]; dx[0] = P[1] - P[0]; dx[-1] = P[-1] - P[-2]
    dy[:, 1:-1] = P[:, 2:] - P[:, :-2]; dy[:, 0] = P[:, 1] - P[:, 0]; dy[:, -1] = P[:, -1] - P[:, -2]
    N = np.cross(dx, dy); ln = np.linalg.norm(N, axis=2, keepdims=True); ln[ln == 0] = 1; N = N / ln
    # columns run north to south (-z): (-z) x (+y) = +x, which faces the river for the WEST wall (s = -1)
    if s > 0:
        N = -N
    return P, V, N


def uv_of(z, vy):
    return ((G.Z_START - z) / U_TILE, (vy - G.YV0) / (G.YV1 - G.YV0))


def chunk_mesh(name, P, V, N, c0, c1, s, cap_start=False, cap_end=False):
    m = Mesh(name, "Strata", smooth=True)
    idx = {}
    for ci in range(c0, c1 + 1):
        for ri in range(P.shape[1]):
            idx[ci, ri] = m.vert(P[ci, ri], uv_of(P[ci, ri, 2], V[ci, ri]), N[ci, ri])
    for ci in range(c0, c1):
        for ri in range(P.shape[1] - 1):
            a, b, c, d = idx[ci, ri], idx[ci + 1, ri], idx[ci + 1, ri + 1], idx[ci, ri + 1]
            if s < 0:
                m.f.append((a, b, c)); m.f.append((a, c, d))
            else:
                m.f.append((a, c, b)); m.f.append((a, d, c))
    for ci, want in ((c0, cap_start), (c1, cap_end)):
        if not want:
            continue
        # close the wall's end: a fan from the middle of its profile, facing along the river (+z at the north end)
        pts = [tuple(P[ci, ri]) for ri in range(P.shape[1])]
        facing = 1.0 if ci == c0 else -1.0
        cy = sum(p[1] for p in pts) / len(pts); cx = sum(p[0] for p in pts) / len(pts)
        nrm = (0.0, 0.0, facing)
        cidx = m.vert((cx, cy, pts[0][2]), (cx / U_TILE, (cy - G.YV0) / (G.YV1 - G.YV0)), nrm)
        ids = [m.vert(p, (p[0] / U_TILE, (min(p[1], V_TOP0 - 0.2) - G.YV0) / (G.YV1 - G.YV0)), nrm) for ri, p in enumerate(pts)]
        ring = ids + [ids[0]]
        for k in range(len(ring) - 1):
            a, b = ring[k], ring[k + 1]
            pa, pb = m.v[a - 1], m.v[b - 1]
            cr = (pa[0] - cx) * (pb[1] - cy) - (pa[1] - cy) * (pb[0] - cx)          # z of (pa-c) x (pb-c)
            m.f.append((cidx, a, b) if cr * facing >= 0 else (cidx, b, a))
    return m


ROCK = []
COLS_PER_CHUNK = 26
for s, tag in ((-1, "W"), (1, "E")):
    P, V, N = build_side(s)
    nc = P.shape[0]
    bounds = list(range(0, nc - 1, COLS_PER_CHUNK)) + [nc - 1]
    for k in range(len(bounds) - 1):
        ROCK.append(chunk_mesh("SouthRock_%s%02d" % (tag, k + 1), P, V, N, bounds[k], bounds[k + 1], s,
                               cap_start=(k == 0), cap_end=False))                 # (the headwall meets the walls at the end)


def strata_texture(path, ylo=G.YV0, yhi=G.YV1, A=G.UPPER, lays=G.layers, wet_y=G.WATER_Y + 0.6, top_band=True):
    """one texture for every chunk: strata by height (ylo..yhi), repeating every U_TILE studs along the river; the
    cliff under the falls gets a second one for the beds below the river-bed level (its wet band at the harbour)"""
    TW, TH = 1024, 1024
    us = (np.arange(TW) + 0.5) / TW                       # 0..1 along one repeat
    ys = yhi - (np.arange(TH) + 0.5) / TH * (yhi - ylo)
    U2, Y2 = np.meshgrid(us, ys)
    th = 2 * math.pi * U2
    R = 6.0
    def tn(sc_y, off):                                     # noise that repeats seamlessly along u
        return 0.5 * (G.vnoise(R * np.cos(th) + off, Y2 * sc_y + R * np.sin(th)) + G.vnoise(R * np.sin(th) + off + 17, Y2 * sc_y * 1.3 + R * np.cos(th) + 5))
    Y0a, Ta = A[0], A[1]
    li = np.clip(np.searchsorted(Y0a, Y2, side="right") - 1, 0, A[7] - 1)
    cols = np.array([l["col"] for l in lays], dtype=float)
    img = cols[li]
    uu = np.clip((Y2 - Y0a[li]) / Ta[li], 0, 1)
    img = img * (1 + 0.05 * tn(0.2, li * 0.37)[..., None])
    R2 = 22.0
    fine = 0.5 * (G.vnoise(R2 * np.cos(th), Y2 * 5.3 + R2 * np.sin(th)) + G.vnoise(R2 * np.sin(th) + 9, Y2 * 7.1 + R2 * np.cos(th)))
    img = img * (1 + 0.05 * fine[..., None])
    # the shadow notch at the base of each bed and a lighter lip at its top edge
    shade = 1.0 - 0.16 * (1 - G.smoothstep(0.0, 0.28, uu)) + 0.04 * G.smoothstep(0.8, 1.0, uu)
    img = img * np.stack([shade ** 0.75, shade ** 1.0, shade ** 1.4], axis=-1) * 1.04
    wet = np.exp(-((Y2 - wet_y) / 0.7) ** 2)[..., None]
    img = img * (1 - 0.22 * wet)
    if top_band:
        top = Y2 > V_TOP0 - 0.1
        tc = np.array(G.TOPCREAM, dtype=float)[None, None, :] * (1 + 0.06 * tn(1.3, 3)[..., None] + 0.03 * fine[..., None])
        img = np.where(top[..., None], tc, img)
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.5)).save(path)


# ================================================================ the cliff and the falls (the gorge's end) ================
# Shannon (Sep 30 evening): the gorge OPENS onto a waterfall. The walls end at sharp corners at their last column
# (ZC); from each corner a cliff arm sweeps south round the plunge pool (the cove), and between the corners the river
# pours over a rounded sill. An arm's first column IS the wall's last column (same rows, same points), so the join is
# seamless; the face carries the walls' strata on past the corner (the along-face coordinate continues the wall's z),
# and the beds carry on down to the pool bed with a second texture (strata_low.png) below the river-bed level.
ZC = float(ZS[-1]); assert abs(ZC - G.ZC) < 1e-6, (ZC, G.ZC)
CXE = float(G.centre_x(ZC))
XCW, XCE = G.corner_x(-1), G.corner_x(1)
N_LOW = 96                                                # rows from the pool bed up to Y0 (the texture split)
K_SILL = 8                                                # the lip's face keeps the corners' first rows above Y0, then the sill
COLS_C = 26


def wall_face_x(y, s):
    """x of the wall's face at its last column (z = ZC): the corner's arris follows it"""
    return float(G.centre_x(ZC)) + s * G.face_d(ZC, np.asarray(y, dtype=float), s)


def arm_path(a, s):
    """plan position of an arm's base line a studs (along x) out from its corner, and the outward (air-side) unit normal"""
    a = float(a)
    x = G.corner_x(s) + s * a; z = ZC - float(G.cove(a))
    da = 0.5
    slope = (float(G.cove(a + da)) - float(G.cove(max(a - da, 0.0)))) / (da + min(a, da))       # d cove / d a >= 0
    tx, tz = s, -slope
    ln = math.hypot(tx, tz); tx, tz = tx / ln, tz / ln
    return x, z, s * tz, -s * tx                          # n = s (t_z, -t_x): south-ish, toward the air


_AA = np.linspace(0.0, G.ARM_L + 2.0, 4000)
_ARC = np.concatenate([[0.0], np.cumsum(np.hypot(np.diff(_AA), np.diff(np.array([float(G.cove(v)) for v in _AA]))))])


def arc_of(a):
    return float(np.interp(a, _AA, _ARC))


def arm_column(a, s):
    """one column of a cliff arm: N_LOW rows from the pool bed to Y0, then exactly the wall's row scheme (N_FACE face
    rows to the lip's foot, the lip, the top strip going back into the ridge). At a = 0 it is the wall's own last
    column with the low rows under it."""
    T = float(G.cliff_T(a, s)); yf = T - G.RR
    ys_low = G.Y_FOOT + (Y0 - G.Y_FOOT) * (np.arange(N_LOW) / N_LOW)
    zv = ZC - arc_of(a)                                   # the along-face coordinate (texture, beds, joints)
    if a <= 1e-9:
        xs = wall_face_x(ys_low, s)
        pts = [(float(x), float(y), ZC) for x, y in zip(xs, ys_low)]; vs = [float(y) for y in ys_low]
        p2, v2 = column(ZC, s)
        return pts + p2, vs + v2, zv
    x0, z0, nx, nz = arm_path(a, s)
    ys_up = Y0 + (yf - Y0) * (np.arange(N_FACE + 1) / N_FACE)
    ys = np.concatenate([ys_low, ys_up]); zvs = np.full(ys.shape, zv)
    wc = float(G.smoothstep(0.0, 6.0, a))                 # the wall's own features right at the corner, the arm's beyond
    rel = ((1 - wc) * G.relief(zvs, ys, T, s) + wc * G.relief(zvs, ys, T, 2 * s)) * float(G.smoothstep(0.0, 4.0, a))
    notch = 1.3 * np.exp(-((ys - (G.SEA_Y + 2.2)) / 2.0) ** 2) * float(G.smoothstep(0.0, 10.0, a))   # the harbour's waterline notch
    d = rel - G.arm_lean(a, ys) - notch                   # offset along n: + toward the air
    shear = (wall_face_x(ys, s) - G.corner_x(s)) * (1 - float(G.smoothstep(0.0, 30.0, a)))   # columns near the corner keep its slant
    pts = [(x0 + float(sx) + nx * float(dd), float(yy), z0 + nz * float(dd)) for sx, yy, dd in zip(shear, ys, d)]
    vs = [float(v) for v in ys]
    df = float(d[-1]); shf = float(shear[-1])
    for k in range(1, N_LIP + 1):
        th = (k / N_LIP) * (math.pi / 2)
        dd = df - (G.RR - G.RR * math.cos(th))
        pts.append((x0 + shf + nx * dd, yf + G.RR * math.sin(th), z0 + nz * dd)); vs.append(V_TOP0 + 0.3 * k / N_LIP)
    for k in range(1, N_STRIP + 1):
        f = k / N_STRIP
        dd = df - G.RR - f * G.TOP_STRIP
        pts.append((x0 + shf + nx * dd, T - 2.5 * f * f, z0 + nz * dd)); vs.append(V_TOP0 + 0.3 + 2.5 * f)
    return pts, vs, zv


def lip_column(x):
    """one column of the face under the lip (between the corners, on z = ZC): the low rows, the corners' first K_SILL
    rows above Y0, the rounded sill, and the sill sloping back down to the river bed. Its end columns coincide with the
    corners' columns row for row."""
    t = (XCE - x) / (XCE - XCW)
    ys_low = G.Y_FOOT + (Y0 - G.Y_FOOT) * (np.arange(N_LOW) / N_LOW)
    yfw = float(G.cliff_T(0.0, -1)) - G.RR; yfe = float(G.cliff_T(0.0, 1)) - G.RR
    yf = yfe * (1 - t) + yfw * t
    ys = np.concatenate([ys_low, Y0 + (yf - Y0) * (np.arange(K_SILL + 1) / N_FACE)])
    ww = 1 - float(G.smoothstep(0.0, 4.0, x - XCW)); we = 1 - float(G.smoothstep(0.0, 4.0, XCE - x))
    zv = ZC - 2.0 * (XCE - x)
    rel = 0.45 * G.relief(np.full(ys.shape, zv), ys, float(G.cliff_T(0.0, -1)), -2) * (1 - max(ww, we))
    xs = x + ww * (wall_face_x(ys, -1) - XCW) + we * (wall_face_x(ys, 1) - XCE)
    pts = [(float(xx), float(yy), ZC + float(dd)) for xx, yy, dd in zip(xs, ys, rel)]; vs = [float(v) for v in ys]
    y0s = float(ys[-1]); df = float(rel[-1]); xf = float(xs[-1])
    for k in range(1, N_LIP + 1):
        th = (k / N_LIP) * (math.pi / 2)
        pts.append((xf, y0s + G.SILL_R * math.sin(th), ZC + df + G.SILL_R - G.SILL_R * math.cos(th))); vs.append(V_TOP0 + 0.3 * k / N_LIP)
    ytop = y0s + G.SILL_R
    for k in range(1, N_STRIP + 1):
        f = k / N_STRIP
        pts.append((xf, ytop - (ytop - (Y0 + 0.3)) * f, ZC + df + G.SILL_R + f * (G.SILL_RUN - G.SILL_R - df))); vs.append(V_TOP0 + 0.3 + 2.5 * f)
    return pts, vs, zv


def strip_meshes(tag, cols, s_wind, cap_end_dir=None):
    """cols: (pts, vs, zv) per column in order; s_wind = -1 when (column direction) x (+y) already points to the air,
    +1 when it must be flipped. Chunks of COLS_C columns; each chunk becomes two meshes: rows 0..N_LOW with
    strata_low.png (name suffix _Lo) and the rest with strata.png. Optionally a fan closes the last column."""
    P = np.array([c[0] for c in cols], dtype=float); V = np.array([c[1] for c in cols], dtype=float); ZV = [c[2] for c in cols]
    dx = np.zeros_like(P); dy = np.zeros_like(P)
    dx[1:-1] = P[2:] - P[:-2]; dx[0] = P[1] - P[0]; dx[-1] = P[-1] - P[-2]
    dy[:, 1:-1] = P[:, 2:] - P[:, :-2]; dy[:, 0] = P[:, 1] - P[:, 0]; dy[:, -1] = P[:, -1] - P[:, -2]
    N = np.cross(dx, dy); ln = np.linalg.norm(N, axis=2, keepdims=True); ln[ln == 0] = 1; N = N / ln
    if s_wind > 0:
        N = -N
    nc = P.shape[0]
    bounds = list(range(0, nc - 1, COLS_C)) + [nc - 1]
    out = []
    for k in range(len(bounds) - 1):
        c0, c1 = bounds[k], bounds[k + 1]
        for part, (r0, r1) in (("Lo", (0, N_LOW)), ("", (N_LOW, P.shape[1] - 1))):
            m = Mesh("SouthCliff_%s%02d%s" % (tag, k + 1, "_Lo" if part else ""), "StrataLow" if part else "Strata", smooth=True)
            idx = {}
            for ci in range(c0, c1 + 1):
                for ri in range(r0, r1 + 1):
                    y = P[ci, ri, 1]
                    uv = ((G.Z_START - ZV[ci]) / U_TILE, (y - G.Y_FOOT) / (Y0 - G.Y_FOOT)) if part else uv_of(ZV[ci], V[ci, ri])
                    idx[ci, ri] = m.vert(P[ci, ri], uv, N[ci, ri])
            for ci in range(c0, c1):
                for ri in range(r0, r1):
                    a, b, c, d = idx[ci, ri], idx[ci + 1, ri], idx[ci + 1, ri + 1], idx[ci, ri + 1]
                    if s_wind < 0:
                        m.f.append((a, b, c)); m.f.append((a, c, d))
                    else:
                        m.f.append((a, c, b)); m.f.append((a, d, c))
            if cap_end_dir is not None and c1 == nc - 1:
                # close the arm's far end with a fan (it is buried in the ridge's terrain slope), facing out along the arm
                pts = [tuple(P[c1, ri]) for ri in range(r0, r1 + 1)]
                cen = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts), sum(p[2] for p in pts) / len(pts))
                nrm = (cap_end_dir, 0.0, 0.0)
                cidx = m.vert(cen, (0.0, 0.5), nrm)
                ids = [m.vert(p, (p[2] / U_TILE, 0.5), nrm) for p in pts]
                for q in range(len(ids) - 1):
                    a, b = ids[q], ids[q + 1]
                    n_ = np.cross(np.subtract(m.v[a - 1], cen), np.subtract(m.v[b - 1], cen))
                    m.f.append((cidx, a, b) if n_[0] * cap_end_dir >= 0 else (cidx, b, a))
            out.append(m)
    return out


CLIFF = []
AS = np.arange(0.0, G.ARM_L + 1e-6, DZC)
for s, tag in ((-1, "W"), (1, "E")):
    CLIFF += strip_meshes(tag, [arm_column(a, s) for a in AS], s, cap_end_dir=float(s))
_lx = np.linspace(XCE, XCW, int(round((XCE - XCW) / DZC)) + 1)            # east to west, so the face points south
CLIFF += strip_meshes("L", [lip_column(x) for x in _lx], -1)

# preview only: the falling water, its foam and mist, and the harbour/sea water plane (terrain water in the game)
falls = Mesh("Falls", "Falls"); foam = Mesh("Foam", "Foam"); mist = Mesh("Mist", "Mist"); sea = Mesh("Sea", "Water")
_nf = 26


def _sheet(t):
    # leaves the sill going forward (clear of the face within a couple of studs), then arcs down to the pool
    return (G.WATER_Y - (G.FALL_H + 0.8) * t, ZC + 1.0 - 5.0 * math.sqrt(t) - 2.5 * t * t)


for i in range(_nf):
    t0, t1 = i / _nf, (i + 1) / _nf
    (ya, za), (yb, zb) = _sheet(t0), _sheet(t1)
    w0 = G.FALL_W / 2 + 1.5 * t0; w1 = G.FALL_W / 2 + 1.5 * t1
    A, B, C, D = (CXE - w0, ya, za), (CXE + w0, ya, za), (CXE + w1, yb, zb), (CXE - w1, yb, zb)
    falls.quad_flat(A, B, C, D); falls.quad_flat(A, D, C, B)
_fc = (CXE, G.SEA_Y + 0.15, ZC - 7.0)
for k in range(28):
    a0, a1 = 2 * math.pi * k / 28, 2 * math.pi * (k + 1) / 28
    foam.tri_flat(_fc, (CXE + 17 * math.cos(a1), _fc[1], _fc[2] + 17 * math.sin(a1)), (CXE + 17 * math.cos(a0), _fc[1], _fc[2] + 17 * math.sin(a0)))
for ang in (0.0, math.pi / 2):
    ux, uz = math.cos(ang) * 14, math.sin(ang) * 14
    A, B = (CXE - ux, G.SEA_Y - 0.5, ZC - 6 - uz), (CXE + ux, G.SEA_Y - 0.5, ZC - 6 + uz)
    C, D = (CXE + ux, G.SEA_Y + 19.0, ZC - 6 + uz), (CXE - ux, G.SEA_Y + 19.0, ZC - 6 - uz)
    mist.quad_flat(A, B, C, D); mist.quad_flat(A, D, C, B)
sea.quad_flat((-1500.0, G.SEA_Y, ZC + 0.5), (2000.0, G.SEA_Y, ZC + 0.5), (2000.0, G.SEA_Y, -3000.0), (-1500.0, G.SEA_Y, -3000.0))
FALLS_PREV = [falls, foam, mist, sea]
print("cliff: arm columns", len(AS), "lip columns", len(_lx), "| corners x %.2f / %.2f  crest z %.1f  sea %.1f plain %.1f" % (XCW, XCE, ZC, G.SEA_Y, G.PLAIN_Y))


# ================================================================ the aqueduct ================
TILE_U, TILE_V = 12.0, 6.0
AQ = []


def uv_masonry(p, n):
    ax = int(np.argmax(np.abs(n)))
    if ax == 1:
        return (p[0] / TILE_U, p[2] / TILE_V)
    if ax == 0:
        return (p[2] / TILE_U, p[1] / TILE_V)
    return (p[0] / TILE_U, p[1] / TILE_V)


stone = Mesh("AqStone", "Masonry"); archm = Mesh("AqArch", "AqArch"); ledge = Mesh("AqLedge", "AqLedge")
capm = Mesh("AqCap", "AqCap"); knob = Mesh("AqKnob", "AqKnob")
AQ = [stone, archm, ledge, capm, knob]
OX, OZ = G.XB, G.ZB                                      # built round (0, 0) and moved here


def W(p):
    return (p[0] + OX, p[1], p[2] + OZ)


def box(m, x0, x1, y0, y1, z0, z1, uvf=None, skip=()):
    A = (x0, y0, z0); B = (x1, y0, z0); C = (x1, y1, z0); D = (x0, y1, z0)
    E = (x0, y0, z1); F = (x1, y0, z1); Gp = (x1, y1, z1); H = (x0, y1, z1)
    faces = {"-z": (A, D, C, B), "+z": (E, F, Gp, H), "-x": (A, E, H, D), "+x": (B, C, Gp, F), "-y": (A, B, F, E), "+y": (D, H, Gp, C)}
    for k, q in faces.items():
        if k not in skip:
            m.quad_flat(*[W(p) for p in q], uvf=uvf)


def arch_pts(xc, r, ys, n):
    return [(xc + r * math.cos(math.pi - math.pi * k / n), ys + r * math.sin(math.pi - math.pi * k / n)) for k in range(n + 1)]


def spandrel(xc, r, ys, top, z0, z1, n=16):
    pts = arch_pts(xc, r, ys, n)
    for k in range(n):
        (xa, ya), (xb, yb) = pts[k], pts[k + 1]
        stone.quad_flat(W((xa, ya, z1)), W((xb, yb, z1)), W((xb, top, z1)), W((xa, top, z1)), uv_masonry)
        stone.quad_flat(W((xa, ya, z0)), W((xa, top, z0)), W((xb, top, z0)), W((xb, yb, z0)), uv_masonry)
        stone.quad_flat(W((xa, ya, z0)), W((xb, yb, z0)), W((xb, yb, z1)), W((xa, ya, z1)), uv_masonry)


def voussoirs(xc, r, ys, t, zface, out, n):
    for k in range(n):
        a0, a1 = math.pi - math.pi * k / n + 0.004, math.pi - math.pi * (k + 1) / n - 0.004
        key = (k == n // 2)
        tt = t + (0.45 if key else 0.0)
        pr = 0.30 if key else (0.22 if k % 2 == 0 else 0.15)
        z0, z1 = (zface - 0.02, zface + pr) if out > 0 else (zface - pr, zface + 0.02)
        pi0 = (xc + r * math.cos(a0), ys + r * math.sin(a0)); pi1 = (xc + r * math.cos(a1), ys + r * math.sin(a1))
        po0 = (xc + (r + tt) * math.cos(a0), ys + (r + tt) * math.sin(a0)); po1 = (xc + (r + tt) * math.cos(a1), ys + (r + tt) * math.sin(a1))
        zo, zi = (z1, z0) if out > 0 else (z0, z1)
        F = [W((pi0[0], pi0[1], zo)), W((pi1[0], pi1[1], zo)), W((po1[0], po1[1], zo)), W((po0[0], po0[1], zo))]
        Bk = [W((pi0[0], pi0[1], zi)), W((pi1[0], pi1[1], zi)), W((po1[0], po1[1], zi)), W((po0[0], po0[1], zi))]
        if out > 0:
            archm.quad_flat(F[0], F[1], F[2], F[3])
        else:
            archm.quad_flat(F[0], F[3], F[2], F[1])
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
    L0, R0, N0 = W((xl, y0, zface)), W((xr, y0, zface)), W((xc, y0, zface + ext))
    L1, R1, N1 = W((xl, yc, zface)), W((xr, yc, zface)), W((xc, yc, zface + ext))
    Pk = W((xc, yc + ext * 0.85, zface))
    stone.quad_flat(L0, N0, N1, L1, uv_masonry); stone.quad_flat(N0, R0, R1, N1, uv_masonry)
    stone.tri_flat(L1, N1, Pk, uv_masonry); stone.tri_flat(N1, R1, Pk, uv_masonry)


T1B, T1T, D1 = -9.0, 19.2, 5.0
for x0, x1 in ((-38, -26), (-14, -10), (10, 14), (26, 38)):
    box(stone, x0, x1, T1B, T1T, -D1, D1, uv_masonry)
spandrel(0, 10, 6.0, T1T, -D1, D1); spandrel(-20, 6, 8.2, T1T, -D1, D1, 12); spandrel(20, 6, 8.2, T1T, -D1, D1, 12)
for zf, out in ((D1, 1), (-D1, -1)):
    voussoirs(0, 10, 6.0, 1.6, zf, out, 15); voussoirs(-20, 6, 8.2, 1.3, zf, out, 9); voussoirs(20, 6, 8.2, 1.3, zf, out, 9)
box(ledge, -38, 38, T1T, T1T + 0.8, -D1 - 0.4, D1 + 0.4)
for xl, xr in ((-14, -10), (10, 14)):
    cutwater(xl, xr, D1, 3.0, T1B, 3.2)                 # upstream noses (the river flows toward -z)
    knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 13.0, D1, 1)
    knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 6.0, -D1, -1)
    knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 13.0, -D1, -1)
T2B, T2T, D2 = T1T + 0.8, 34.0, 4.0
for x0, x1 in ((-44, -26), (-14, -10), (10, 14), (26, 44)):
    box(stone, x0, x1, T2B, T2T, -D2, D2, uv_masonry)
spandrel(0, 10, 22.4, T2T, -D2, D2); spandrel(-20, 6, 26.0, T2T, -D2, D2, 12); spandrel(20, 6, 26.0, T2T, -D2, D2, 12)
for zf, out in ((D2, 1), (-D2, -1)):
    voussoirs(0, 10, 22.4, 1.3, zf, out, 15); voussoirs(-20, 6, 26.0, 1.1, zf, out, 9); voussoirs(20, 6, 26.0, 1.1, zf, out, 9)
    for xl, xr in ((-14, -10), (10, 14)):
        knobs(((xl + xr) / 2 - 1.0, (xl + xr) / 2 + 1.0), 22.4, zf, out)
box(ledge, -44, 44, T2T, T2T + 0.8, -D2 - 0.4, D2 + 0.4)
T3B, D3 = T2T + 0.8, 3.0
PITCH, SPAN = 3.8, 2.6
xs3 = np.arange(-50.0, 50.0 + 1e-6, PITCH)
for k in range(len(xs3) - 1):
    xa, xb = xs3[k], xs3[k + 1]
    box(stone, xa, xa + (PITCH - SPAN) / 2, T3B, 38.6, -D3, D3, uv_masonry)
    box(stone, xb - (PITCH - SPAN) / 2, xb, T3B, 38.6, -D3, D3, uv_masonry)
    spandrel((xa + xb) / 2, SPAN / 2, 36.0, 38.6, -D3, D3, 8)
box(stone, -50, 50, 38.6, 40.6, -D3, D3, uv_masonry)
for sx in (-1, 1):                                        # the inspection shafts where the channel goes underground
    xa, xb = (50.0, 53.6) if sx > 0 else (-53.6, -50.0)
    box(stone, xa, xb, 38.0, 42.6, -3.6, 3.6, uv_masonry)
    apex = W(((xa + xb) / 2, 44.3, 0.0))
    for q in (((xa, 42.6, -3.6), (xb, 42.6, -3.6)), ((xb, 42.6, -3.6), (xb, 42.6, 3.6)), ((xb, 42.6, 3.6), (xa, 42.6, 3.6)), ((xa, 42.6, 3.6), (xa, 42.6, -3.6))):
        capm.tri_flat(W(q[1]), W(q[0]), apex)
xcap = -50.0
while xcap < 50.0 - 0.5:
    box(capm, xcap + 0.06, min(xcap + 2.9, 50.0) - 0.06, 40.6, 41.4, -D3 - 0.3, D3 + 0.3)
    xcap += 2.9

# ================================================================ terrain (preview of what the terrain writer makes) ======
def corridor(x, z):
    """(inside the gorge opening?, s, distance from the centre line, rim distance)"""
    if z > G.Z_START or z < ZC:
        return False, 0, 0.0, 0.0
    xc = float(G.centre_x(z)); s = 1 if x >= xc else -1
    d = abs(x - xc); rd = G.rim_d(z, s)
    return d < rd + 1.5, s, d, rd


_RIM_CACHE = {}


def rim_cached(z, s):
    k = (round(z * 2) / 2, s)
    if k not in _RIM_CACHE:
        _RIM_CACHE[k] = (G.rim_d(k[0], s), float(G.top_at(k[0], s)))
    return _RIM_CACHE[k]


def south_terrain(x, z, hill):
    """south of the gorge: the plateau behind the cliff arms (None right behind their faces, as along the walls), the
    ridge's terrain slope beyond the arms, and in front of it all the plain, the cove and the sea"""
    zc = float(G.crest_z(x))
    a = max(0.0, max(XCW - x, x - XCE)); s = -1 if x < CXE else 1
    T = float(G.cliff_T(a, s))
    low = float(G.south_height(x, z))
    if a <= G.ARM_L and z < zc:
        return low                                        # the plain, the cove, the pool: right up to the face's foot
    if a <= G.ARM_L - 4.0:                                # (the last 4 studs of an arm take the slope rule below, so the
        dn = z - zc                                       #  preview grid has no hole where the hollow meets the slope)
        rim = float(G.arm_lean(a, T - G.RR)) + G.RR       # the lip's top sits this far north of the base line
        if dn < rim + 1.5:
            return None
        blend = float(G.smoothstep(rim + 5.0, rim + 25.0, dn))
        return (T + 0.1) * (1 - blend) + max(hill, 0.0) * blend
    # beyond the arms the ridge's south side is a terrain slope that climbs NORTH from the base line with exactly the
    # profile of the arms' end faces (the inverse of arm_lean at a = ARM_L: 0.44 per stud from the plain up to y 0,
    # 0.6 per stud above), stretched toward a gentler slope further out, with a little wander so it does not read as
    # one long embankment. Matching the end face closes the hollow behind the arm's top from the side.
    ease = float(G.smoothstep(G.ARM_L, G.ARM_L + 80.0, a))
    wander = 1.0 + 0.22 * math.sin(x / 41.0 + 1.0) * float(G.smoothstep(G.ARM_L, G.ARM_L + 40.0, a))
    stretch = (1.0 + 0.8 * ease) * wander
    dn = z - zc                                           # > 0 north of the base line
    if dn <= 0:
        return low
    d = dn / stretch
    d0 = 0.44 * (0.0 - G.PLAIN_Y)                        # where the end face reaches y 0
    prof = G.PLAIN_Y + d / 0.44 if d <= d0 else (d - d0) / 0.60
    if prof < T:
        return max(low, prof)
    top = (d0 + 0.60 * T) * stretch                       # dn where the slope reaches the crest
    blend = float(G.smoothstep(top, top + 25.0, dn))
    return T * (1 - blend) + max(hill, 0.0) * blend


def terrain_height(x, z, preview=False):
    """the terrain's surface at (x, z), or None where the terrain writer leaves things alone (for the preview mesh, the
    existing ground near the walls is drawn flat at y 0)"""
    wz = float(G.wall_z(x))
    if preview and z > G.Z_START - 1.0 and abs(x - float(G.centre_x(z))) < float(G.half_width(z)) + 2.0:
        return None                                       # the river between the village wall and the gorge: left as it is
    if z > wz - 10.0:
        return 0.0 if preview and not (ZC <= z <= G.Z_START and abs(x - float(G.centre_x(z))) < rim_cached(z, 1 if x >= float(G.centre_x(z)) else -1)[0] + 1.5) else None
    dz = wz - z
    hill = float(G.ridge_profile(dz) + G.hill_noise(x, z) * G.smoothstep(14.0, 60.0, dz))
    if ZC <= z <= G.Z_START:
        xc = float(G.centre_x(z)); s = 1 if x >= xc else -1
        d = abs(x - xc)
        rd, T = rim_cached(z, s)
        if d < rd + 1.5:
            return None                                   # the gorge itself (rock, water, beaches)
        blend = float(G.smoothstep(rd + 5.0, rd + 25.0, d))
        return (T + 0.1) * (1 - blend) + max(hill, 0.0) * blend
    if z < ZC:
        return south_terrain(x, z, hill)
    return max(hill, 0.0)


def terrain_mesh(step=4.0):
    """the terrain as meshes by kind: Hills (the ridge), Slope (steep ground), Plain, Sand (banks by the water) and
    Bed (under the sea). Quads that straddle the cliff line where the rock mesh provides the face are pulled down to
    the plain at the face's foot (the terrain writer does the same)."""
    xs = np.arange(-520.0, 1020.0 + 1e-6, step)               # the terrain writer's whole width
    zs = np.arange(-200.0, -1400.0 - 1e-6, -step)
    H = np.full((len(zs), len(xs)), np.nan)
    for i, z in enumerate(zs):
        for j, x in enumerate(xs):
            h = terrain_height(x, z, preview=True)
            if h is not None:
                H[i, j] = h
    crest = np.array([float(G.crest_z(x)) for x in xs])
    meshes = {k: Mesh(k, mat) for k, mat in (("Hills", "Grass"), ("Slope", "Slope"), ("Plain", "Plain"), ("Sand", "Sand"), ("Bed", "Bed"))}
    for i in range(len(zs) - 1):
        for j in range(len(xs) - 1):
            q = [(i, j), (i, j + 1), (i + 1, j + 1), (i + 1, j)]
            hs = [H[a, b] for a, b in q]
            if any(np.isnan(hs)):
                continue
            south = [zs[a] < crest[b] for a, b in q]
            if any(south) and not all(south) and XCW - G.ARM_L - 2 <= xs[j] and xs[j + 1] <= XCE + G.ARM_L + 2:
                P = [(xs[b], H[a, b] if zs[a] < crest[b] else float(G.south_height(xs[b], crest[b] - 0.5)), zs[a] if zs[a] < crest[b] else crest[b] - 0.01) for a, b in q]
                south = [True] * 4
            else:
                P = [(xs[b], H[a, b], zs[a]) for a, b in q]
            ym = sum(p[1] for p in P) / 4
            steep = max(hs) - min(hs) > 0.9 * step
            dnq = [zs[a] - crest[b] for a, b in q]
            if all(south):
                key = "Bed" if ym < G.SEA_Y - 1.5 else "Sand" if ym < G.SEA_Y + 2.5 else "Slope" if steep else "Plain"
            elif steep and max(dnq) < 130.0:
                key = "Slope"                             # the ridge's steep south side beyond the arms (sandstone in the game)
            else:
                key = "Hills"
            # rows run south (-z), columns east (+x): (+x) x (-z) = +y
            meshes[key].quad_flat(P[0], P[1], P[2], P[3])
    return list(meshes.values())


TERR = terrain_mesh()

# beaches and banks inside the gorge (terrain in the game; a strip mesh here), and the water
sand = Mesh("Sand", "Sand"); mud = Mesh("Mud", "Mud")
for s in (-1, 1):
    zs_b = np.arange(G.Z_START - 2, ZC + 1.0, -1.5)
    for z0, z1 in zip(zs_b[:-1], zs_b[1:]):
        f0, f1 = float(G.foot(z0, s)), float(G.foot(z1, s)); h0, h1 = float(G.half_width(z0)), float(G.half_width(z1))
        if min(f0 - h0, f1 - h1) < 1.2:
            continue
        def prof(z, f, h):
            ramp = float(G.smoothstep(1.2, 3.0, f - h))
            ds = [h - 1.6, h - 0.2, h + 1.2, h + 3.0, f + 2.0]
            ds = [dd for dd in ds if dd <= f + 2.0]
            out = []
            for dd in ds:
                if dd <= h - 1.5:
                    hh = G.WATER_Y - 1.1
                elif dd <= h:
                    hh = G.WATER_Y + 0.2
                elif dd <= h + 1.3:
                    hh = 0.1
                else:
                    hh = 0.25 + 0.08 * math.sin(z / 3.7 + dd)
                out.append((dd, (G.WATER_Y - 0.5) + (hh - (G.WATER_Y - 0.5)) * ramp))
            return out
        p0, p1 = prof(z0, f0, h0), prof(z1, f1, h1)
        n = min(len(p0), len(p1))
        xa0, xa1 = float(G.centre_x(z0)), float(G.centre_x(z1))
        for j in range(n - 1):
            (da, ha), (db, hb) = p0[j], p0[j + 1]
            (dc, hc), (dd_, hd) = p1[j], p1[j + 1]
            q = [(xa0 + s * da, ha, z0), (xa1 + s * dc, hc, z1), (xa1 + s * dd_, hd, z1), (xa0 + s * db, hb, z0)]
            tgt = mud if (db - h0) <= 1.3 else sand
            # rows run south: for the east side (+x outward) (-z) x (+x) = -y, so flip
            if s > 0:
                tgt.quad_flat(q[0], q[3], q[2], q[1])
            else:
                tgt.quad_flat(q[0], q[1], q[2], q[3])
water = Mesh("Water", "Water")
water.quad_flat((146.5, G.WATER_Y, -110), (170.5, G.WATER_Y, -110), (174.0, G.WATER_Y, -216), (146.5, G.WATER_Y, -216))
_wz = np.arange(G.Z_START + 1.0, G.Z_END - 1e-6, -1.5)
for z0, z1 in zip(_wz[:-1], _wz[1:]):
    a0 = float(G.face_d(z0, np.array([G.WATER_Y]), -1)[0]) + 1.0; b0 = float(G.face_d(z0, np.array([G.WATER_Y]), 1)[0]) + 1.0
    a1 = float(G.face_d(z1, np.array([G.WATER_Y]), -1)[0]) + 1.0; b1 = float(G.face_d(z1, np.array([G.WATER_Y]), 1)[0]) + 1.0
    if a0 + b0 <= 0 and a1 + b1 <= 0:
        continue
    c0, c1 = float(G.centre_x(z0)), float(G.centre_x(z1))
    water.quad_flat((c0 - a0, G.WATER_Y, z0), (c0 + b0, G.WATER_Y, z0), (c1 + b1, G.WATER_Y, z1), (c1 - a1, G.WATER_Y, z1))
# context: the play area's ground (Baseplate + terrain grass at about y 0) with the river's south stretch, the jetty, the boat
ground = Mesh("Ground", "Grass")
for (x0, x1, z0, z1) in ((-240, 146.5, 40, -214), (170.5, 1000, 40, -214), (146.5, 170.5, 40, -110)):
    ground.quad_flat((x0, 0.05, z0), (x1, 0.05, z0), (x1, 0.05, z1), (x0, 0.05, z1))
for (x0, x1, z0, z1) in ((-240, 1000, -214, -1022),):
    pass
jetty = Mesh("Jetty", "Wood")
box_j = [(160.4, 163.9, -168, -146)]
for x0, x1, z0, z1 in box_j:
    A = (x0, 0.2, z0); B = (x1, 0.2, z0); C = (x1, 0.9, z0); D = (x0, 0.9, z0); E = (x0, 0.2, z1); F = (x1, 0.2, z1); Gp = (x1, 0.9, z1); H = (x0, 0.9, z1)
    for q in ((A, D, C, B), (E, F, Gp, H), (A, E, H, D), (B, C, Gp, F), (D, H, Gp, C)):
        jetty.quad_flat(*q)
boat = Mesh("Boat", "BoatGreen")
for q in (((155.5, -0.9, -161), (159.7, -0.9, -161), (159.7, 1.4, -161), (155.5, 1.4, -161)),
          ((155.5, -0.9, -153), (155.5, 1.4, -153), (159.7, 1.4, -153), (159.7, -0.9, -153)),
          ((155.5, 1.4, -161), (159.7, 1.4, -161), (159.7, 1.4, -153), (155.5, 1.4, -153))):
    boat.quad_flat(*q)

# ================================================================ trees (kit copies) ================
trng = np.random.default_rng(5)
KIT = {"pine_tall": ("forest/pine_tall.obj", (1.2, 1.6)), "pine_squat": ("forest/pine_squat.obj", (1.2, 1.5)),
       "olive": ("domaine/olive_tree.obj", (1.0, 1.25)), "cypress": ("domaine/cypress.obj", (0.85, 1.0)),
       "boxwood": ("domaine/boxwood.obj", (1.2, 1.6)), "bush": ("forest/bush_small.obj", (1.2, 1.7))}
TREES = []


def add_tree(kind, x, y, z, scale=None):
    f, (a, b) = KIT[kind]
    TREES.append(dict(kind=kind, file=f, x=float(x), y=float(y), z=float(z), scale=float(scale or trng.uniform(a, b)), yaw=float(trng.uniform(0, 360))))


# along the rims
for s in (-1, 1):
    for z in np.arange(G.Z_START - 30, G.Z_END + 10, -7.5):
        if abs(z - G.ZB) < 12:
            continue
        rd, T = rim_cached(z, s)
        x = float(G.centre_x(z)) + s * (rd + trng.uniform(4.0, 9.0))
        h = terrain_height(x, z)
        if h is None:
            continue
        kind = str(trng.choice(["pine_tall", "pine_tall", "pine_squat", "olive", "olive", "cypress"]))
        add_tree(kind, x, h - 0.1, z + trng.uniform(-1.5, 1.5))
# cypresses flanking the aqueduct's ends
for s in (-1, 1):
    for dzz in (8.6, -8.6):
        z = G.ZB + dzz
        rd, T = rim_cached(z, s)
        x = G.XB + s * (rd + 7.5); h = terrain_height(x, z)
        if h is not None:
            add_tree("cypress", x, h - 0.1, z, 0.95)
# (no bushes on the cliff faces or along the edges: Shannon, Sep 30 - they read as pompoms)
# over the hills: denser on the front ridge you see from the map, sparser behind
tries = 0
while tries < 6000 and len(TREES) < 330:
    tries += 1
    x = trng.uniform(G.X_MIN + 10, G.X_MAX - 10); z = trng.uniform(G.Z_FAR + 30, -230)
    dz = float(G.wall_z(x)) - z
    if dz < 30:
        continue
    keep = 0.55 if dz < 220 else 0.18
    if trng.random() > keep:
        continue
    inside, s, d, rd = corridor(x, z)
    if G.Z_END - 30 <= z <= G.Z_START and d < rd + 6:
        continue
    if z < float(G.crest_z(x)) + 6.0:
        continue                                          # the plain below the falls is Italy's to plant, later
    h = terrain_height(x, z)
    if h is None:
        continue
    kind = str(trng.choice(["pine_tall", "pine_tall", "pine_tall", "pine_squat", "olive", "cypress"]))
    add_tree(kind, x, h - 0.1, z)

# ================================================================ writing ================
def bbox_centre(m):
    a = np.array(m.v)
    return (a.min(0) + a.max(0)) / 2, a.max(0) - a.min(0)


def write_obj(path, meshes, mtlname, roblox):
    lines = ["# gen_gorge_real.py", "mtllib " + mtlname]
    vo = 0
    centres = {}
    for m in meshes:
        if not m.f:
            continue
        c, size = bbox_centre(m)
        centres[m.name] = dict(centre=[round(float(v), 4) for v in c], size=[round(float(v), 4) for v in size], tris=len(m.f))
        lines += ["o " + m.name, "g " + m.name, "usemtl " + m.mat, "s 1" if m.smooth else "s off"]
        for p in m.v:
            if roblox:
                lines.append("v %.4f %.4f %.4f" % (-(p[0] - c[0]), p[1] - c[1], -(p[2] - c[2])))
            else:
                lines.append("v %.4f %.4f %.4f" % p)
        lines += ["vt %.5f %.5f" % t for t in m.vt]
        for n in m.vn:
            lines.append(("vn %.4f %.4f %.4f" % (-n[0], n[1], -n[2])) if roblox else ("vn %.4f %.4f %.4f" % n))
        lines += ["f %d/%d/%d %d/%d/%d %d/%d/%d" % (a + vo, a + vo, a + vo, b + vo, b + vo, b + vo, cc + vo, cc + vo, cc + vo) for a, b, cc in m.f]
        vo += len(m.v)
    with open(path, "w", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    return centres


MATS = {"Strata": ("tex", "strata.png"), "Masonry": ("tex", "masonry.png"), "AqArch": ("col", (198, 156, 100)),
        "AqLedge": ("col", (228, 198, 148)), "AqCap": ("col", (206, 186, 150)), "AqKnob": ("col", (192, 150, 98)),
        "Grass": ("col", (98, 142, 72)), "Water": ("col", (40, 128, 140)), "Sand": ("col", (226, 206, 160)),
        "Mud": ("col", (132, 108, 82)), "Wood": ("col", (122, 86, 56)), "BoatGreen": ("col", (86, 96, 60)),
        "StrataLow": ("tex", "strata_low.png"), "Falls": ("col", (216, 236, 246)), "Foam": ("col", (240, 246, 248)),
        "Mist": ("col", (236, 242, 246)), "Plain": ("col", (150, 158, 88)), "Bed": ("col", (150, 140, 110)), "Slope": ("col", (206, 178, 128))}


def write_mtl(path, names):
    ml = []
    for k in names:
        kind, val = MATS[k]
        ml.append("newmtl " + k)
        ml += ["Kd 1 1 1", "map_Kd " + val] if kind == "tex" else ["Kd %.4f %.4f %.4f" % tuple(c / 255 for c in val)]
    with open(path, "w", newline="\n") as fh:
        fh.write("\n".join(ml) + "\n")


strata_texture(os.path.join(HERE, "strata.png"))
strata_texture(os.path.join(HERE, "strata_low.png"), G.Y_FOOT, Y0, G.LOWER, G.layers_low, G.SEA_Y + 0.6, False)
shutil.copy(os.path.join(os.path.dirname(HERE), "gorge", "masonry.png"), os.path.join(HERE, "masonry.png"))
rock_c = write_obj(os.path.join(HERE, "rock_roblox.obj"), ROCK, "rock_roblox.mtl", roblox=True)
write_mtl(os.path.join(HERE, "rock_roblox.mtl"), ["Strata"])
cliff_c = write_obj(os.path.join(HERE, "cliff_roblox.obj"), CLIFF, "cliff_roblox.mtl", roblox=True)
write_mtl(os.path.join(HERE, "cliff_roblox.mtl"), ["Strata", "StrataLow"])
aq_c = write_obj(os.path.join(HERE, "aqueduct_roblox.obj"), AQ, "aqueduct_roblox.mtl", roblox=True)
write_mtl(os.path.join(HERE, "aqueduct_roblox.mtl"), ["Masonry", "AqArch", "AqLedge", "AqCap", "AqKnob"])
prev = ROCK + CLIFF + AQ + TERR + [sand, mud, water, ground, jetty, boat] + FALLS_PREV
write_obj(os.path.join(HERE, "preview_world.obj"), prev, "preview_world.mtl", roblox=False)
write_mtl(os.path.join(HERE, "preview_world.mtl"), list(MATS.keys()))
data = dict(rock=rock_c, aqueduct=aq_c, trees=TREES, root=ROOT, cliff=cliff_c,
            colours={"Foliage": (72, 120, 74), "Trunk": (104, 78, 56), "Olive": (152, 170, 132), "OTrunk": (108, 88, 66),
                     "Boxwood": (72, 116, 62), "Cypress": (54, 88, 58), "Leaf": (84, 132, 76)},
            shape=dict(z_start=G.Z_START, z_end=G.Z_END, zc=ZC, zb=G.ZB, xb=G.XB, water_y=G.WATER_Y, sea_y=G.SEA_Y, plain_y=G.PLAIN_Y,
                       fall_h=G.FALL_H, corners=[XCW, XCE], arm_l=G.ARM_L, cove_a=G.COVE_A, cove_l=G.COVE_L))
with open(os.path.join(HERE, "gorge_data.json"), "w") as fh:
    json.dump(data, fh)
print("rock chunks", len(ROCK), "tris", sum(len(m.f) for m in ROCK), "max chunk", max(len(m.f) for m in ROCK))
print("cliff pieces", len(CLIFF), "tris", sum(len(m.f) for m in CLIFF), "max piece", max(len(m.f) for m in CLIFF))
print("aqueduct tris", {m.name: len(m.f) for m in AQ})
print("terrain tris", {m.name: len(m.f) for m in TERR}, "| trees", len(TREES))
