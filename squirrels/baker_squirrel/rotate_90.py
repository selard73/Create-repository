
import bpy, math
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

# Rotate mesh -90 degrees around Z so facing (-X) becomes (-Y)
# Wait, let's verify direction:
# If current face is at -X, rotating +90 around Z:
# (-1, 0) rotated by +90 deg -> (0, -1) which is -Y!
# Let's check: cos(90)*(-1) - sin(90)*(0) = 0
#             sin(90)*(-1) + cos(90)*(0) = -1 -> (0, -1) = -Y! Exactly +90 degrees!
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.transform.rotate(value=math.radians(90), orient_axis='Z')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Save blend
bpy.ops.wm.save_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
print('ROTATED_AND_SAVED')
