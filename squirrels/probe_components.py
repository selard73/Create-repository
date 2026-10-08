"""Connected pieces INSIDE a box (edges only between vertices that are both in the box), with bbox, centroid and
mean Head/Chest/Tail weights. Separates e.g. raised hands from cheeks on a fused Meshy mesh.
Run: blender --background --python probe_components.py -- <out_dir> <name> '<json list of boxes [x0,x1,y0,y1,z0,z1]>'"""
import bpy, bmesh, sys, os, json, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, BOXES = argv[0], argv[1], json.loads(argv[2])
LOG = os.path.join(OUTD, "probe_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; gi = {g.index: g.name for g in sq.vertex_groups}
    bm = bmesh.new(); bm.from_mesh(sq.data); bm.verts.ensure_lookup_table()
    mv = sq.data.vertices
    def wsum(i, names): return sum(g.weight for g in mv[i].groups if gi[g.group] in names)
    for b in BOXES:
        inb = {v.index for v in bm.verts if b[0] <= v.co.x <= b[1] and b[2] <= v.co.y <= b[3] and b[4] <= v.co.z <= b[5]}
        seen = set(); comps = []
        for i0 in inb:
            if i0 in seen: continue
            stack = [bm.verts[i0]]; comp = []; seen.add(i0)
            while stack:
                v = stack.pop(); comp.append(v.index)
                for e in v.link_edges:
                    o = e.other_vert(v)
                    if o.index in inb and o.index not in seen: seen.add(o.index); stack.append(o)
            comps.append(comp)
        comps.sort(key=len, reverse=True)
        log(f"BOX {b}: {len(inb)} verts, {len(comps)} pieces")
        for n, comp in enumerate(comps[:8]):
            cs = [mv[i].co for i in comp]
            lo = Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs)))
            hi = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))
            cen = sum(cs, Vector()) / len(cs)
            h = sum(wsum(i, ("Head", "Neck")) for i in comp) / len(comp)
            c = sum(wsum(i, ("Chest",)) for i in comp) / len(comp)
            log(f"  #{n} verts {len(comp):4d}  x {lo.x:5.2f}..{hi.x:5.2f}  y {lo.y:5.2f}..{hi.y:5.2f}  z {lo.z:5.2f}..{hi.z:5.2f}  centre ({cen.x:5.2f},{cen.y:5.2f},{cen.z:5.2f})  head {h:.2f} chest {c:.2f}")
    log("PROBE_DONE")
except Exception:
    log(traceback.format_exc())
