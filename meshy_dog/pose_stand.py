"""Try a standing pose on the rigged pup: lift the hips, straighten the hind legs, level the spine.
Renders stand_test.png and logs the bone transforms used. Run: blender --background --python pose_stand.py -- <out_dir>"""
import bpy, sys, os, math, traceback
from mathutils import Vector, Quaternion

argv = sys.argv[sys.argv.index("--") + 1:]
OUTD = argv[0]
LOG = os.path.join(OUTD, "stand_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")

def aim_bone(pb, target_dir):
    """Rotate a pose bone so its Y axis (bone direction) points along target_dir (world)."""
    cur = (pb.matrix.to_3x3() @ Vector((0, 1, 0))).normalized()
    q = cur.rotation_difference(Vector(target_dir).normalized())
    # apply in pose space: new world rot = q * current
    m = pb.matrix.copy()
    rot = q.to_matrix().to_4x4()
    loc = m.to_translation()
    m_new = rot @ m
    m_new.translation = loc
    pb.matrix = m_new

try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "pup_rigged.blend"))
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    for b in pb: b.rotation_mode = "XYZ"
    # 1) lift hips so the rump comes off the ground (world Z), and level the spine
    pb["Hips"].location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    hips_world = pb["Hips"].matrix.to_translation()
    lift = 1.05
    # move via matrix so the lift is in world Z regardless of bone axes
    m = pb["Hips"].matrix.copy(); m.translation = hips_world + Vector((0, 0, lift)); pb["Hips"].matrix = m
    bpy.context.view_layer.update()
    aim_bone(pb["Hips"], (0, -1, 0.55))          # spine runs forward and slightly up toward the chest
    bpy.context.view_layer.update()
    aim_bone(pb["Chest"], (0, -1, 0.2))
    bpy.context.view_layer.update()
    # 2) hind legs point straight down under the hips
    for side in ("L", "R"):
        aim_bone(pb[f"HindLeg.{side}"], (0, 0.05, -1))
        bpy.context.view_layer.update()
        aim_bone(pb[f"FrontLeg.{side}"], (0, -0.05, -1))
        bpy.context.view_layer.update()
    # 3) neck/head back to a natural standing carriage
    aim_bone(pb["Neck"], (0, -0.8, 0.6)); bpy.context.view_layer.update()
    aim_bone(pb["Head"], (0, -1, 0.15)); bpy.context.view_layer.update()
    aim_bone(pb["Tail1"], (0.2, 0.6, 0.8)); bpy.context.view_layer.update()
    aim_bone(pb["Tail2"], (0.2, 0.3, 1.0)); bpy.context.view_layer.update()
    for name in ("Hips", "Chest", "Neck", "Head", "HindLeg.L", "FrontLeg.L", "Tail1"):
        b = pb[name]
        log(f"{name}: loc {tuple(round(v,3) for v in b.location)} rot(xyz deg) {tuple(round(math.degrees(v),1) for v in b.rotation_euler)}")
    bpy.ops.object.mode_set(mode="OBJECT")
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 900, 700
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    c = Vector((0.0, 0.2, 2.6))
    camo.location = (7.5, -7.0, 4.5)
    camo.rotation_euler = (c - camo.location).to_track_quat("-Z", "Y").to_euler()
    cam.lens = 45
    sc.render.filepath = os.path.join(OUTD, "stand_test.png")
    bpy.ops.render.render(write_still=True)
    log("STAND_DONE")
except Exception:
    log(traceback.format_exc())
