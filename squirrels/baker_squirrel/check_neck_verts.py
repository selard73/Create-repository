import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Let\'s check which vertices have Neck weight:
neck_verts = []
for v in mesh.data.vertices:
    for g in v.groups:
        if g.group == vgs.get('Neck') and g.weight > 0.01:
            neck_verts.append((v.index, v.co.x, v.co.y, v.co.z, g.weight))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/neck_dump.txt', 'w') as out:
    out.write(f'Neck verts count: {len(neck_verts)}\n')
    for v in neck_verts:
        out.write(f'idx {v[0]}: ({v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f}) -> Neck={v[4]:.2f}\n')
