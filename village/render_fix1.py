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
    house = imp(os.path.join(D, "townhouse_d.obj"))
    shot("fix1_house_lowfront.png", (-16, 30, 1.6), (0, 0, 22), lens=32)      # low, from the front-left, looking up at the roof
    shot("fix1_house_gable.png", (-70, 30, 12), (0, 0, 24), lens=35)         # from the side: gable end must be a solid wall
    shot("fix1_house_gable_low.png", (-34, -20, 1.5), (0, 0, 30), lens=30)   # low from the back-left, looking up at the gable
    shot("fix1_house_back_low.png", (14, -30, 1.6), (0, 0, 22), lens=32)     # low from the back-right
    for o in house: bpy.data.objects.remove(o)

    imp(os.path.join(D, "lamp_post_v2.obj"))
    shot("fix1_lamp_top.png", (4, -5, 7.5), (0, 0, 9.0), w=700, h=900, lens=60)
    shot("fix1_lamp_below.png", (3.5, -4.5, 3.0), (0, 0, 9.3), w=700, h=900, lens=55)   # from a player's eye height
    for o in [o for o in bpy.data.objects if o.type == "MESH"]: bpy.data.objects.remove(o)

    imp(os.path.join(D, "cafe_table.obj"))
    imp(os.path.join(D, "table_setting.obj"), (0, 0, 2.3 - 0.6))             # kit y 0 sits 0.6 below the table top
    shot("fix1_table.png", (4.2, -4.0, 4.6), (0, 0, 2.4), w=1000, h=800, lens=45)
    shot("fix1_table_low.png", (5.5, -1.5, 2.9), (0, 0, 2.5), w=1000, h=600, lens=50)
    with open(LOG, "a") as f:
        f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f:
        f.write(traceback.format_exc())
