import bpy
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
sh.background_color = (1.0, 1.0, 1.0)

for o in list(bpy.data.objects):
    if o.type == "CAMERA":
        bpy.data.objects.remove(o)

cam = bpy.data.cameras.new("Cam")
camo = bpy.data.objects.new("Cam", cam)
sc.collection.objects.link(camo)
sc.camera = camo
cam.type = 'ORTHO'
cam.ortho_scale = 3.0

# Side view of the squirrel (looking from +Y along -Y so head points left)
# In prep_squirrel.py: front view is looking at the front of the squirrel (which for this model is side view of bike)
camo.location = Vector((0.0, -5.0, 1.2))
camo.rotation_euler = (Vector((0.0, 0.0, 1.2)) - camo.location).to_track_quat("-Z", "Y").to_euler()

sc.render.resolution_x, sc.render.resolution_y = 800, 800
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\ref_front_after_fix.png"
bpy.ops.render.render(write_still=True)
print("REF_FRONT_AFTER_FIX_DONE")
