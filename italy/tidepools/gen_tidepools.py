"""gen_tidepools.py - natural tide pools for Porto Nocciola's sandy cove (Oct 4 2026), replacing Codex's ring-of-boulders pools.

A low limestone rock shelf along the cove's sea edge (heightfield mesh, game coordinates x / y up / z), with six irregular
pool hollows carved into it, plus flat water surfaces sitting in the hollows. The texture is baked from the heightfield:
dry cream limestone with pits, a darker wet band near the sea, darker pool beds and a green algae line at each pool's
water line.

Writes (this folder):
  tidepools_roblox.obj/.mtl  TidePoolShelf + TidePoolWater, each centred on its box and turned 180 deg about y
                             (Studio's Import 3D turns it back, as for the gorge pieces)
  tidepools_preview.obj/.mtl the same in world coordinates + context (sea, the sandy cove slab) for render_tidepools.py
  tidepool_rock.png          the baked texture (one image over the whole shelf)
  tidepools_data.json        piece centres/sizes (for the Studio placement script), pool list, water levels
"""
import json, math, os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SEA = -52.9
X0, X1, Z0, Z1 = 280.0, 314.0, -812.0, -756.0
STEP = 0.5
TEX = 1024

# shelf outline (game x, z), same footprint as the terrain attempts
POLY = [(299, -762), (295, -764), (290, -768), (287, -774), (285.5, -781), (286, -788), (288.5, -794), (292.5, -799),
        (297, -804), (302, -807.5), (307.5, -807), (311, -804), (311, -796), (304, -794), (300, -793), (299.5, -780)]
# pools: blobs (x, z, radius along x, radius along z, turn deg), depth below the local rim
POOLS = [
    dict(blobs=[(294.0, -770.0, 2.3, 1.7, 20), (296.3, -772.2, 1.8, 1.4, -30)], depth=1.0),          # kidney
    dict(blobs=[(290.6, -779.4, 1.3, 2.4, 10), (291.5, -782.8, 1.2, 2.2, -12), (290.5, -786.0, 1.1, 1.8, 15)], depth=1.2),  # long crack
    dict(blobs=[(296.8, -786.5, 1.7, 1.5, 0)], depth=0.8),                                             # round puddle
    dict(blobs=[(293.0, -793.6, 2.4, 1.9, 35), (295.6, -795.8, 1.8, 1.6, -20)], depth=1.3),          # bigger pool
    dict(blobs=[(302.4, -800.4, 2.0, 1.5, 25), (304.7, -802.0, 1.6, 1.3, 0)], depth=1.0),            # by the stairs
    dict(blobs=[(298.0, -777.2, 1.1, 1.0, 0)], depth=0.6),                                             # little one
]


def noise2(x, z, seed):
    """smooth value noise in [-1, 1] (vectorised)"""
    rng = np.random.RandomState(seed)
    g = rng.uniform(-1, 1, (256, 256))
    xi, zi = np.floor(x).astype(int), np.floor(z).astype(int)
    fx, fz = x - xi, z - zi
    u, v = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    a = g[xi % 256, zi % 256]; b = g[(xi + 1) % 256, zi % 256]
    c = g[xi % 256, (zi + 1) % 256]; d = g[(xi + 1) % 256, (zi + 1) % 256]
    return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v


def fbm(x, z, seed, octaves=4):
    s, amp, f = 0, 1.0, 1.0
    for o in range(octaves):
        s = s + amp * noise2(x * f, z * f, seed + o)
        amp *= 0.5; f *= 2.0
    return s / 1.875


def poly_sdf(x, z):
    """signed distance to POLY (positive inside), vectorised"""
    P = np.array(POLY)
    d = np.full(x.shape, 1e9)
    inside = np.zeros(x.shape, bool)
    n = len(P)
    for i in range(n):
        ax, az = P[i]; bx, bz = P[(i + 1) % n]
        ex, ez = bx - ax, bz - az
        t = np.clip(((x - ax) * ex + (z - az) * ez) / (ex * ex + ez * ez), 0, 1)
        d = np.minimum(d, np.hypot(x - ax - t * ex, z - az - t * ez))
        cross = ((az > z) != (bz > z)) & (x < (bx - ax) * (z - az) / (bz - az + 1e-12) + ax)
        inside ^= cross
    return np.where(inside, d, -d)


def top_profile(x, z):
    """shelf top before pools: ~ -51.3 by the cove (east), ~ -52.15 at the sea edge, gentle bumps"""
    t = np.clip((299.5 - x) / 13.0, 0, 1)
    south = np.clip((-794 - z) / 14.0, 0, 1)
    t = np.where(z < -794, np.clip((311 - x) / 16, 0, 1) * 0.6 + south * 0.4, t)
    base = -51.3 - 0.85 * t + fbm(x * 0.22, z * 0.22, 11) * 0.30 + fbm(x * 0.7, z * 0.7, 17, 3) * 0.14 + fbm(x * 1.6, z * 1.6, 23, 3) * 0.05
    ledge = np.round(fbm(x * 0.12, z * 0.12, 41, 2) * 3) * 0.12           # a few shallow steps in the rock
    return base + ledge


def pool_field(x, z, pool, warp=True):
    """>0 inside the pool (1 at its deepest), with a noise-warped edge"""
    # metaballs: the blobs melt into ONE irregular pool (a max of ellipses read as separate eggs side by side)
    f = np.zeros(x.shape)
    wx = x + (fbm(x * 0.55, z * 0.55, 31, 3) * 0.6 if warp else 0)
    wz = z + (fbm(x * 0.55, z * 0.55, 37, 3) * 0.6 if warp else 0)
    for (cx, cz, rx, rz, deg) in pool["blobs"]:
        a = math.radians(deg)
        dx, dz = wx - cx, wz - cz
        u = (dx * math.cos(a) + dz * math.sin(a)) / rx
        v = (-dx * math.sin(a) + dz * math.cos(a)) / rz
        f = f + np.exp(-(u * u + v * v) * 0.7)
    T0 = 0.5                                   # exp(-0.7) ~ 0.5: a lone blob's edge sits at its radius
    return (f - T0) / (1 - T0)


def heights(x, z):
    sd = poly_sdf(x, z) + fbm(x * 0.28, z * 0.28, 5) * 1.3       # irregular outline
    h = top_profile(x, z)
    h = h - np.where(sd < 1.4, (1.4 - np.clip(sd, -9, 1.4)) ** 2 * 0.28, 0)   # rounded lip, then a steep drop into the sea
    h = np.where(sd < 0, top_profile(x, z) - 0.55 - (-sd) * 1.9, h)
    pf_all = np.full(x.shape, -9.0)
    water = []
    for i, p in enumerate(POOLS):
        pf = pool_field(x, z, p)
        cx = np.mean([b[0] for b in p["blobs"]]); cz = np.mean([b[1] for b in p["blobs"]])
        rim = float(top_profile(np.array([cx]), np.array([cz]))[0])
        wl = rim - 0.22
        bowl = np.clip(pf, 0, 1)
        prof = np.sqrt(bowl) * p["depth"] + np.clip(pf + 0.25, 0, 0.25) * 0.4    # soft shelf into a bowl
        h = np.where(pf > -0.25, np.maximum(np.minimum(h, rim + 0.05 - prof), np.minimum(h, SEA + 0.18)), h)
        # a rock lip round each pool, a little above its water, so the water can never run out over lower rock nearby
        lip = np.sqrt(np.clip(1 - np.abs(pf + 0.17) / 0.3, 0, 1))         # a firm ring hugging the pool's edge
        h = np.where(lip > 0, np.maximum(h, h * (1 - lip) + (wl + 0.12 + fbm(x * 1.3, z * 1.3, 91 + i, 2) * 0.04) * lip), h)
        water.append(dict(level=round(wl, 3), rim=round(rim, 3), centre=[round(float(cx), 2), round(float(cz), 2)]))
        pf_all = np.maximum(pf_all, pf)
    return np.clip(h, -57.5, None), sd, pf_all, water


def build():
    xs = np.arange(X0, X1 + 1e-6, STEP); zs = np.arange(Z0, Z1 + 1e-6, STEP)
    X, Z = np.meshgrid(xs, zs, indexing="ij")
    H, SD, PF, water = heights(X, Z)
    nx, nz = X.shape
    keep = H > -57.2                                              # drop the flat sea-bed skirt far from the shelf
    # vertices + faces of the shelf (only cells with at least one kept corner)
    vid = -np.ones(X.shape, int)
    verts, uvs = [], []
    for i in range(nx):
        for j in range(nz):
            ok = keep[max(i - 1, 0):i + 2, max(j - 1, 0):j + 2].any()
            if ok:
                vid[i, j] = len(verts)
                verts.append((float(X[i, j]), float(H[i, j]), float(Z[i, j])))
                uvs.append(((X[i, j] - X0) / (X1 - X0), (Z[i, j] - Z0) / (Z1 - Z0)))
    faces = []
    for i in range(nx - 1):
        for j in range(nz - 1):
            a, b, c, d = vid[i, j], vid[i + 1, j], vid[i + 1, j + 1], vid[i, j + 1]
            if min(a, b, c, d) < 0 or not keep[i:i + 2, j:j + 2].any():
                continue
            # outward = +y in game coords; with x right and z toward the viewer the winding a,d,c / a,c,b faces up
            faces.append((a, d, c)); faces.append((a, c, b))
    # water: marching squares at each pool's level, so the edge follows the rock smoothly (whole cells read as stairs)
    wv, wf = [], []
    for k, p in enumerate(POOLS):
        pf = pool_field(X, Z, p)
        wl = water[k]["level"]
        S = np.minimum(wl - H, (pf + 0.08) * 0.6)                 # >0 = under this pool's water; the pool field caps it smoothly (a hard mask left steps)
        for i in range(nx - 1):
            for j in range(nz - 1):
                cs = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
                vals = [S[c] for c in cs]
                if max(vals) <= 0:
                    continue
                poly = []
                for q in range(4):
                    c0, c1 = cs[q], cs[(q + 1) % 4]
                    v0, v1 = vals[q], vals[(q + 1) % 4]
                    if v0 > 0:
                        poly.append((float(X[c0]), float(Z[c0])))
                    if (v0 > 0) != (v1 > 0):
                        t = v0 / (v0 - v1)
                        poly.append((float(X[c0] + (X[c1] - X[c0]) * t), float(Z[c0] + (Z[c1] - Z[c0]) * t)))
                if len(poly) < 3:
                    continue
                base = len(wv)
                for (px, pz) in poly:
                    wv.append((px, wl, pz))
                for q in range(1, len(poly) - 1):                 # fan; corner order runs x+ then z+, so (0, q+1, q) faces up
                    wf.append((base, base + q + 1, base + q))
    return dict(X=X, Z=Z, H=H, SD=SD, PF=PF, water=water, verts=verts, uvs=uvs, faces=faces, wv=wv, wf=wf)


def bake_texture(m, path):
    u = (np.arange(TEX) + 0.5) / TEX
    U, V = np.meshgrid(u, u, indexing="ij")                      # U along x, V along z (v=0 at Z0)
    x = X0 + U * (X1 - X0); z = Z0 + V * (Z1 - Z0)
    H, SD, PF, water = heights(x, z)
    big = fbm(x * 0.35, z * 0.35, 51)
    fine = fbm(x * 2.6, z * 2.6, 57, 3)
    pits = fbm(x * 9.0, z * 9.0, 63, 2)
    dry = np.stack([168 + big * 14, 156 + big * 13, 132 + big * 11], -1)      # Roblox lights it far brighter than Blender: start darker and warmer
    dry = dry + fine[..., None] * 9
    dry = np.where((pits > 0.42)[..., None], dry * 0.80, dry)               # small dark pits
    wet = np.array([122.0, 114.0, 96.0])
    wetness = np.clip((SEA + 0.75 - H) / 0.6, 0, 1)                         # darker near the sea
    col = dry * (1 - wetness[..., None]) + wet * wetness[..., None]
    # pools: darker beds, a green algae line at the water's edge, a few pink coralline patches
    for k, p in enumerate(POOLS):
        pf = pool_field(x, z, p)
        wl = water[k]["level"]
        damp = np.clip(1 - (H - wl) / 0.35, 0, 1) * (pf > -0.7) * np.clip(0.5 + fbm(x * 0.9, z * 0.9, 81 + k, 3), 0, 1)   # patchy splashed rock
        col = col * (1 - 0.15 * damp[..., None])
        bed = np.clip((wl - H) / 0.5, 0, 1) * (pf > -0.4)
        col = col * (1 - 0.35 * bed[..., None]) + np.array([118, 112, 92.0]) * 0.35 * bed[..., None]
        line = np.exp(-((H - wl) / 0.12) ** 2) * (pf > -0.6)
        algae = np.array([92.0, 128.0, 70.0]) + fine[..., None] * 10
        col = col * (1 - 0.75 * line[..., None]) + algae * 0.75 * line[..., None]
        pink = (fbm(x * 1.7, z * 1.7, 71 + k, 2) > 0.45) & (bed > 0.5)
        col = np.where(pink[..., None], col * 0.6 + np.array([196.0, 120, 128]) * 0.4, col)
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8).transpose(1, 0, 2)[::-1])   # rows = v (top = v 1)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    img.save(path)


def bbox_centre(v):
    a = np.array(v)
    lo, hi = a.min(0), a.max(0)
    return (lo + hi) / 2, hi - lo


def write_obj(path, pieces, mtl, roblox):
    L = ["# gen_tidepools.py", "mtllib " + mtl]
    vo = 0
    info = {}
    for name, mat, v, f, uv in pieces:
        c, s = bbox_centre(v)
        info[name] = dict(centre=[round(float(t), 4) for t in c], size=[round(float(t), 4) for t in s], tris=len(f))
        L += ["o " + name, "g " + name, "usemtl " + mat, "s 1"]
        for p in v:
            L.append("v %.4f %.4f %.4f" % ((-(p[0] - c[0]), p[1] - c[1], -(p[2] - c[2])) if roblox else p))
        for t in uv:
            L.append("vt %.5f %.5f" % t)
        for (a, b, cc) in f:
            if uv:
                L.append("f %d/%d %d/%d %d/%d" % (a + vo + 1, a + vo + 1, b + vo + 1, b + vo + 1, cc + vo + 1, cc + vo + 1))
            else:
                L.append("f %d %d %d" % (a + vo + 1, b + vo + 1, cc + vo + 1))
        vo += len(v)
    open(path, "w", newline="\n").write("\n".join(L) + "\n")
    return info


if __name__ == "__main__":
    m = build()
    bake_texture(m, os.path.join(HERE, "tidepool_rock.png"))
    wuv = []
    pieces = [("TidePoolShelf", "Rock", m["verts"], m["faces"], m["uvs"]), ("TidePoolWater", "PoolWater", m["wv"], m["wf"], wuv)]
    open(os.path.join(HERE, "tidepools_roblox.mtl"), "w").write("newmtl Rock\nKd 1 1 1\nmap_Kd tidepool_rock.png\nnewmtl PoolWater\nKd 0.36 0.70 0.72\n")
    info = write_obj(os.path.join(HERE, "tidepools_roblox.obj"), pieces, "tidepools_roblox.mtl", True)
    # preview: same pieces in world coords + the sea and the sandy cove slab for context
    sea_v = [(240.0, SEA, -840.0), (340.0, SEA, -840.0), (340.0, SEA, -740.0), (240.0, SEA, -740.0)]
    sea_f = [(0, 3, 2), (0, 2, 1)]
    def box(x0, x1, y0, y1, z0, z1):
        v = [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1), (x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)]
        f = [(4, 7, 6), (4, 6, 5), (0, 4, 5), (0, 5, 1), (1, 5, 6), (1, 6, 2), (2, 6, 7), (2, 7, 3), (3, 7, 4), (3, 4, 0)]
        return v, f
    sv, sf = box(300.6, 318.0, -56.0, -49.6, -794.5, -757.5)
    cv, cf = box(316.0, 329.0, -56.0, -46.8, -808.0, -756.0)
    pieces_p = pieces + [("Sea", "Sea", sea_v, sea_f, []), ("CoveSand", "Sand", sv, sf, []), ("Causeway", "Stone", cv, cf, [])]
    open(os.path.join(HERE, "tidepools_preview.mtl"), "w").write(
        "newmtl Rock\nKd 1 1 1\nmap_Kd tidepool_rock.png\nnewmtl PoolWater\nKd 0.36 0.70 0.72\nnewmtl Sea\nKd 0.16 0.55 0.58\n"
        "newmtl Sand\nKd 0.89 0.83 0.66\nnewmtl Stone\nKd 0.80 0.78 0.72\n")
    write_obj(os.path.join(HERE, "tidepools_preview.obj"), pieces_p, "tidepools_preview.mtl", False)
    json.dump(dict(pieces=info, water=m["water"], sea=SEA), open(os.path.join(HERE, "tidepools_data.json"), "w"), indent=1)
    print("shelf tris", len(m["faces"]), "water tris", len(m["wf"]))
    print(json.dumps(info, indent=1))
    print("water", m["water"])
