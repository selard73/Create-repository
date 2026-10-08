import bpy, math
from mathutils import Vector, Matrix

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

# Rotate 90 degrees around Z so front faces -Y
sq.rotation_euler = (0, 0, math.radians(90))
bpy.context.view_layer.objects.active = sq
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

# Check new bounding box
pts = [v.co for v in sq.data.vertices]
min_x, max_x = min(p.x for p in pts), max(p.x for p in pts)
min_y, max_y = min(p.y for p in pts), max(p.y for p in pts)
min_z, max_z = min(p.z for p in pts), max(p.z for p in pts)
print(f"New bbox: x=({min_x:.2f}, {max_x:.2f}), y=({min_y:.2f}, {max_y:.2f}), z=({min_z:.2f}, {max_z:.2f})")

bpy.ops.wm.save_mainfile(filepath=blend_path)
print("ROTATED_AND_SAVED")
