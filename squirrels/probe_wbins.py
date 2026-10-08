"""Bin the vertices of a rigged squirrel inside a box and print mean weights per bone group, to find where a tail ends
and a hat brim begins (Oct 5 2026, Penny). Also prints the mean texture colour per bin so fur (brown) and straw (tan)
can be told apart. Run: blender --background --python probe_wbins.py -- <dir> <name> x0 x1 y0 y1 z0 z1 [step] [blend]"""
import bpy, sys, os
from collections import defaultdict
argv = sys.argv[sys.argv.index("--") + 1:]
D, N = argv[0], argv[1]
x0, x1, y0, y1, z0, z1 = map(float, argv[2:8])
S = float(argv[8]) if len(argv) > 8 else 0.1
BL = argv[9] if len(argv) > 9 else N + "_rigged.blend"
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, BL))
sq = bpy.data.objects["Squirrel"]
me = sq.data
gi = {g.index: g.name for g in sq.vertex_groups}
img = [n for n in me.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0].image
W, H = img.size; px = img.pixels[:]
uvl = me.uv_layers.active.data
vuv = {}
for poly in me.polygons:
    for li in poly.loop_indices:
        vuv.setdefault(me.loops[li].vertex_index, uvl[li].uv)
bins = defaultdict(lambda: [0, defaultdict(float), [0.0, 0.0, 0.0]])
for v in me.vertices:
    c = v.co
    if not (x0 <= c.x <= x1 and y0 <= c.y <= y1 and z0 <= c.z <= z1): continue
    k = (round(c.x / S) * S, round(c.y / S) * S, round(c.z / S) * S)
    b = bins[k]; b[0] += 1
    for g in v.groups: b[1][gi[g.group]] += g.weight
    uv = vuv.get(v.index)
    if uv is not None:
        i = (min(H - 1, int(uv[1] * H)) * W + min(W - 1, int(uv[0] * W))) * 4
        for j in range(3): b[2][j] += px[i + j]
with open(os.path.join(D, "wbins_probe.txt"), "w") as f:
    for k in sorted(bins):
        n, ws, col = bins[k]
        top = sorted(ws.items(), key=lambda t: -t[1])[:3]
        f.write(f"x {k[0]:+.2f} y {k[1]:+.2f} z {k[2]:.2f} n {n:3d} rgb {int(255*col[0]/n):3d},{int(255*col[1]/n):3d},{int(255*col[2]/n):3d}  " +
                " ".join(f"{nm} {w / n:.2f}" for nm, w in top) + "\n")
    f.write("PROBE_DONE\n")
