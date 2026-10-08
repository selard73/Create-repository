"""Mean bone weights in height bands, split front (y < -0.3), middle, back (y > 0.3).
Run: blender --background --python probe_bands.py -- <out_dir> <name>"""
import bpy, sys, os, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
LOG = os.path.join(OUTD, "bands_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; gi = {g.index: g.name for g in sq.vertex_groups}
    bones = ["Root", "Chest", "Neck", "Head", "Tail1", "Tail2"]
    log("band      part   n     " + "  ".join(f"{b:>5s}" for b in bones) + "   x-range")
    z = 0.0
    while z < 1.5:
        for part, test in (("front", lambda y: y < -0.3), ("mid", lambda y: -0.3 <= y <= 0.3), ("back", lambda y: y > 0.3)):
            vs = [v for v in sq.data.vertices if z <= v.co.z < z + 0.1 and test(v.co.y)]
            if not vs: continue
            means = []
            for b in bones:
                means.append(sum(sum(g.weight for g in v.groups if gi[g.group] == b) for v in vs) / len(vs))
            log(f"{z:4.1f}-{z+0.1:3.1f}  {part:5s} {len(vs):4d}   " + "  ".join(f"{m:5.2f}" for m in means) + f"   {min(v.co.x for v in vs):5.2f}..{max(v.co.x for v in vs):5.2f}")
        z += 0.1
    log("BANDS_DONE")
except Exception:
    log(traceback.format_exc())
