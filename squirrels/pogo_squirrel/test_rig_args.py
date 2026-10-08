import bpy, os
from mathutils import Vector

OUTD = r"C:\Users\slard\roblox-props\squirrels\pogo_squirrel"
LOG = os.path.join(OUTD, "test_rig_log.txt")
with open(LOG, "w") as f:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "pogo_squirrel.blend"))
    sq = bpy.data.objects["Squirrel"]
    pts = [v.co for v in sq.data.vertices]
    BX = -0.25
    head = [p for p in pts if p.y < -0.30 and 1.6 < p.z < 99 and abs(p.x - BX) < 0.5]
    tail = [p for p in pts if p.y > 0.15 and 0.8 < p.z < 99 and p.x > 0.05]
    def centroid(ps): return sum(ps, Vector()) / len(ps) if ps else None
    hc = centroid(head)
    tc = centroid(tail)
    f.write(f"Head verts: {len(head)}, hc: {hc}\n")
    f.write(f"Tail verts: {len(tail)}, tc: {tc}\n")
    f.write("TEST_RIG_DONE\n")
