import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg for vg in mesh.vertex_groups}

chest_upper = [v for v in mesh.data.vertices if v.co.z >= 1.50 and any(g.group == vgs['Chest'].index and g.weight > 0.1 for g in v.groups)]
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/chest_upper.txt', 'w') as out:
    out.write(f'Chest upper count: {len(chest_upper)}\n')
    for v in chest_upper[:20]:
        out.write(f'  idx {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})\n')
