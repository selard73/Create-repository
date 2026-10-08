"""Render the forest kit in a row (WORKBENCH, material colours) for a quick look. Run: blender --background --python render_kit.py"""
import bpy, os, math, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "render_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    names = ["townhouse_a", "townhouse_b", "townhouse_c", "cafe_table", "parasol", "lamp_post", "planter", "fountain", "bollards", "shop_sign", "bench", "bicycle", "bridge", "plane_tree"]
    x = 0.0
    for n in names:
        before = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=os.path.join(D, n + ".obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
        new = [o for o in bpy.data.objects if o not in before]
        w = max((o.dimensions.x for o in new), default=4) + 3
        for o in new: o.location.x += x + w / 2
        x += w
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.55, 0.62, 0.72)
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 2400, 800; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"; cam.ortho_scale = x + 4
    ctr = Vector((x / 2, 0, 5.5))
    camo.location = ctr + Vector((0, 80, 22))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Z").to_euler()
    sc.render.filepath = os.path.join(D, "village_preview.png"); bpy.ops.render.render(write_still=True)
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
