import bpy, os, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__)); LOG = os.path.join(D, "render_river_log.txt")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "river.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    for m in bpy.data.materials: m.use_backface_culling = True
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "FLAT"; sh.color_type = "MATERIAL"; sh.show_backface_culling = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.2, 0.8, 0.2); sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"; cam.ortho_scale = 420
    # top-down over a stretch of bends (blender: z up after import, river runs along blender Y)
    camo.location = Vector((0, 220, 200)); camo.rotation_euler = (0, 0, 0)
    sc.render.filepath = os.path.join(D, "river_check.png"); bpy.ops.render.render(write_still=True)
    with open(LOG, "a") as f: f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f: f.write(traceback.format_exc())
