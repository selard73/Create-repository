"""Rig the aligned Meshy pup: build an armature from measured landmarks, bind the mesh with automatic
weights, export pup_rigged.fbx, and render a test pose (head turned, jaw open, tail and ears moved)
so the skinning can be checked. Writes rig_log.txt.
Run: blender --background --python rig_pup.py -- <out_dir>"""
import bpy, sys, os, math, traceback
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUTD = argv[0]
LOG = os.path.join(OUTD, "rig_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")

# bone name: (head, tail, parent). Coordinates: nose toward -Y, feet at z=0, x centred.
BONES = {
    "Hips":     ((0.0, 1.0, 2.0),   (0.0, 0.35, 3.25), None),
    "Chest":    ((0.0, 0.35, 3.25), (0.0, -0.3, 3.65), "Hips"),
    "Neck":     ((0.0, -0.3, 3.65), (0.0, -0.8, 4.3),  "Chest"),
    "Head":     ((0.0, -0.8, 4.3),  (0.0, -1.55, 4.55), "Neck"),
    "Jaw":      ((0.0, -1.15, 3.65), (0.0, -1.9, 3.25), "Head"),
    "Ear.L":    ((0.62, -0.9, 4.7),  (1.12, -0.75, 4.1), "Head"),
    "Ear.R":    ((-0.62, -0.9, 4.7), (-1.12, -0.75, 4.1), "Head"),
    "Tail1":    ((0.15, 1.7, 1.05),  (0.5, 2.1, 0.6),  "Hips"),
    "Tail2":    ((0.5, 2.1, 0.6),    (0.72, 2.42, 0.55), "Tail1"),
    "FrontLeg.L": ((0.65, -0.35, 2.7), (0.7, -0.5, 0.3), "Chest"),
    "FrontLeg.R": ((-0.65, -0.35, 2.7), (-0.7, -0.5, 0.3), "Chest"),
    "HindLeg.L":  ((0.75, 1.0, 1.7),  (0.55, -0.1, 0.3), "Hips"),
    "HindLeg.R":  ((-0.75, 1.0, 1.7), (-0.55, -0.1, 0.3), "Hips"),
}

try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "pup_aligned.blend"))
    dog = [o for o in bpy.data.objects if o.type == "MESH"][0]
    # armature
    arm_data = bpy.data.armatures.new("HoundRig")
    arm = bpy.data.objects.new("HoundRig", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for name, (h, t, parent) in BONES.items():
        b = arm_data.edit_bones.new(name)
        b.head = Vector(h); b.tail = Vector(t)
        eb[name] = b
    for name, (h, t, parent) in BONES.items():
        if parent:
            eb[name].parent = eb[parent]
            eb[name].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    # bind
    bpy.ops.object.select_all(action="DESELECT")
    dog.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    try:
        bpy.ops.object.parent_set(type="ARMATURE_AUTO")
        log("bound with automatic weights")
    except Exception as e:
        log(f"auto weights failed ({e}); using envelope weights")
        bpy.ops.object.parent_set(type="ARMATURE_ENVELOPE")
    # report weight coverage
    zero = sum(1 for v in dog.data.vertices if not v.groups or sum(g.weight for g in v.groups) < 0.01)
    log(f"vertices with no weight: {zero} / {len(dog.data.vertices)}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "pup_rigged.blend"))
    # export rigged FBX (rest pose)
    bpy.ops.object.select_all(action="DESELECT")
    dog.select_set(True); arm.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "pup_rigged.fbx"), use_selection=True, path_mode="COPY", embed_textures=False,
                             mesh_smooth_type="FACE", axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=False,
                             add_leaf_bones=False, primary_bone_axis="Y", secondary_bone_axis="X", armature_nodetype="NULL",
                             bake_anim=False, object_types={"ARMATURE", "MESH"})
    log("exported pup_rigged.fbx")
    # test pose: turn head, open jaw, swing tail, lift ears
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    for b in pb: b.rotation_mode = "XYZ"
    pb["Head"].rotation_euler = (0.0, 0.0, math.radians(30))          # turn head to the side
    pb["Neck"].rotation_euler = (math.radians(-10), 0.0, 0.0)
    pb["Jaw"].rotation_euler = (math.radians(25), 0.0, 0.0)           # open mouth
    pb["Tail1"].rotation_euler = (0.0, 0.0, math.radians(35))
    pb["Tail2"].rotation_euler = (0.0, 0.0, math.radians(30))
    pb["Ear.L"].rotation_euler = (math.radians(-35), 0.0, 0.0)
    pb["Ear.R"].rotation_euler = (math.radians(20), 0.0, 0.0)
    bpy.ops.object.mode_set(mode="OBJECT")
    # render test pose + rest pose side by side (two files)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 900, 700
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    c = Vector((0.0, 0.2, 2.5))
    camo.location = (7.5, -7.0, 5.0)
    camo.rotation_euler = (c - camo.location).to_track_quat("-Z", "Y").to_euler()
    cam.lens = 45
    sc.render.filepath = os.path.join(OUTD, "rig_test_pose.png")
    bpy.ops.render.render(write_still=True)
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc())
