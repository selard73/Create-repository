"""Repaint a white sliver under one eye's pupil (Oct 7 2026: the lemon seller's right eye showed white below the iris).
Works in 3D: rasterises the UV triangles of the faces inside an eye box, maps every texel back to its 3D point, finds the
dark iris/pupil texels, and recolours near-white texels that sit BELOW the iris centre and within its width with the
iris's own lower colour. The rest of the eye white (sides, top) stays.
Run: blender --background --python eye_fix.py -- <dir> <name> <texture.png> x0 x1 y0 y1 z0 z1 <out.png> <log>"""
import bpy, sys, os, traceback
import numpy as np
argv = sys.argv[sys.argv.index("--") + 1:]
D, N, TEX = argv[0], argv[1], argv[2]
x0, x1, y0, y1, z0, z1 = map(float, argv[3:9])
OUT, LOG = argv[9], argv[10]
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + ".blend"))
    ob = bpy.data.objects["Squirrel"]; me = ob.data
    uv = me.uv_layers.active.data
    img = bpy.data.images.load(TEX)
    W, H = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)   # bottom-up rows
    rgb = px[..., :3]
    tex = []      # (row, col, xyz)
    me.calc_loop_triangles()
    for lt in me.loop_triangles:
        c = sum((me.vertices[i].co for i in lt.vertices), me.vertices[lt.vertices[0]].co * 0) / 3
        if not (x0 <= c.x <= x1 and y0 <= c.y <= y1 and z0 <= c.z <= z1): continue
        P = [np.array(me.vertices[i].co) for i in lt.vertices]
        T = [np.array(uv[l].uv) * np.array([W, H]) for l in lt.loops]
        umin, umax = int(min(t[0] for t in T)), int(max(t[0] for t in T)) + 1
        vmin, vmax = int(min(t[1] for t in T)), int(max(t[1] for t in T)) + 1
        a, b, cc = T
        den = (b[1] - cc[1]) * (a[0] - cc[0]) + (cc[0] - b[0]) * (a[1] - cc[1])
        if abs(den) < 1e-9: continue
        for v in range(max(vmin, 0), min(vmax, H)):
            for u in range(max(umin, 0), min(umax, W)):
                p = np.array([u + 0.5, v + 0.5])
                w1 = ((b[1] - cc[1]) * (p[0] - cc[0]) + (cc[0] - b[0]) * (p[1] - cc[1])) / den
                w2 = ((cc[1] - a[1]) * (p[0] - cc[0]) + (a[0] - cc[0]) * (p[1] - cc[1])) / den
                w3 = 1 - w1 - w2
                if w1 < -0.02 or w2 < -0.02 or w3 < -0.02: continue
                tex.append((v, u, w1 * P[0] + w2 * P[1] + w3 * P[2]))
    log(f"texels in eye box {len(tex)}")
    lum = lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
    def brown(c): return 0.18 < c[0] < 0.75 and c[1] < c[0] * 0.78 and c[2] <= c[1] + 0.02 and 0.10 < lum(c) < 0.48
    iris = [(r, c, xyz) for r, c, xyz in tex if brown(rgb[r, c])]
    if not iris: raise SystemExit("no brown iris texels found")
    pts = np.array([t[2] for t in iris])
    ctr = pts.mean(axis=0)
    rad = float(np.percentile(np.linalg.norm((pts - ctr)[:, [0, 2]], axis=1), 90))
    log(f"iris centre {ctr.round(3)} radius ~{rad:.3f} from {len(iris)} brown texels")
    fill = np.median(np.array([rgb[r, c] for r, c, xyz in iris if xyz[2] < ctr[2]]), axis=0)
    def white(c): return lum(c) > 0.6 and abs(c[0] - c[2]) < 0.07 and abs(c[0] - c[1]) < 0.07
    n_in = n_below = 0
    for r, c, xyz in tex:
        col = rgb[r, c]
        if not white(col): continue
        d = np.linalg.norm((xyz - ctr)[[0, 2]])
        # only the lower OUTER side (+x = his left/your right in the front view): the eye white and the highlight
        # above and on the inner side stay, like his other eye
        lower_outer = (xyz[2] < ctr[2]) and (xyz[0] > ctr[0] - 0.2 * rad)
        inside = lower_outer and d < 0.75 * rad
        below = lower_outer and d < float(os.environ.get("BELOW", "1.2")) * rad
        if inside or below:
            px[r, c, :3] = fill
            if inside: n_in += 1
            else: n_below += 1
    log(f"recoloured {n_in} white texels inside the iris and {n_below} below it with {fill.round(3)}")
    img.pixels[:] = px.ravel()
    img.filepath_raw = OUT; img.file_format = "PNG"; img.save()
    log("EYE_DONE")
except SystemExit as e:
    log(f"STOP {e}")
except Exception:
    log(traceback.format_exc())
