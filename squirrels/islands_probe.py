"""List loose islands of a prepped squirrel with their bounding boxes. Run: blender -b --python islands_probe.py -- <blend>  (log: <blend>.islands.txt)"""
import bpy, sys, traceback, bmesh
argv = sys.argv[sys.argv.index("--") + 1:]; BL = argv[0]; LOG = BL + ".islands.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    sq = bpy.data.objects["Squirrel"]
    bm = bmesh.new(); bm.from_mesh(sq.data); bm.faces.ensure_lookup_table()
    seen = set(); isl = []
    for f in bm.faces:
        if f.index in seen: continue
        stack = [f]; seen.add(f.index); fs = []
        while stack:
            g = stack.pop(); fs.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen: seen.add(h.index); stack.append(h)
        vs = {v for g in fs for v in g.verts}
        xs = [v.co.x for v in vs]; ys = [v.co.y for v in vs]; zs = [v.co.z for v in vs]
        isl.append((len(fs), min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    isl.sort(reverse=True)
    out = ["faces %d islands %d" % (len(bm.faces), len(isl))]
    for i in isl[:40]: out.append("  n %5d  x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f" % i)
    open(LOG, "w").write("\n".join(out) + "\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
