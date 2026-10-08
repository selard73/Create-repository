"""List vertices of a rigged squirrel in a box with head weight + texture colour, binned (to tell whiskers from a collar).
Run: blender --background --python probe_zone_cols.py -- <dir> <name> x0 x1 y0 y1 z0 z1   (writes <dir>/zone_cols.txt)"""
import bpy, sys, os
from collections import defaultdict
argv = sys.argv[sys.argv.index("--") + 1:]
D, N = argv[0], argv[1]
x0, x1, y0, y1, z0, z1 = map(float, argv[2:8])
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + "_rigged.blend"))
sq = bpy.data.objects["Squirrel"]
me = sq.data
gi = {g.index: g.name for g in sq.vertex_groups}
img = [n for n in me.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0].image
W, H = img.size; px = img.pixels[:]; uvl = me.uv_layers.active.data
col = {}
for poly in me.polygons:
    for li in poly.loop_indices:
        vi = me.loops[li].vertex_index
        if vi in col: continue
        uv = uvl[li].uv; k = (min(H - 1, int(uv[1] * H)) * W + min(W - 1, int(uv[0] * W))) * 4
        col[vi] = (255 * px[k], 255 * px[k + 1], 255 * px[k + 2])
bins = defaultdict(list)
for v in me.vertices:
    c = v.co
    if x0 <= c.x <= x1 and y0 <= c.y <= y1 and z0 <= c.z <= z1:
        hw = sum(g.weight for g in v.groups if gi[g.group] in ("Head", "Neck"))
        k = (round(c.x / 0.05) * 0.05, round(c.y / 0.05) * 0.05, round(c.z / 0.05) * 0.05)
        bins[k].append((hw, col.get(v.index, (0, 0, 0))))
with open(os.path.join(D, "zone_cols.txt"), "w") as f:
    for k in sorted(bins, key=lambda k: (k[2], k[0], k[1])):
        L = bins[k]; n = len(L)
        hw = sum(a for a, _ in L) / n
        r = sum(c[0] for _, c in L) / n; g = sum(c[1] for _, c in L) / n; b = sum(c[2] for _, c in L) / n
        f.write(f"z {k[2]:.2f} x {k[0]:+.2f} y {k[1]:+.2f}  n {n:3d}  head {hw:.2f}  rgb {r:3.0f},{g:3.0f},{b:3.0f}\n")
    f.write("PROBE_DONE\n")
