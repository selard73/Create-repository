import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in mesh.vertex_groups}

# Let\'s check every vertex in the mesh:
# We want to know:
# Which vertices have Head > 0?
# Do ANY of those vertices have weight in Tail1, Tail2, Chest, Root, or Neck?
# And which vertices have Tail1 or Tail2 > 0? Where are they located in space?

tail_verts = []
for v in mesh.data.vertices:
    w_t1 = 0
    w_t2 = 0
    for g in v.groups:
        if g.group == vgs.get('Tail1'): w_t1 = g.weight
        if g.group == vgs.get('Tail2'): w_t2 = g.weight
    if (w_t1 + w_t2) > 0.001:
        tail_verts.append((v.index, v.co.x, v.co.y, v.co.z, w_t1, w_t2))

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/tail_dump.txt', 'w') as out:
    out.write(f'Total tail verts: {len(tail_verts)}\n')
    # find min and max X, Y, Z of tail verts:
    xs = [t[1] for t in tail_verts]
    ys = [t[2] for t in tail_verts]
    zs = [t[3] for t in tail_verts]
    out.write(f'Tail X range: {min(xs):.3f} .. {max(xs):.3f}\n')
    out.write(f'Tail Y range: {min(ys):.3f} .. {max(ys):.3f}\n')
    out.write(f'Tail Z range: {min(zs):.3f} .. {max(zs):.3f}\n')
    # Are any tail verts near face? (Y < 0 or X < 0.2)
    near_face = [t for t in tail_verts if t[2] < 0.1 or t[1] < 0.2]
    out.write(f'Tail verts with Y < 0.1 or X < 0.2: {len(near_face)}\n')
    for t in near_face[:20]:
        out.write(f'  idx {t[0]}: ({t[1]:.3f}, {t[2]:.3f}, {t[3]:.3f}) -> T1={t[4]:.2f}, T2={t[5]:.2f}\n')
