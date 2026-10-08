import bpy, bmesh
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

# Smooth the bridge spike above the nose:
# The snout slope goes from (x=-0.48, z=1.85) down to (x=-0.56, z=1.65)
# In between, at z=1.78..1.84, anything poking out past x = -0.52 at y ~ 0 should be pulled back to the snout slope
for v in bm.verts:
    if 1.76 <= v.co.z <= 1.85 and abs(v.co.y) < 0.03 and v.co.x < -0.51:
        # Interpolate expected x along slope: at z=1.76 x=-0.54, at z=1.85 x=-0.48
        t = (v.co.z - 1.76) / (1.85 - 1.76)
        expected_x = -0.54 + t * (-0.48 - (-0.54))
        v.co.x = max(v.co.x, expected_x)

bm.to_mesh(sq.data)
bm.free()
sq.data.update()

bpy.ops.wm.save_mainfile(filepath=blend_path)

# Render ref_front again
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
sc.collection.objects.link(camo); sc.camera = camo
cam.type = 'ORTHO'
cam.ortho_scale = 3.0

camo.location = Vector((0.0, -5.0, 1.2))
camo.rotation_euler = (Vector((0.0, 0.0, 1.2)) - camo.location).to_track_quat("-Z", "Y").to_euler()

sc.render.resolution_x, sc.render.resolution_y = 800, 800
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\ref_front_after_fix.png"
bpy.ops.render.render(write_still=True)

# Also render nose close-up
cam.type = 'PERSP'; cam.lens = 70
ctr = Vector((-0.55, 0.0, 1.65))
camo.location = ctr + Vector((-1.0, -1.2, 0.3))
camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\nose_fixed_preview.png"
bpy.ops.render.render(write_still=True)

print("SMOOTH_BRIDGE_DONE")
