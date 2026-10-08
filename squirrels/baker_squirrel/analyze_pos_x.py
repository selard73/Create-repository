import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

pos_x = [v for v in verts if v.x > 0.10 and v.z >= 1.40]
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pos_x.txt', 'w') as out:
    out.write(f'Count: {len(pos_x)}\n')
    for v in pos_x[:20]:
        out.write(f'idx {v.index}: ({v.x:.3f}, {v.y:.3f}, {v.z:.3f})\n')
