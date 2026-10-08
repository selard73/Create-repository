import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Look at vertices at X in 0.20 .. 0.50, Y in -0.10 .. 0.25, Z in 1.45 .. 2.20:
border_verts = []
for v in mesh.data.vertices:
    co = v.co
    if 0.15 <= co.x <= 0.55 and -0.20 <= co.y <= 0.25 and 1.40 <= co.z <= 2.25:
        w_dict = {name: 0.0 for name in vgs}
        for g in v.groups:
            for name, idx in vgs.items():
                if g.group == idx:
                    w_dict[name] = g.weight
        border_verts.append((v.index, co.x, co.y, co.z, w_dict))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/border.txt', 'w') as out:
    out.write(f'Border verts count: {len(border_verts)}\n')
    for b in border_verts:
        w_str = ', '.join(f'{k}:{v:.2f}' for k, v in b[4].items() if v > 0.01)
        out.write(f'idx {b[0]}: ({b[1]:.3f}, {b[2]:.3f}, {b[3]:.3f}) -> {w_str}\n')
