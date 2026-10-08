import bpy, os, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__)); LOG = os.path.join(D, "render_log2.txt")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "log_hollow.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "stump.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    for o in bpy.data.objects:
        if o.name.startswith("Wood") and o.dimensions.x < 6: o.location.x += 8
        if o.name.startswith("Rings") and o.dimensions.x < 4: o.location.x += 8
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.55, 0.62, 0.72); sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1200, 600; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 30
    ctr = Vector((4, 0, 1.4)); camo.location = ctr + Vector((-24, -22, 12))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Z").to_euler()
    sc.render.filepath = os.path.join(D, "log_check.png"); bpy.ops.render.render(write_still=True)
    with open(LOG, "a") as f: f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f: f.write(traceback.format_exc())
