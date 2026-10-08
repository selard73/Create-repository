"""Render-only: open <name>_rigged.blend, turn the head (Neck +15, Head +25 deg about Z) and render one view.
Does not change or save weights.
Run: blender --background --python render_turned_view.py -- <out_dir> <name> <out png name> <off_x> <off_y> <off_z>"""
import bpy, sys, os, math, traceback
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, OUTPNG = argv[0], argv[1], argv[2]
OFF = Vector((float(argv[3]), float(argv[4]), float(argv[5])))
LOG = os.path.join(OUTD, "render_view_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = bpy.data.objects["SquirrelRig"]
    tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    tex.image = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sh.background_type = "VIEWPORT"; sh.background_color = (0.86, 0.88, 0.92)
    sc.render.resolution_x, sc.render.resolution_y = 700, 700
    sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    for o in list(bpy.data.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o)
    cam = bpy.data.cameras.new("Cam")
    camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 60
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones

    def rot_world(b, axis, deg):
        m = b.matrix.copy()
        loc = m.to_translation()
        m2 = Matrix.Rotation(math.radians(deg), 4, axis) @ m
        m2.translation = loc
        b.matrix = m2
        bpy.context.view_layer.update()

    if not os.environ.get("NOTURN"):          # NOTURN=1: same camera, rest pose (to tell a stretch from the model itself)
        rot_world(pb["Neck"], Vector((0, 0, 1)), 15)
        rot_world(pb["Head"], Vector((0, 0, 1)), 25)
    ctr = Vector((0, -0.4, 1.7))
    camo.location = ctr + OFF
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUTD, OUTPNG)
    bpy.ops.render.render(write_still=True)
    log("VIEW_DONE")
except Exception:
    log(traceback.format_exc())
