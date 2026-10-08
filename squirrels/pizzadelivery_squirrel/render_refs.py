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
cam.type = 'ORTHO'; cam.ortho_scale = 3.2
sc.render.resolution_x, sc.render.resolution_y = 800, 800

# 1. Front view (looking at squirrel's face and front of scooter from -Y)
camo.location = Vector((0.0, -5.0, 1.2))
camo.rotation_euler = (Vector((0.0, 0.0, 1.2)) - camo.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\ref_front.png"
bpy.ops.render.render(write_still=True)

# 2. Side view (looking at bike profile from -X)
camo.location = Vector((-5.0, 0.0, 1.2))
camo.rotation_euler = (Vector((0.0, 0.0, 1.2)) - camo.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\ref_side.png"
bpy.ops.render.render(write_still=True)

# 3. Top view (looking down from +Z)
camo.location = Vector((0.0, 0.0, 6.0))
camo.rotation_euler = (0, 0, 0)
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\ref_top.png"
bpy.ops.render.render(write_still=True)

print("CANONICAL_REFS_RENDERED")
