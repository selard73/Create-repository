"""gorge_shape.py - the south gorge's shape in GAME coordinates (x, y up, z; downstream = -z), shared by the mesh
generator, the terrain writer's data and the preview renders. Approved by Shannon on Sep 30 2026 (preview v1 + the
build plan: the gorge follows the river's own bends from the village wall; the aqueduct at the west bend; hills along
the whole south edge).

The river's centre and width come from the read-only probe tools/gorge_probe2_out.txt (water edges every 4 studs from
z -196 to -640). Everything else is defined here: the basin at the aqueduct, the cliff foot, the rim height, the rock's
strata (the Sandstone Climb's recipe and colours, beds shaped as flat slabs with a shadow notch), and the hills.
"""
import math, os, re
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PROBE = os.path.join(os.path.dirname(os.path.dirname(HERE)), "tools", "gorge_probe2_out.txt")
WATER_Y = -0.9
Z_START, Z_END = -228.0, -548.0          # the rock walls: from just past the 10-stud untouched zone by the walls (the village
                                         # wall is at z -205, the forest's at -215) to where the hills close over
ZB, XB = -384.0, None                    # the aqueduct's line (x set from the river below)
BASIN_R = 24.0                           # how far along the river the basin reaches (as in the preview)
BASIN_FOOT = 30.0                        # the cliff foot at the aqueduct, from the centre line (preview: 30)
RR = 1.4                                 # the rim's rounded lip
TOP_STRIP = 10.0                         # the rock's top strip runs this far back from the lip, dipping under the grass


def smoothstep(e0, e1, x):
    t = np.clip((np.asarray(x, dtype=float) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# ---------------------------------------------------------------- the river, from the probe ----
def _read_probe():
    zs, x0s, x1s = [], [], []
    for line in open(PROBE, encoding="utf-8-sig"):
        if not line.startswith("CH "):
            continue
        for tok in line.split()[1:]:
            z, a, b, _ = tok.split(":")
            if a == "-":
                continue
            zs.append(float(z)); x0s.append(float(a)); x1s.append(float(b))
    zs, x0s, x1s = np.array(zs), np.array(x0s), np.array(x1s)
    keep = zs <= -204                                  # north of that the lagoon joins the river
    return zs[keep], x0s[keep], x1s[keep]


_PZ, _PX0, _PX1 = _read_probe()
_PC = (_PX0 + _PX1) / 2.0
_PH = (_PX1 - _PX0) / 2.0 + 0.5
# smooth a little (3-tap) so the walls don't wobble with the probe's 1-stud steps
_PC = np.convolve(np.pad(_PC, 1, mode="edge"), [0.25, 0.5, 0.25], mode="valid")
_PH = np.convolve(np.pad(_PH, 1, mode="edge"), [0.25, 0.5, 0.25], mode="valid")
XB = float(np.interp(-ZB, -_PZ, _PC))


def close_f(z):
    """(kept for the face functions) the walls no longer pinch: the headwall closes the slot"""
    return np.zeros_like(np.asarray(z, dtype=float))


def basin(z):
    return np.exp(-((np.asarray(z, dtype=float) - ZB) / BASIN_R) ** 4)


def centre_x(z):
    """the river's centre line; straight (x = XB) through the basin so the aqueduct crosses square"""
    z = np.asarray(z, dtype=float)
    c = np.interp(-z, -_PZ, _PC)
    w = np.exp(-((z - ZB) / 16.0) ** 4)
    return c * (1 - w) + XB * w


def half_width(z):
    z = np.asarray(z, dtype=float)
    h = np.interp(-z, -_PZ, _PH)
    w = np.exp(-((z - ZB) / 16.0) ** 4)
    return h * (1 - w) + 12.2 * w


# ---------------------------------------------------------------- the walls ----
def foot(z, s):
    """centre line -> the foot of the cliff (before relief), s = -1 west, +1 east. Through the basin the foot stands
    back BASIN_FOOT; at the far end the two walls close in to a slot, so the river disappears into the rock."""
    z = np.asarray(z, dtype=float)
    margin = 0.9 if s < 0 else 2.7                     # the west mostly drops into the water; the east keeps a thin beach
    wob = 0.9 * np.sin(z / 17.0 + 1.7 * s)
    b = basin(z)
    f = (half_width(z) + margin + wob) * (1 - b) + BASIN_FOOT * b
    return f                                              # (the walls run at full width to the headwall; no pinch)


def top_at(z, s):
    """the rim height: rising out of the village with the hills (low at the mouth), about 41 through the gorge, exactly
    40.6 at the aqueduct, a little taller past the fade point"""
    z = np.asarray(z, dtype=float)
    t = 41.0 + 3.2 * np.sin(z / 29.0 + 1.3 * s) + 1.3 * np.sin(z / 11.0 + 0.7 * s)
    t = t + 4.0 * smoothstep(-440, -520, z)
    w = np.exp(-((z - ZB) / 14.0) ** 2)
    t = t * (1 - w) + 40.6 * w
    rise = np.maximum(3.0, ridge_profile(-205.0 - z) + 1.5)    # the hills beside the mouth (village wall at z -205)
    t = np.minimum(t, rise)
    # at the mouth the old edge mounds stand 7-9 high (measured Sep 30): the rock starts as tall as they are
    floor = 9.5 * (1 - smoothstep(-238.0, -246.0, z))
    return np.maximum(t, floor)


def lean(y):
    return 0.22 * np.clip(np.asarray(y, dtype=float), 0, None)


def undercut(y):
    return 1.3 * np.exp(-((np.asarray(y, dtype=float) - 2.2) / 2.0) ** 2)


# ---------------------------------------------------------------- strata (the Sandstone Climb's recipe) ----
rng = np.random.default_rng(3009)
YV0, YV1 = -8.0, 52.0
CREAM, GOLD, SAND, HONEY, ORANGE, WHITE = (238, 224, 188), (228, 204, 150), (220, 190, 132), (212, 172, 112), (214, 152, 96), (242, 232, 205)
TOPCREAM = (222, 194, 142)
layers = []
_y = YV0
while _y < YV1 + 4:
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
    layers.append(dict(y0=_y, y1=_y + t, p0=p0, fr=rng.uniform(5, 14), ph=rng.uniform(0, 2 * math.pi), amp=rng.uniform(0.2, 0.7),
                       col=col, kind=kind, g=rng.uniform(0.35, 0.95) + (0.35 if kind == "thick" else 0.0)))
    _y += t
L_Y0 = np.array([l["y0"] for l in layers]); L_T = np.array([l["y1"] - l["y0"] for l in layers])
L_P0 = np.array([l["p0"] for l in layers]); L_FR = np.array([l["fr"] for l in layers])
L_PH = np.array([l["ph"] for l in layers]); L_AMP = np.array([l["amp"] for l in layers])
L_G = np.array([l["g"] for l in layers]); NL = len(layers)
NG = rng.uniform(-1, 1, (64, 64))
UPPER = (L_Y0, L_T, L_P0, L_FR, L_PH, L_AMP, L_G, NL)

# the same recipe carried on DOWN from YV0 for the cliff under the falls (its own random stream, so the walls' beds,
# which are already in the place, do not change)
_rng2 = np.random.default_rng(3010)
layers_low = []
_y = -64.0
while _y < YV0 - 1e-9:
    r = _rng2.random()
    if r < 0.13:
        t, kind = _rng2.uniform(0.35, 0.6), "seam"
    elif r < 0.31:
        t, kind = _rng2.uniform(2.0, 3.4), "thick"
    else:
        t, kind = _rng2.uniform(0.8, 1.8), "bed"
    t = min(t, YV0 - _y)
    p0 = {"seam": _rng2.uniform(-1.3, -0.7), "thick": _rng2.uniform(0.5, 1.6), "bed": _rng2.uniform(-0.4, 1.1)}[kind]
    c = _rng2.random()
    if kind == "seam":
        col = ORANGE if c < 0.55 else HONEY
    else:
        col = CREAM if c < 0.17 else GOLD if c < 0.53 else SAND if c < 0.82 else HONEY if c < 0.96 else WHITE
    layers_low.append(dict(y0=_y, y1=_y + t, p0=p0, fr=_rng2.uniform(5, 14), ph=_rng2.uniform(0, 2 * math.pi), amp=_rng2.uniform(0.2, 0.7),
                           col=col, kind=kind, g=_rng2.uniform(0.35, 0.95) + (0.35 if kind == "thick" else 0.0)))
    _y += t
LOWER = (np.array([l["y0"] for l in layers_low]), np.array([l["y1"] - l["y0"] for l in layers_low]), np.array([l["p0"] for l in layers_low]),
         np.array([l["fr"] for l in layers_low]), np.array([l["ph"] for l in layers_low]), np.array([l["amp"] for l in layers_low]),
         np.array([l["g"] for l in layers_low]), len(layers_low))


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


def _side_features(s):
    r = np.random.default_rng(71 if s < 0 else 72)
    pockets = []
    while len(pockets) < 40:
        pz, py = r.uniform(Z_END + 6, Z_START - 30), r.uniform(5, 36)
        if abs(pz - ZB) < 14:
            continue
        pockets.append((pz, py, r.uniform(1.2, 2.6), r.uniform(0.5, 1.2)))
    joints = []
    jz = Z_END - 10 + r.uniform(3, 10)
    while jz < Z_START + 10:
        joints.append((jz, r.uniform(0.9, 1.9)))
        jz += r.uniform(9, 20)
    off = r.uniform(-1.5, 1.5, len(joints) + 1)
    cracks = [(float(r.uniform(-300, -260)), 0.2, 0.9), (float(r.uniform(-500, -440)), 0.15, 0.85), (float(r.uniform(-545, -520)), 0.2, 0.8)]
    return dict(pockets=pockets, joints=joints, off=off, cracks=cracks)


def _arm_features(s):
    """pockets, joints and cracks for a cliff arm (s = -2 west, +2 east); z here is the along-face coordinate, which
    runs on from ZC (-547.5) for another ~150 studs"""
    r = np.random.default_rng(81 if s < 0 else 82)
    z_hi = Z_END - 4.0; z_lo = Z_END - 160.0
    pockets = [(r.uniform(z_lo, z_hi), r.uniform(-50, 34), r.uniform(1.2, 2.8), r.uniform(0.5, 1.2)) for _ in range(34)]
    joints = []
    jz = z_lo + r.uniform(3, 10)
    while jz < z_hi:
        joints.append((jz, r.uniform(0.9, 1.9)))
        jz += r.uniform(9, 20)
    off = r.uniform(-1.5, 1.5, len(joints) + 1)
    cracks = [(float(r.uniform(z_lo + 20, z_hi - 20)), -1.2, 0.9), (float(r.uniform(z_lo + 20, z_hi - 20)), -1.0, 0.5)]
    return dict(pockets=pockets, joints=joints, off=off, cracks=cracks)


FEAT = {-1: _side_features(-1), 1: _side_features(1), -2: _arm_features(-2), 2: _arm_features(2)}
# ledges where a bush has taken hold (s, z, y)
SHELVES = []                             # (Shannon, Sep 30: no bushes on the cliff faces, so no ledges for them)
SHELF_OUT = 2.4


def _blocks(z, s):
    f = FEAT[s]; z = np.asarray(z, dtype=float)
    off = np.full(z.shape, f["off"][0])
    for k, (jzk, _) in enumerate(f["joints"]):
        off = off + (f["off"][k + 1] - f["off"][k]) * smoothstep(jzk - 1.2, jzk + 1.2, z)
    groove = np.zeros(z.shape)
    for jzk, dep in f["joints"]:
        groove = groove + dep * np.exp(-((z - jzk) / 0.9) ** 2)
    return off - groove


def _beds(y, zz, A):
    """the beds' relief from one set of layers (flat slabs with a shadow notch at the base of each)"""
    Y0a, Ta, P0a, FRa, PHa, AMPa, Ga, n = A
    i = np.clip(np.searchsorted(Y0a, y, side="right") - 1, 0, n - 1)
    u = np.clip((y - Y0a[i]) / Ta[i], 0, 1)
    p = P0a[i] + AMPa[i] * np.sin(zz / FRa[i] + PHa[i])
    ib = np.clip(i - 1, 0, n - 1)
    pb = P0a[ib] + AMPa[ib] * np.sin(zz / FRa[ib] + PHa[ib])
    zlow = np.minimum(p, pb) - Ga[i]
    return 0.8 * (p - (p - zlow) * (1 - smoothstep(0.0, 0.28, u)) - 0.35 * smoothstep(0.82, 1.0, u))


def relief(z, y, T, s):
    """how far the stone stands out (toward the river) from the face line at (z, y), for a column whose rim is T.
    s = -1 west wall, +1 east wall; -2 / +2 the cliff arms beyond the corners (their own pockets and joints; z is
    then the along-face coordinate carried on past ZC)."""
    z = np.asarray(z, dtype=float); y = np.asarray(y, dtype=float)
    zz = z + 37.0 * s
    rl = np.where(y >= YV0, _beds(y, zz, UPPER), _beds(y, zz, LOWER))
    rl = rl + 0.16 * fbm(zz, y) + _blocks(z, s) * (1 - smoothstep(T - 2.0, T - 0.5, y) * 0.6)
    rl = rl + 0.45 * smoothstep(T - 2.6, T - 1.2, y) - 0.6 * np.exp(-((y - (T - 3.2)) / 0.55) ** 2)
    for pz, py, pr, pd in FEAT[s]["pockets"]:
        rl = rl - pd * np.exp(-(((z - pz) ** 2) + ((y - py) * 1.3) ** 2) / (pr * pr))
    for cz, f0, f1 in FEAT[s]["cracks"]:
        band = smoothstep(f0 * T, f0 * T + 3, y) * (1 - smoothstep(f1 * T - 2, f1 * T, y))
        rl = rl - 2.4 * np.exp(-((z - cz) / 1.0) ** 2) * band
    for ss, sz, sy in SHELVES:
        if ss == s:
            rl = rl + SHELF_OUT * np.exp(-((z - sz) / 3.2) ** 4) * smoothstep(sy - 2.6, sy - 0.4, y) * (1 - smoothstep(sy, sy + 0.4, y))
    # calmer where the aqueduct is built into the rock, and at the low mouth by the village
    rl = rl * (1 - 0.5 * np.exp(-((z - ZB) / 9.0) ** 2))
    return rl


def face_d(z, y, s):
    """distance from the centre line to the rock face at (z, y)"""
    T = float(top_at(z, s))
    y = np.asarray(y, dtype=float)
    c = float(close_f(z))
    return foot(z, s) + (lean(y) + undercut(y)) * (1 - c) - relief(np.full(y.shape, z), y, T, s) * (1 - 0.8 * c)


def rim_d(z, s):
    """distance from the centre line to the top of the lip (where the top strip starts)"""
    T = float(top_at(z, s)); yf = T - RR
    return float(face_d(z, np.array([yf]), s)[0]) + RR


# ---------------------------------------------------------------- the hills (whole south edge) ----
def wall_z(x):
    """the play area's south wall line (from gorge_probe2): forest -215, village -205, domaine -250, the Sandstone
    Climb's back wall -273. Smoothed where it steps, always on or SOUTH of the real wall so the hills never reach
    inside the play area; west of the forest and east of the domaine the line carries on."""
    x = np.asarray(x, dtype=float)
    z = -215.0 + 10.0 * smoothstep(135.0, 185.0, x)          # forest -> village (after the step, going north)
    z = z - 45.0 * smoothstep(302.0, 352.0, x)               # village -> domaine (before the step, going south)
    z = z - 23.0 * smoothstep(416.0, 466.0, x)               # the Sandstone Climb's back wall
    z = z + 23.0 * smoothstep(568.0, 618.0, x)
    return z


def ridge_profile(dz):
    """height of the hills by distance south of the wall line"""
    dz = np.asarray(dz, dtype=float)
    h = 42.0 * smoothstep(14.0, 84.0, dz)
    h = h + 7.0 * np.sin((dz - 84.0) / 70.0) * smoothstep(84.0, 150.0, dz)
    h = h + 40.0 * smoothstep(300.0, 780.0, dz)
    return h


def hill_noise(x, z):
    x = np.asarray(x, dtype=float); z = np.asarray(z, dtype=float)
    return (6.0 * np.sin(x / 97.0 + 1.3) * np.cos(z / 83.0 - 0.7) + 3.5 * np.sin(x / 41.0 + z / 57.0 + 2.1)
            + 2.0 * np.sin(x / 23.0 - z / 31.0 + 0.4) + 0.9 * np.sin(x / 9.7 + z / 13.3 + 1.1))


X_MIN, X_MAX, Z_FAR = -240.0, 1000.0, -1020.0


# ---------------------------------------------------------------- the falls (the gorge's end) ----
# Shannon, Sep 30 evening: not a cave - the gorge OPENS onto a waterfall. The walls stop at sharp corners on the
# ridge's south face (their last column, ZC) and the river pours over a rock sill into a plunge pool at the head of
# Porto Nocciola's harbour, FALL_H studs below: the land beyond the ridge is the Italian coastal plain, PLAIN_Y, with
# the sea at SEA_Y (the Baseplate is cut away south of the ridge). From each corner the cliff face sweeps south in a
# curve (a cove round the pool) for ARM_L studs of mesh - vertical at the corners and under the lip, leaning back a
# little further out - and beyond the arms the ridge's south side is a terrain slope down to the plain.
ZC = Z_START - 1.5 * math.floor((Z_START - Z_END) / 1.5 + 1e-9)     # the walls' last column: the corners (-547.5)
SEA_Y = WATER_Y - 52.0                   # the harbour and the sea
PLAIN_Y = -48.0                          # the coastal plain (Italy's ground; quays a little lower, later)
FALL_H = WATER_Y - SEA_Y                 # 52
Y_FOOT = -64.0                           # the cliff's lowest row (the plunge pool's bed)
SILL_R, SILL_RUN = 1.8, 12.0             # the lip's rounded sill and how far back it slopes down to the river bed
ARM_L = 130.0                            # each cliff arm (mesh) runs this far from its corner, measured along x
COVE_A, COVE_L = 40.0, 110.0             # the cliff line sweeps this far south over that distance (the cove)
FALL_W = 30.0                            # the falling water's width (the river is ~32 wide between the corners)
COAST = 210.0                            # south of the corners' line the cove opens into the sea about here


def cove(a):
    """how far south of ZC the cliff line has swept, a studs (along x) out from a corner: the sweep round the pool
    plus buttresses and gullies (a 4-stud scallop every ~40 studs) so the faces do not read as flat walls; the scallops
    die out at the corners (the walls meet the cliff square) and before the arms' ends"""
    a = np.asarray(a, dtype=float)
    scallop = 4.0 * np.sin(a / 6.4 + 1.1) * smoothstep(6.0, 30.0, a) * (1 - smoothstep(ARM_L - 40.0, ARM_L - 10.0, a))
    return COVE_A * smoothstep(0.0, COVE_L, a) + scallop


def corner_x(s):
    """the corners' base x (the walls' feet at their last column, before lean and relief)"""
    return float(centre_x(ZC)) + s * float(foot(ZC, s))


def crest_z(x):
    """the cliff line's z at x (the base line: before lean and relief); between the corners it is the lip"""
    x = np.asarray(x, dtype=float)
    a = np.maximum(0.0, np.maximum(corner_x(-1) - x, x - corner_x(1)))
    return ZC - cove(a)


def arm_lean(a, y):
    """the arms' faces are vertical at the corners (to meet the walls), lean back a little further out, and over the
    last 30 studs lie back to a 60-degree slope so the terrain slope beyond the arm carries on at the same angle"""
    y = np.asarray(y, dtype=float)
    end = 0.44 * smoothstep(ARM_L - 30.0, ARM_L, a)          # the end taper lies the WHOLE face back, from the plain up
    return 0.16 * smoothstep(0.0, 45.0, a) * np.clip(y, 0, None) + end * np.clip(y - PLAIN_Y, 0, None)


def cliff_T(a, s):
    """the crest height along an arm: the wall's own rim height at the corner, waves and a slow rise beyond"""
    a = np.asarray(a, dtype=float)
    return float(top_at(ZC, s)) + 2.6 * np.sin(a / 23.0) + 1.1 * np.sin(a / 9.5) + 2.0 * smoothstep(20.0, 110.0, a)


def cove_axis(zd):
    """x of the cove's centre line, zd studs south of the corners' line"""
    zd = np.asarray(zd, dtype=float)
    return float(centre_x(ZC)) + 14.0 * np.sin(zd / 60.0) * smoothstep(20.0, 120.0, zd)


def cove_hw(zd):
    return 24.0 + 0.13 * np.asarray(zd, dtype=float)


def south_height(x, z):
    """the ground south of the cliff line: the coastal plain, the cove (the harbour's head) with the plunge pool under
    the falls, the open sea beyond the coast. Water lies wherever this is below SEA_Y."""
    x = np.asarray(x, dtype=float); z = np.asarray(z, dtype=float)
    zd = ZC - z
    plain = PLAIN_Y + 1.2 * np.sin(x / 31.0) * np.cos(z / 27.0) + 0.6 * np.sin(x / 11.0 + z / 13.0)
    ax = cove_axis(zd); hw = cove_hw(zd)
    r = np.abs(x - ax) / hw                                # 0 at the cove's middle .. 1 at its shore
    # the plunge pool: deepest where the water lands, but shallowing to the cliff's foot so the rock's lowest row (Y_FOOT)
    # stays buried under the bed right at the face
    pool = 9.0 * np.exp(-(((x - float(centre_x(ZC))) / 22.0) ** 2 + ((zd - 12.0) / 18.0) ** 2)) * smoothstep(0.0, 10.0, zd)
    bed = SEA_Y - 3.0 - 3.0 * (1 - np.minimum(r, 1.0) ** 2) - pool
    beach = smoothstep(30.0, 60.0, zd) * (1 - smoothstep(90.0, 120.0, zd)) * (x > ax)     # a gentle sandy shore on the east side (the parachute target)
    shore = smoothstep(0.85, 1.25 + 0.5 * beach, r)
    h = bed * (1 - shore) + plain * shore
    coast = COAST + 45.0 * np.sin(x / 90.0 + 0.6) + 18.0 * np.sin(x / 31.0 - 1.0)       # the coastline wanders
    sea = smoothstep(coast - 30.0, coast + 30.0, zd)
    return h * (1 - sea) + (SEA_Y - 9.0) * sea
