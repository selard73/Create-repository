import bpy, sys, os
argv = sys.argv[sys.argv.index("--") + 1:]
D = argv[0]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(D, "broomcart.fbx"))
for o in bpy.data.objects:
    o.scale = (o.scale[0] * 100, o.scale[1] * 100, o.scale[2] * 100)
from mathutils import Vector
sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.background_type = "VIEWPORT"; sh.background_color = (0.93, 0.94, 0.95)
sc.render.resolution_x = sc.render.resolution_y = 700; sc.view_settings.view_transform = "Standard"
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
for tag, pos in (("front", (0.6, -6.2, 1.8)), ("q34", (4.4, -4.6, 2.6))):
    cam.location = Vector(pos); d = Vector((0, 0, 1.1)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(D, f"light_{tag}.png"); bpy.ops.render.render(write_still=True)
open(os.path.join(D, "relight_done.txt"), "w").write("ok")
