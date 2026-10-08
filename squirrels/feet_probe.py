"""Foot contact clusters of a prepped squirrel (verts with z < 0.06). Run: blender -b --python feet_probe.py -- <blend>"""
import bpy, sys, traceback
argv = sys.argv[sys.argv.index("--") + 1:]; BL = argv[0]; LOG = BL + ".feet.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    me = bpy.data.objects["Squirrel"].data
    pts = [v.co.copy() for v in me.vertices if v.co.z < 0.06]
    pts.sort(key=lambda p: p.x)
    cl = []
    for p in pts:
        for c in cl:
            if abs(c[0].x - p.x) < 0.25 and abs(c[0].y - p.y) < 0.4: c.append(p); break
        else: cl.append([p])
    out = []
    for c in cl:
        n = len(c); out.append("n %d centre x %.3f y %.3f  x %.2f..%.2f y %.2f..%.2f" % (n, sum(p.x for p in c)/n, sum(p.y for p in c)/n, min(p.x for p in c), max(p.x for p in c), min(p.y for p in c), max(p.y for p in c)))
    open(LOG, "w").write("\n".join(out) + "\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
