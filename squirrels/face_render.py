import bpy, sys, os
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
D, N, TEX, OUT = argv[0], argv[1], argv[2], argv[3]
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, N + ".blend"))
sq = bpy.data.objects["Squirrel"]
for o in list(bpy.data.objects):
    if o != sq: bpy.data.objects.remove(o)
tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
tex.image = bpy.data.images.load(TEX)
sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
sh = sc.display.shading; sh.light = "FLAT"; sh.color_type = "TEXTURE"
sh.background_type = "VIEWPORT"; sh.background_color = (0.9, 0.9, 0.92)
sc.render.resolution_x = sc.render.resolution_y = 600; sc.view_settings.view_transform = "Standard"
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.lens = 120
ctr = Vector((0.0, -0.3, 1.93)); cam.location = ctr + Vector((0.05, -3.2, 0.1))
cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = OUT; bpy.ops.render.render(write_still=True)
