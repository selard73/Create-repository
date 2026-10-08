import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Look at vertices on +X side of face (X > 0.0, Z > 1.4):
pos_x_head = [v for v in mesh.data.vertices if v.co.x > 0.0 and v.co.z > 1.4]
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pos_x_weights.txt', 'w') as out:
    for v in pos_x_head:
        w_dict = {name: 0.0 for name in vgs}
        for g in v.groups:
            for name, idx in vgs.items():
                if g.group == idx:
                    w_dict[name] = g.weight
        w_str = ', '.join(f'{k}:{v:.2f}' for k, v in w_dict.items() if v > 0.01)
        out.write(f'({v.co.x:.2f}, {v.co.y:.2f}, {v.co.z:.2f}) -> {w_str}\n')
