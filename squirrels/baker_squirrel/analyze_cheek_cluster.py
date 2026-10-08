import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Look at (0.471, 0.017, 1.519) and (0.548, 0.097, 1.530)
# What is around (0.47, 0.02, 1.52)?
pts = [v for v in verts if (v.x - 0.47)**2 + (v.y - 0.02)**2 + (v.z - 1.52)**2 < 0.25**2]
print(f'Cluster around (0.47, 0.02, 1.52): {len(pts)} verts')
for p in pts:
    print(f'  ({p.x:.3f}, {p.y:.3f}, {p.z:.3f})')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/cluster.txt', 'w') as out:
    for p in pts:
        out.write(f'({p.x:.3f}, {p.y:.3f}, {p.z:.3f})\n')
