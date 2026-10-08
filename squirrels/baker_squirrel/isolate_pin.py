import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg for vg in mesh.vertex_groups}

# Let\'s inspect what vertices are in Chest with Z >= 1.50:
chest_upper = [v for v in mesh.data.vertices if v.co.z >= 1.50 and any(g.group == vgs['Chest'].index and g.weight > 0.1 for g in v.groups)]
print(f'Chest upper verts: {len(chest_upper)}')
for v in chest_upper[:10]:
    print(f'  idx {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})')
