import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

neg_x = [v for v in verts if v.x < -0.4]
tail_high_y = [v for v in verts if v.y > 0.3]
near_tip = [v for v in verts if (v.x - (-0.78))**2 + (v.y - (-0.03))**2 + (v.z - 2.22)**2 < 0.2**2]

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/tail_info.txt', 'w') as out:
    out.write(f'X < -0.4 count: {len(neg_x)}\n')
    out.write(f'Y > 0.3 count: {len(tail_high_y)}\n')
    out.write(f'Y > 0.3 X range: {min(v.x for v in tail_high_y):.3f} .. {max(v.x for v in tail_high_y):.3f}\n')
    out.write(f'Near tip count: {len(near_tip)}\n')
    for v in near_tip[:5]:
        out.write(f'  {v.x:.3f}, {v.y:.3f}, {v.z:.3f}\n')
