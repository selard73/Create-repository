import bpy, sys, os, traceback
OUTD = sys.argv[sys.argv.index("--") + 1]
LOG = os.path.join(OUTD, "audit_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "mailman_squirrel_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; gi = {g.index: g.name for g in sq.vertex_groups}
    def region(name, test, bones):
        vs = [v for v in sq.data.vertices if test(v.co)]
        if not vs: log(f"{name}: no vertices"); return
        tot = [sum(g.weight for g in v.groups if gi[g.group] in bones) for v in vs]
        heavy = sum(1 for t in tot if t > 0.25)
        log(f"{name}: {len(vs)} verts, mean {'/'.join(bones)} weight {sum(tot)/len(tot):.3f}, max {max(tot):.2f}, verts over 0.25: {heavy}")
    # letter: in front of the chest, below the head slice (from ref_front: x -0.54..-0.1, z 0.67..1.21)
    region("letter vs head", lambda c: -0.6 < c.x < -0.05 and 0.6 < c.z < 1.3 and c.y < -0.3, ("Head", "Neck"))
    # satchel: right hip (x +0.34..+0.63, z 0.14..0.72)
    region("satchel vs tail", lambda c: c.x > 0.3 and 0.1 < c.z < 0.8, ("Tail1", "Tail2"))
    # sanity: the face should be mostly head
    region("face vs head", lambda c: abs(c.x) < 0.3 and c.z > 1.6 and c.y < -0.6, ("Head", "Neck"))
    log("AUDIT_DONE")
except Exception:
    log(traceback.format_exc())
