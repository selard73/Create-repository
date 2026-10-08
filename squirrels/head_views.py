"""Close-up renders of a prepped squirrel's head. Run: blender -b --python head_views.py -- <blend> <out_prefix> <cx> <cy> <cz> <ortho>"""
import bpy, sys, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
BL, OUT = argv[0], argv[1]; C = Vector((float(argv[2]), float(argv[3]), float(argv[4]))); OS = float(argv[5])
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    for o in list(bpy.data.objects):
        if o.name != "Squirrel": bpy.data.objects.remove(o)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False; sh.show_cavity = True
    sc.render.resolution_x = sc.render.resolution_y = 700; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); co = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(co); sc.camera = co
    cam.type = "ORTHO"; cam.ortho_scale = OS
    for name, off in {"front": (0, -10, 0), "left": (-10, 0, 0), "right": (10, 0, 0), "top": (0, -0.01, 10), "q34r": (7, -7, 1.5), "q34l": (-7, -7, 1.5)}.items():
        co.location = C + Vector(off)
        co.rotation_euler = (C - co.location).to_track_quat("-Z", "Y" if name != "top" else "Y").to_euler()
        sc.render.filepath = f"{OUT}_{name}.png"; bpy.ops.render.render(write_still=True)
    open(OUT + "_done.txt", "w").write("ok")
except Exception:
    open(OUT + "_done.txt", "w").write(traceback.format_exc())
