import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Let\'s see all vertices with X > 0.15, Z > 1.4:
# How many are in Tail2?
tail2_high = [v for v in mesh.data.vertices if v.co.x > 0.15 and v.co.z > 1.4 and any(g.group == vgs['Tail2'] for g in v.groups)]
print(f'Tail2 high verts: {len(tail2_high)}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/tail2_high.txt', 'w') as out:
    for v in tail2_high:
        out.write(f'idx {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})\n')
