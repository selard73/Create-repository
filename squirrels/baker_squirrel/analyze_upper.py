import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

sq = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in sq.vertex_groups}

head_region = []
for v in sq.data.vertices:
    co = v.co
    if co.z > 1.35:
        weights = {name: 0.0 for name in vgs}
        for g in v.groups:
            for name, idx in vgs.items():
                if g.group == idx:
                    weights[name] = g.weight
        if weights.get('Chest', 0) > 0.01 or weights.get('Root', 0) > 0.01 or weights.get('Tail1', 0) > 0.01 or weights.get('Tail2', 0) > 0.01:
            head_region.append((v.index, co.x, co.y, co.z, weights))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/upper_weights.txt', 'w') as out:
    out.write(f'Total verts with Z > 1.35 having non-head weights: {len(head_region)}\n')
    for row in head_region:
        w_str = ', '.join(f'{k}:{v:.2f}' for k, v in row[4].items() if v > 0.01)
        out.write(f'idx {row[0]}: ({row[1]:.2f}, {row[2]:.2f}, {row[3]:.2f}) -> {w_str}\n')
