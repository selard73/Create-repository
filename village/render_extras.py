import bpy, os, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__)); LOG = os.path.join(D, "render_extras_log.txt")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(D, "village_extra.obj"), forward_axis="NEGATIVE_Z", up_axis="Y")
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL"; sh.show_shadows = True; sh.show_cavity = True
    sh.background_type = "VIEWPORT"; sh.background_color = (0.75, 0.78, 0.82); sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1000, 700; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 50
    ctr = Vector((4.5, 0, 1.8)); camo.location = ctr + Vector((6.0, -12.0, 4.0))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Z").to_euler()
    sc.render.filepath = os.path.join(D, "extras_check.png"); bpy.ops.render.render(write_still=True)
    with open(LOG, "a") as f: f.write("RENDER_DONE\n")
except Exception:
    with open(LOG, "a") as f: f.write(traceback.format_exc())
