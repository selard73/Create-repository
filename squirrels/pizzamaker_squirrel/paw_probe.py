import bpy, sys, os
D = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "pizzamaker_squirrel_rigged.blend"))
sq = bpy.data.objects["Squirrel"]
vs = [v.co for v in sq.data.vertices if v.co.x > 0.6 and v.co.z > 1.9]
n = len(vs)
c = sum(vs, vs[0] * 0) / n
top = max(vs, key=lambda v: v.z)
allv = [v.co for v in sq.data.vertices]
bb = [(min(v[i] for v in allv), max(v[i] for v in allv)) for i in range(3)]
open(os.path.join(D, "paw_probe.txt"), "w").write(f"n {n} centroid {tuple(round(a,3) for a in c)} top {tuple(round(a,3) for a in top)} bbox {[(round(a,3), round(b,3)) for a, b in bb]}")
