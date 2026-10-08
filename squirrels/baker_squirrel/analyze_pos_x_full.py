import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

pos_x = [v for v in verts if v.x > 0.10 and v.z >= 1.40]
# Split into forward (Y < 0.05) vs backward (Y >= 0.05):
fwd = [v for v in pos_x if v.y < 0.05]
bwd = [v for v in pos_x if v.y >= 0.05]

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/split.txt', 'w') as out:
    out.write(f'Forward (Y < 0.05) count: {len(fwd)}\n')
    for v in fwd:
        out.write(f'  ({v.x:.3f}, {v.y:.3f}, {v.z:.3f})\n')
    out.write(f'Backward (Y >= 0.05) count: {len(bwd)}\n')
