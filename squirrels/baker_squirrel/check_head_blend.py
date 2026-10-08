import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Let\'s check every single vertex in the mesh that has Head > 0 or Neck > 0:
head_neck_verts = []
for v in mesh.data.vertices:
    w_head = 0
    w_neck = 0
    w_chest = 0
    w_tail1 = 0
    w_tail2 = 0
    w_root = 0
    for g in v.groups:
        if g.group == vgs.get('Head'): w_head = g.weight
        if g.group == vgs.get('Neck'): w_neck = g.weight
        if g.group == vgs.get('Chest'): w_chest = g.weight
        if g.group == vgs.get('Tail1'): w_tail1 = g.weight
        if g.group == vgs.get('Tail2'): w_tail2 = g.weight
        if g.group == vgs.get('Root'): w_root = g.weight
    if w_head > 0 or w_neck > 0:
        head_neck_verts.append((v.index, v.co.x, v.co.y, v.co.z, w_head, w_neck, w_chest, w_tail1, w_tail2, w_root))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/head_neck_dump.txt', 'w') as out:
    out.write(f'Total head/neck verts: {len(head_neck_verts)}\n')
    # Check if any have non-zero chest, tail, root:
    dirty = [v for v in head_neck_verts if v[6] > 0.001 or v[7] > 0.001 or v[8] > 0.001 or v[9] > 0.001]
    out.write(f'Dirty head/neck verts (sharing chest/tail/root): {len(dirty)}\n')
    for d in dirty[:20]:
        out.write(f'  idx {d[0]}: ({d[1]:.2f}, {d[2]:.2f}, {d[3]:.2f}) -> H={d[4]:.2f}, N={d[5]:.2f}, C={d[6]:.2f}, T1={d[7]:.2f}, T2={d[8]:.2f}\n')
