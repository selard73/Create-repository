"""Find a raised paw's tip on a rigged squirrel: vertices with x in [x0, x1] above z0 -> highest point and the top cluster's centre.
Run: blender --background --python paw_tip_probe.py -- <dir> <name> x0 x1 z0   (writes <dir>/paw_tip.txt)"""
import bpy, sys, os
argv = sys.argv[sys.argv.index("--") + 1:]
D, N = argv[0], argv[1]
x0, x1, z0 = map(float, argv[2:5])
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + "_rigged.blend"))
sq = bpy.data.objects["Squirrel"]
vs = [v.co.copy() for v in sq.data.vertices if x0 <= v.co.x <= x1 and v.co.z >= z0]
top = max(vs, key=lambda c: c.z)
near = [c for c in vs if c.z >= top.z - 0.15]
cx = sum(c.x for c in near) / len(near); cy = sum(c.y for c in near) / len(near); cz = sum(c.z for c in near) / len(near)
with open(os.path.join(D, "paw_tip.txt"), "w") as f:
    f.write(f"n {len(vs)} top ({top.x:.3f}, {top.y:.3f}, {top.z:.3f}) top-0.15 cluster n {len(near)} centre ({cx:.3f}, {cy:.3f}, {cz:.3f})\n")
    f.write(f"x {min(c.x for c in near):.3f}..{max(c.x for c in near):.3f} y {min(c.y for c in near):.3f}..{max(c.y for c in near):.3f}\n")
    f.write("PROBE_DONE\n")
