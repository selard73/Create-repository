import bpy, math
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sh = sc.display.shading
sh.light = "STUDIO"
sh.color_type = "TEXTURE"
sh.show_shadows = False
sh.background_type = "VIEWPORT"
sh.background_color = (0.86, 0.88, 0.92)

for o in list(bpy.data.objects):
    if o.type == "CAMERA":
        bpy.data.objects.remove(o)

cam = bpy.data.cameras.new("Cam")
camo = bpy.data.objects.new("Cam", cam)
sc.collection.objects.link(camo)
sc.camera = camo
cam.lens = 70

# Nose is around (-0.55, 0.0, 1.65)
ctr = Vector((-0.55, 0.0, 1.65))
# Camera view looking at the nose from side-front
camo.location = ctr + Vector((-1.0, -1.2, 0.3))
camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()

sc.render.resolution_x, sc.render.resolution_y = 800, 800
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\nose_closeup.png"
bpy.ops.render.render(write_still=True)
print("NOSE_RENDER_WORKBENCH_DONE")
