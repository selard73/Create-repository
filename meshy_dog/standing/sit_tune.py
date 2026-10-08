"""Search sit-pose parameters so buttocks, hind paws and front paws all land on the ground.
Run: blender --background --python sit_tune.py -- <out_dir>"""
import bpy, sys, os, math, itertools, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD = argv[0]
LOG = os.path.join(OUTD, "tune_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
LEFT, UP, FWD = Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, -1, 0))
def rot_world(pb, axis, deg):
    if abs(deg) < 1e-6: return
    m = pb.matrix.copy(); loc = m.to_translation()
    R = Matrix.Rotation(math.radians(deg), 4, Vector(axis)); m2 = R @ m; m2.translation = loc; pb.matrix = m2
    bpy.context.view_layer.update()
def move_world(pb, off):
    m = pb.matrix.copy(); m.translation = m.to_translation() + Vector(off); pb.matrix = m
    bpy.context.view_layer.update()
def pose(pb, name, pitch=0, yaw=0, roll=0, off=None):
    b = pb[name]
    if off: move_world(b, off)
    rot_world(b, FWD, roll); rot_world(b, LEFT, pitch); rot_world(b, UP, yaw)
ORDER = ["Hips", "Chest", "Neck", "Head", "Ear.L", "Ear.R", "Tail1", "Tail2",
         "FrontUpper.L", "FrontLower.L", "FrontPaw.L", "FrontUpper.R", "FrontLower.R", "FrontPaw.R",
         "HindUpper.L", "HindLower.L", "HindPaw.L", "HindUpper.R", "HindLower.R", "HindPaw.R"]

PAW_FLAT = -51   # paw flat along the ground in front of the vertical shin
def sit_spec(pitch, drop, fwd, thigh, chest):
    """Puppy splay with split spine: pelvis pitches `pitch`, chest adds `chest`; hind legs straight, swung forward to `thigh`."""
    s = {"Hips": dict(pitch=pitch, off=(0, fwd, -drop)), "Chest": dict(pitch=chest), "Neck": dict(pitch=14), "Head": dict(pitch=14),
         "Tail1": dict(pitch=30), "Tail2": dict(pitch=10)}
    for side in (".L", ".R"):
        s["FrontUpper" + side] = dict(pitch=-pitch - chest - 4); s["FrontPaw" + side] = dict(pitch=4)
        s["HindUpper" + side] = dict(pitch=thigh - pitch); s["HindLower" + side] = dict(pitch=0); s["HindPaw" + side] = dict(pitch=-51 - thigh)
    return s

try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "standing_rigged.blend"))
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    dogo = [o for o in bpy.data.objects if o.type == "MESH" and o.name == "Hound"][0]
    bpy.context.view_layer.objects.active = arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="POSE"); pb = arm.pose.bones
    # vertex sets from the rig's own weights (dominant group)
    gnames = {g.index: g.name for g in dogo.vertex_groups}
    dom = {}
    for v in dogo.data.vertices:
        if v.groups:
            g = max(v.groups, key=lambda g: g.weight); dom[v.index] = gnames[g.group]
    rest = {v.index: v.co.copy() for v in dogo.data.vertices}
    FP = [i for i, n in dom.items() if n.startswith("FrontPaw")]
    HP = [i for i, n in dom.items() if n.startswith("HindPaw")]
    HL = [i for i, n in dom.items() if n.startswith("HindLower")]
    BUTT = [i for i, n in dom.items() if n in ("Hips", "Tail1") and rest[i].z < 1.7 and rest[i].y > 1.4]
    log(f"vertex sets: frontpaw {len(FP)} hindpaw {len(HP)} hindlower {len(HL)} butt {len(BUTT)}")
    def measure():
        dg = bpy.context.evaluated_depsgraph_get(); ev = dogo.evaluated_get(dg)
        vs = [ev.matrix_world @ v.co for v in ev.data.vertices]
        return min(vs[i].z for i in BUTT), min(min(vs[i].z for i in HP), min(vs[i].z for i in HL)), min(vs[i].z for i in FP)
    log("pitch drop thigh | butt  hpaw  fpaw | score")
    results = []
    for pitch, chest, drop, thigh in itertools.product((-24, -30, -36), (-22, -28, -34), (1.2, 1.35, 1.5), (-68, -76, -84)):
        for b in pb: b.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        spec = sit_spec(pitch, drop, 0.15, thigh, chest)
        for bn in ORDER:
            if bn in spec: pose(pb, bn, **spec[bn])
        bt, hp_z, fp = measure()
        score = abs(bt) + abs(hp_z) + abs(fp) + (0.5 if bt < -0.15 else 0)
        results.append((score, pitch, chest, drop, thigh, bt, hp_z, fp))
        log(f"{pitch:5d} {chest:5d} {drop:4.2f} {thigh:4d} | {bt:5.2f} {hp_z:5.2f} {fp:5.2f} | {score:.2f}")
    results.sort()
    log("BEST:")
    for r in results[:6]: log(r)
    log("TUNE_DONE")
except Exception:
    log(traceback.format_exc())
