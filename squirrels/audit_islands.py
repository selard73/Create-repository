"""List the connected pieces (islands) of a rigged squirrel mesh with size, bbox, centroid and mean bone weights.
Run: blender --background --python audit_islands.py -- <out_dir> <name>"""
import bpy, bmesh, sys, os, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
LOG = os.path.join(OUTD, "islands_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; gi = {g.index: g.name for g in sq.vertex_groups}
    bm = bmesh.new(); bm.from_mesh(sq.data); bm.verts.ensure_lookup_table()
    seen = set(); islands = []
    for v0 in bm.verts:
        if v0.index in seen: continue
        stack = [v0]; comp = []; seen.add(v0.index)
        while stack:
            v = stack.pop(); comp.append(v.index)
            for e in v.link_edges:
                o = e.other_vert(v)
                if o.index not in seen: seen.add(o.index); stack.append(o)
        islands.append(comp)
    islands.sort(key=len, reverse=True)
    log(f"{len(islands)} islands, total verts {len(bm.verts)}")
    mv = sq.data.vertices
    def wsum(i, names): return sum(g.weight for g in mv[i].groups if gi[g.group] in names)
    for n, comp in enumerate(islands):
        cs = [mv[i].co for i in comp]
        lo = Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs)))
        hi = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))
        cen = sum(cs, Vector()) / len(cs)
        h = sum(wsum(i, ("Head", "Neck")) for i in comp) / len(comp)
        t = sum(wsum(i, ("Tail1", "Tail2")) for i in comp) / len(comp)
        c = sum(wsum(i, ("Chest",)) for i in comp) / len(comp)
        if n < 40:
            log(f"#{n:02d} verts {len(comp):5d}  x {lo.x:5.2f}..{hi.x:5.2f}  y {lo.y:5.2f}..{hi.y:5.2f}  z {lo.z:5.2f}..{hi.z:5.2f}  centre ({cen.x:5.2f},{cen.y:5.2f},{cen.z:5.2f})  head {h:.2f} chest {c:.2f} tail {t:.2f}")
    log("ISLANDS_DONE")
except Exception:
    log(traceback.format_exc())
