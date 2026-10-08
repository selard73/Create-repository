import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

left_foot = [v for v in verts if v.x > 0.05 and v.z < 0.15]
right_foot = [v for v in verts if v.x < -0.05 and v.z < 0.15]

min_left = min(left_foot, key=lambda v: v.z)
min_right = min(right_foot, key=lambda v: v.z)

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/feet.txt', 'w') as out:
    out.write(f'Left: {min_left.x:.4f} {min_left.y:.4f} {min_left.z:.4f}\n')
    out.write(f'Right: {min_right.x:.4f} {min_right.y:.4f} {min_right.z:.4f}\n')
    out.write(f'Center: {(min_left.x + min_right.x)/2:.4f} {(min_left.y + min_right.y)/2:.4f}\n')
