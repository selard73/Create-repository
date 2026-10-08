"""Find thin rod geometry in front of the chest. Run: blender -b --python stem_probe.py -- <blend>"""
import bpy, sys, traceback, bmesh
from collections import defaultdict
argv = sys.argv[sys.argv.index("--") + 1:]; BL = argv[0]; LOG = BL + ".stem.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    sq = bpy.data.objects["Squirrel"]; me = sq.data
    out = []
    cand = [v for v in me.vertices if -0.75 < v.co.y < -0.45 and 0.95 < v.co.z < 1.75]
    out.append("candidates %d" % len(cand))
    by = defaultdict(list)
    for v in cand: by[round(v.co.x, 1)].append(v)
    for k in sorted(by):
        vs = by[k]; out.append("x~%.1f n %d  y %.2f..%.2f z %.2f..%.2f" % (k, len(vs), min(v.co.y for v in vs), max(v.co.y for v in vs), min(v.co.z for v in vs), max(v.co.z for v in vs)))
    # thinness: vertices whose 1-ring spans < 0.03 in x and y but the chain is long in z
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    thin = []
    for v in bm.verts:
        if not (-0.75 < v.co.y < -0.4 and 0.9 < v.co.z < 1.8): continue
        nb = [e.other_vert(v) for e in v.link_edges]
        if not nb: continue
        sx = max(abs(n.co.x - v.co.x) for n in nb); sy = max(abs(n.co.y - v.co.y) for n in nb)
        dz = max(abs(n.co.z - v.co.z) for n in nb)
        if sx < 0.02 and sy < 0.02: thin.append((v.index, round(v.co.x, 3), round(v.co.y, 3), round(v.co.z, 3), round(dz, 3)))
    out.append("thin verts %d" % len(thin))
    for t in sorted(thin, key=lambda t: t[3]): out.append("  %s" % (t,))
    open(LOG, "w").write("\n".join(out) + "\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
