"""Render the poses the Roblox client uses (CrocClient) on the rigged croc, to check them before Studio:
swim (legs tucked + tail mid-stroke), hold (jaw on a victim, nose up), nap, lunge (jaw wide), dizzy.
Run: blender --background --python pose_check.py -- <out_dir>"""
import bpy, sys, os, math, traceback
from mathutils import Vector, Matrix
OUTD = sys.argv[sys.argv.index("--") + 1:][0]
LOG = os.path.join(OUTD, "posecheck_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
LEFT, UP, FWD = Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, -1, 0))
ORDER = ["Hips", "Chest", "Neck", "Head", "Jaw", "Tail1", "Tail2", "Tail3", "Tail4", "Tail5",
         "FrontUpper.L", "FrontLower.L", "FrontFoot.L", "FrontUpper.R", "FrontLower.R", "FrontFoot.R",
         "HindUpper.L", "HindLower.L", "HindFoot.L", "HindUpper.R", "HindLower.R", "HindFoot.R"]
def rot_world(pb, axis, deg):
    if abs(deg) < 1e-6: return
    m = pb.matrix.copy(); loc = m.to_translation()
    m2 = Matrix.Rotation(math.radians(deg), 4, Vector(axis)) @ m; m2.translation = loc; pb.matrix = m2
    bpy.context.view_layer.update()
def apply(pb, W):
    # same order as the client: yaw * pitch * roll in the world, parents first
    for n in ORDER:
        if n in W:
            p, y, r = W[n]
            b = pb[n]
            rot_world(b, FWD, r); rot_world(b, LEFT, p); rot_world(b, UP, y)
def tuck(W):
    for n, v in {"FrontUpper.L": (0, 25, 7), "FrontUpper.R": (0, -25, -7), "HindUpper.L": (0, 23, 5), "HindUpper.R": (0, -23, -5)}.items():
        a = W.setdefault(n, [0, 0, 0]); a[0] += v[0]; a[1] += v[1]; a[2] += v[2]
def add(W, n, p=0, y=0, r=0):
    a = W.setdefault(n, [0, 0, 0]); a[0] += p; a[1] += y; a[2] += r
def swim(phase, amp):
    W = {}; tuck(W)
    for n, a0, off in (("Tail1", 7, 0), ("Tail2", 10, 0.8), ("Tail3", 13, 1.6), ("Tail4", 12, 2.4), ("Tail5", 10, 3.2)):
        add(W, n, 0, a0 * amp * math.sin(phase - off), 0)
    add(W, "Hips", 0, -4 * amp * math.sin(phase + 0.6)); add(W, "Chest", 0, 3 * amp * math.sin(phase + 1.2))
    add(W, "Neck", 0, -2.5 * amp * math.sin(phase + 1.8)); add(W, "Jaw", -15)
    return W
POSES = {
    "swim_a": swim(math.pi / 2, 1.2),
    "swim_b": swim(-math.pi / 2, 1.2),
    "hold": (lambda W: (add(W, "Neck", -10), add(W, "Head", -16, 10), add(W, "Jaw", -16), W)[-1])(swim(0, 0.4)),
    "lunge": (lambda W: (add(W, "Neck", -8), add(W, "Jaw", 16), W)[-1])(swim(0, 0.4)),
    "nap": (lambda W: (add(W, "Neck", 7), add(W, "Head", 5), add(W, "Jaw", -22), W)[-1])(swim(0, 0.3)),
    "dizzy": (lambda W: (add(W, "Head", 0, 12, 12), add(W, "Neck", 4), add(W, "Jaw", 6), W)[-1])(swim(0, 0.3)),
}
def render(sc, path, frm, to, ortho=None, res=(1000, 640), up=(0, 0, 1)):
    sc.render.resolution_x, sc.render.resolution_y = res
    cam = sc.camera; cam.location = Vector(frm)
    f = (Vector(to) - cam.location).normalized(); r = f.cross(Vector(up)).normalized(); u = r.cross(f).normalized()
    cam.rotation_mode = "QUATERNION"; cam.rotation_quaternion = Matrix((r, u, -f)).transposed().to_4x4().to_quaternion()
    if ortho: cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else: cam.data.type = "PERSP"; cam.data.lens = 40
    sc.render.filepath = path; bpy.ops.render.render(write_still=True)
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "croc_rigged.blend"))
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.image_settings.file_format = "PNG"
    # a water plane at the swim line (bottom 2.9 below the surface in Blender units)
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 8, 2.9)); wp = bpy.context.active_object
    wm = bpy.data.materials.new("Water"); wm.diffuse_color = (0.2, 0.42, 0.34, 0.55); wp.data.materials.append(wm)
    wp.active_material.blend_method = "BLEND" if hasattr(wp.active_material, "blend_method") else None
    sh.show_xray = False
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    bpy.context.view_layer.objects.active = arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    for name, W in POSES.items():
        for b in pb: b.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        apply(pb, W)
        bpy.ops.object.mode_set(mode="OBJECT")
        wp.hide_render = True
        render(sc, os.path.join(OUTD, f"pc_{name}_34.png"), (9, -6, 7), (0, 6.5, 2.0))
        if name.startswith("swim"):
            render(sc, os.path.join(OUTD, f"pc_{name}_top.png"), (0, 8, 40), (0, 8, 0), ortho=18, res=(700, 1100), up=(0, -1, 0))
            render(sc, os.path.join(OUTD, f"pc_{name}_under.png"), (0, 8, -40), (0, 8, 0), ortho=18, res=(700, 1100), up=(0, -1, 0))
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    log("PC_DONE")
except Exception:
    log(traceback.format_exc()); log("PC_FAILED")
