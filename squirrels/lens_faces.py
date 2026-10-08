"""Find sunglass LENS faces on a prepped squirrel: front-most faces inside the red frame loops (front view), not red themselves.
Writes <dir>/lens_faces.json: [{uv:[[u,v]x3], z:[z x3], x:[...]}] for painting. Region box in final coords.
Run: blender -b --python lens_faces.py -- <dir> <name> <x0> <x1> <z0> <z1>"""
import bpy, sys, os, json, traceback
from mathutils import Vector
from mathutils.bvhtree import BVHTree
argv = sys.argv[sys.argv.index("--") + 1:]
D, NAME = argv[0], argv[1]; X0, X1, Z0, Z1 = map(float, argv[2:6])
LOG = os.path.join(D, "lens_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(D, f"{NAME}.blend"))
    sq = bpy.data.objects["Squirrel"]; me = sq.data
    img = None
    for n in sq.data.materials[0].node_tree.nodes:
        if n.type == "TEX_IMAGE": img = n.image
    W, H = img.size; px = list(img.pixels[:])
    def col(u, v):
        x = min(W - 1, max(0, int(u * W))); y = min(H - 1, max(0, int(v * H))); i = (y * W + x) * 4
        return px[i], px[i + 1], px[i + 2]
    uvl = me.uv_layers.active.data
    bvh = BVHTree.FromObject(sq, bpy.context.evaluated_depsgraph_get())
    G = 0.01
    nx, nz = int((X1 - X0) / G) + 1, int((Z1 - Z0) / G) + 1
    red = [[False] * nz for _ in range(nx)]
    info = []
    for p in me.polygons:
        c = p.center
        if not (X0 <= c.x <= X1 and Z0 <= c.z <= Z1): continue
        uv = [tuple(uvl[li].uv) for li in p.loop_indices]
        cu = sum(q[0] for q in uv) / 3; cv = sum(q[1] for q in uv) / 3
        r, g, b = col(cu, cv)
        hit = bvh.ray_cast(Vector((c.x, -5, c.z)), Vector((0, 1, 0)))
        front = hit[2] == p.index or (hit[0] is not None and hit[0].y > c.y - 0.004)
        isred = r > 0.25 and r > 2.2 * g and r > 2.2 * b
        info.append((p.index, c, uv, front, isred, (r, g, b)))
        if front and isred:
            # mark the triangle's footprint (vertices + centre) on the grid, dilated
            pts = [me.vertices[i].co for i in p.vertices] + [c]
            for q in pts:
                ix, iz = int((q.x - X0) / G), int((q.z - Z0) / G)
                for dx in range(-3, 4):
                    for dz in range(-3, 4):
                        if 0 <= ix + dx < nx and 0 <= iz + dz < nz: red[ix + dx][iz + dz] = True
    # flood fill the outside from the border; unreached non-red cells = inside a frame loop
    out = [[False] * nz for _ in range(nx)]
    st = [(i, j) for i in range(nx) for j in (0, nz - 1)] + [(i, j) for i in (0, nx - 1) for j in range(nz)]
    while st:
        i, j = st.pop()
        if out[i][j] or red[i][j]: continue
        out[i][j] = True
        for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= i + a < nx and 0 <= j + b < nz and not out[i + a][j + b]: st.append((i + a, j + b))
    inside = sum(1 for i in range(nx) for j in range(nz) if not out[i][j] and not red[i][j])
    log(f"grid {nx}x{nz} inside cells {inside}")
    res = []
    for idx, c, uv, front, isred, rgb in info:
        if not front or isred: continue
        i, j = int((c.x - X0) / G), int((c.z - Z0) / G)
        if not out[i][j] and not red[i][j]:
            p = me.polygons[idx]
            res.append({"f": idx, "uv": uv, "z": [me.vertices[k].co.z for k in p.vertices], "x": [me.vertices[k].co.x for k in p.vertices], "c": [c.x, c.z]})
    json.dump({"W": W, "H": H, "faces": res}, open(os.path.join(D, "lens_faces.json"), "w"))
    xs = [r["c"][0] for r in res]; zs = [r["c"][1] for r in res]
    log(f"lens faces {len(res)} x {min(xs):.2f}..{max(xs):.2f} z {min(zs):.2f}..{max(zs):.2f}" if res else "lens faces 0")
    # ascii map of the front view for checking: R frame, L lens face centre, . inside, ' ' outside
    for j in range(nz - 1, -1, -3):
        log("".join("R" if red[i][j] else ("." if not out[i][j] else " ") for i in range(0, nx, 2)))
    log("LENS_DONE")
except Exception:
    log(traceback.format_exc())
