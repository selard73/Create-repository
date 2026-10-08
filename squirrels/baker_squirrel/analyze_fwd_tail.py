import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

pos_x = [v for v in verts if v.x > 0.10 and v.z >= 1.40]
fwd = [v for v in pos_x if v.y < 0.05]

# Let\'s see all vertices with X > 0.20 in fwd:
print('X > 0.20 in fwd:')
for v in fwd:
    if v.x > 0.20:
        print(f'  ({v.x:.3f}, {v.y:.3f}, {v.z:.3f})')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/fwd_check.txt', 'w') as out:
    for v in fwd:
        if v.x > 0.20:
            out.write(f'({v.x:.3f}, {v.y:.3f}, {v.z:.3f})\n')
