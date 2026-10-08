"""Checks for village fix 1, rendered the way Roblox draws them (single-sided faces): the pitched house from a low
front angle and from the gable side, the lamp post top, and a cafe table with its setting.
Run: blender --background --python render_fix1.py"""
import bpy, os, traceback
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_fix1_log.txt")


def imp(path, offset=(0, 0, 0)):
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=path, forward_axis="NEGATIVE_Z", up_axis="Y")
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        o.location = o.location + Vector(offset)
    return new


def shot(name, eye, at, w=1200, h=700, lens=40):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = w, h
    cam = sc.camera
    cam.data.lens = lens
    cam.location = Vector(eye)
    cam.rotation_euler = (Vector(at) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, name)
    bpy.ops.render.render(write_still=True)


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.show_backface_culling = True                     # Roblox culls back faces: inward-facing walls vanish here too
    sh.background_type = "VIEWPORT"; sh.background_color = (0.80, 0.85, 0.92)
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo

    # Blender coords after import: kit (x, y, z) -> (x, -z, y). House front (kit -z) faces +Y here.
    house = imp(os.path.join(D, "townhouse_b.obj"))
    shot("fix2_house_lowfront.png", (-12, 26, 1.6), (0, 0, 17), lens=30)      # low, from the front-left, looking up at the roof
    shot("fix2_house_gable.png", (-60, 26, 10), (0, 0, 16), lens=35)         # from the side: gable end must be a solid wall
    shot("fix2_house_gable_low.png", (-30, -18, 1.5), (0, 0, 21), lens=30)   # low from the back-left, looking up at the gable
    shot("fix2_house_back_low.png", (12, -26, 1.6), (0, 0, 17), lens=32)     # low from the back-right
    for o in house: bpy.data.objects.remove(o)

    with open(LOG, "a") as f:
        f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f:
        f.write(traceback.format_exc())
