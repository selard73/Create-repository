"""Prop-agnostic weight audit for a rigged squirrel.
Run: blender --background --python audit_generic.py -- <out_dir> <name>
Reports: vertices below the head that follow the head (held props), low/wide vertices that follow the tail (hip
props, capes), and a face sanity check, each with a bounding box so a targeted fix can be written."""
import bpy, sys, os, json, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
LOG = os.path.join(OUTD, "audit_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; gi = {g.index: g.name for g in sq.vertex_groups}
    B = json.load(open(os.path.join(OUTD, "bones.json")))
    neck_z = B["Neck"][1][2]                          # where the head bone starts
    hc = (Vector(B["Head"][0]) + Vector(B["Head"][1])) / 2
    def w(v, names): return sum(g.weight for g in v.groups if gi[g.group] in names)
    def report(label, vs):
        if not vs: log(f"{label}: none"); return
        lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
        hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
        dmin = min((v.co - hc).length for v in vs)
        log(f"{label}: {len(vs)} verts, bbox x {lo.x:.2f}..{hi.x:.2f} y {lo.y:.2f}..{hi.y:.2f} z {lo.z:.2f}..{hi.z:.2f}, nearest to head centre {dmin:.2f}")
    log(f"head centre {tuple(round(c, 2) for c in hc)}, neck starts z {neck_z:.2f}")
    report("below-neck verts following the HEAD (>0.25)", [v for v in sq.data.vertices if v.co.z < neck_z - 0.1 and w(v, ("Head", "Neck")) > 0.25])
    report("low or wide verts following the TAIL (>0.25)", [v for v in sq.data.vertices if (v.co.z < 1.0 or abs(v.co.x) > 0.45) and w(v, ("Tail1", "Tail2")) > 0.25])
    face = [v for v in sq.data.vertices if (v.co - hc).length < 0.4]
    log(f"face check: {len(face)} verts within 0.4 of head centre, mean head weight {sum(w(v, ('Head', 'Neck')) for v in face) / max(1, len(face)):.3f}")
    head_far = sorted((v.co - hc).length for v in sq.data.vertices if v.co.z >= neck_z - 0.1 and w(v, ("Head",)) > 0.5)
    if head_far: log(f"head-bound verts above the neck: farthest from head centre {head_far[-1]:.2f}, 95th percentile {head_far[int(len(head_far) * 0.95)]:.2f}")
    log("AUDIT_DONE")
except Exception:
    log(traceback.format_exc())
