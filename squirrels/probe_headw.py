"""List head-weighted vertices in a box of a rigged squirrel, binned, to separate cheek fur from a raised arm.
Run: blender --background --python probe_headw.py -- <dir> <name> x0 x1 z0 z1"""
import bpy, sys, os
from collections import defaultdict
argv = sys.argv[sys.argv.index("--") + 1:]
D, N = argv[0], argv[1]
x0, x1, z0, z1 = map(float, argv[2:6])
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + "_rigged.blend"))
sq = bpy.data.objects["Squirrel"]
gi = {g.index: g.name for g in sq.vertex_groups}
bins = defaultdict(lambda: [0, 0.0])
for v in sq.data.vertices:
    c = v.co
    if x0 <= c.x <= x1 and z0 <= c.z <= z1:
        hw = sum(g.weight for g in v.groups if gi[g.group] in ("Head", "Neck"))
        k = (round(c.x / 0.05) * 0.05, round(c.y / 0.1) * 0.1, round(c.z / 0.1) * 0.1)
        bins[k][0] += 1; bins[k][1] += hw
with open(os.path.join(D, "headw_probe.txt"), "w") as f:
    for k in sorted(bins):
        n, s = bins[k]
        f.write(f"x {k[0]:+.2f} y {k[1]:+.1f} z {k[2]:.1f}  n {n:3d}  head {s / n:.2f}\n")
    f.write("PROBE_DONE\n")
