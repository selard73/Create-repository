import bpy, sys, os, traceback
OUTD = sys.argv[sys.argv.index("--") + 1]
LOG = os.path.join(OUTD, "satchel_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "mailman_squirrel_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; gi = {g.index: g.name for g in sq.vertex_groups}
    root = sq.vertex_groups["Root"]; moved = 0
    for v in sq.data.vertices:
        c = v.co
        if c.x > 0.3 and 0.1 < c.z < 0.8:                      # the satchel on the right hip only
            w = sum(g.weight for g in v.groups if gi[g.group] in ("Tail1", "Tail2"))
            if w > 0:
                for nm in ("Tail1", "Tail2"): sq.vertex_groups[nm].remove([v.index])
                cur = sum(g.weight for g in v.groups if gi[g.group] == "Root")
                root.add([v.index], min(1.0, cur + w), "REPLACE"); moved += 1
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "mailman_squirrel_rigged.blend"))
    log(f"satchel fix: {moved} vertices moved from Tail to Root"); log("SATCHEL_DONE")
except Exception:
    log(traceback.format_exc())
