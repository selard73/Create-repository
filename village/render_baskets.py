"""Preview: three village bicycles with the basket fillers seated in their baskets, in the builder's colours.
Run: blender --background --python render_baskets.py"""
import bpy, os, traceback
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_baskets_log.txt")
COL = {"Frame": (70, 90, 140), "Wheel": (50, 50, 50), "Bench": (140, 110, 85), "Leaf": (100, 160, 90),
       "Bread": (226, 172, 92), "Trim": (250, 247, 238), "Lavender": (160, 120, 210), "Flour": (248, 236, 205)}
FLOWERS = [(230, 90, 120), (240, 200, 70), (220, 70, 60), (200, 120, 220)]


def colour_for(name):
    base = name.split(".")[0]
    if base.startswith("Flower"):
        digits = "".join(ch for ch in base if ch.isdigit()) or "1"
        return FLOWERS[(int(digits) - 1) % len(FLOWERS)]
    for k, v in COL.items():
        if base.startswith(k):
            return v
    return (200, 200, 200)


def imp(path, offset):
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=path, forward_axis="NEGATIVE_Z", up_axis="Y")
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        o.location = Vector(offset)
        r, g, b = colour_for(o.name)
        m = bpy.data.materials.new(o.name + "_m"); m.diffuse_color = (r / 255, g / 255, b / 255, 1)
        o.data.materials.clear(); o.data.materials.append(m)
    return new


try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    fills = ["basket_flowers", "basket_bread", "basket_mixed"]
    for i, fill in enumerate(fills):
        y = -3.2 * i                       # obj +z -> blender -y; space the bikes apart across their width
        imp(os.path.join(D, "bicycle.obj"), (0, y, 0))
        imp(os.path.join(D, f"{fill}.obj"), (1.75, y, 3.0))   # basket floor top on the bicycle kit
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.80, 0.83, 0.87)
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    # overview of all three bikes
    sc.render.resolution_x, sc.render.resolution_y = 1400, 800
    cam.lens = 50
    ctr = Vector((0.6, -3.2, 1.9)); camo.location = ctr + Vector((9.0, 6.5, 5.0))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, "baskets_overview.png"); bpy.ops.render.render(write_still=True)
    # close-ups of each basket from the front-side, the way a player on the sidewalk sees it
    sc.render.resolution_x, sc.render.resolution_y = 700, 700
    cam.lens = 60
    for i, fill in enumerate(fills):
        c = Vector((1.75, -3.2 * i, 3.6)); camo.location = c + Vector((3.2, 2.6, 1.6))
        camo.rotation_euler = (c - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(D, f"{fill}_close.png"); bpy.ops.render.render(write_still=True)
    with open(LOG, "a") as f:
        f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f:
        f.write(traceback.format_exc())
