import bpy
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sh = sc.display.shading
sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
sh.background_type = "VIEWPORT"; sh.background_color = (1.0, 1.0, 1.0)

for o in list(bpy.data.objects):
    if o.type == "CAMERA":
        bpy.data.objects.remove(o)

cam = bpy.data.cameras.new("Cam")
camo = bpy.data.objects.new("Cam", cam)
sc.collection.objects.link(camo); sc.camera = camo
cam.type = 'PERSP'; cam.lens = 75

# Looking straight into his face from the front (-X looking +X)
camo.location = Vector((-2.5, 0.0, 1.65))
camo.rotation_euler = (Vector((0.0, 0.0, 1.65)) - camo.location).to_track_quat("-Z", "Y").to_euler()

sc.render.resolution_x, sc.render.resolution_y = 800, 800
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\face_front.png"
bpy.ops.render.render(write_still=True)
print("FACE_FRONT_RENDERED")
