import bpy, bmesh
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

# Vertices to fix:
# 1. Top whisker spike (3737, 1917, and nearby ridge vertices)
v3737 = [v for v in bm.verts if v.index == 3737][0]
base_top = (Vector((-0.6407, 0.0032, 1.7947)) + Vector((-0.6245, -0.0030, 1.7966)) + Vector((-0.6629, -0.0013, 1.7911))) / 3.0
v3737.co = base_top

for v in bm.verts:
    if v.co.z > 1.73 and abs(v.co.y) < 0.04 and v.co.x < -0.58:
        v.co.x = -0.57

# 2. Front whisker protrusion on the dark nose button:
# Front whiskers stick out to x = -0.74 between z 1.60 and 1.68 near y = 0
# The natural nose curve has x = -0.58
for v in bm.verts:
    if 1.60 <= v.co.z <= 1.68 and abs(v.co.y) < 0.06 and v.co.x < -0.60:
        # Move back to smooth dome of the nose button
        v.co.x = -0.575

bm.to_mesh(sq.data)
bm.free()
sq.data.update()

# Save the updated blend file
bpy.ops.wm.save_mainfile(filepath=blend_path)
print("SAVED_FIXED_BLEND")

# Set up render
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

# Nose close-up
ctr = Vector((-0.55, 0.0, 1.65))
camo.location = ctr + Vector((-1.0, -1.2, 0.3))
camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()

sc.render.resolution_x, sc.render.resolution_y = 800, 800
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\nose_fixed_preview.png"
bpy.ops.render.render(write_still=True)

# Also render side profile to verify front curve
camo.location = ctr + Vector((0.0, -2.0, 0.0))
camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\nose_profile_preview.png"
bpy.ops.render.render(write_still=True)

print("ALL_PREVIEWS_RENDERED")
