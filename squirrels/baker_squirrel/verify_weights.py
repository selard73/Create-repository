import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

sq = bpy.data.objects['Squirrel']
vgs = {vg.name: vg.index for vg in sq.vertex_groups}

tail_on_head = []
for v in sq.data.vertices:
    co = v.co
    if co.z >= 1.48 and co.y <= 0.15 and not (co.x < -0.42 and co.y < -0.10):
        for g in v.groups:
            if g.group in (vgs.get('Tail1'), vgs.get('Tail2')) and g.weight > 0.001:
                tail_on_head.append((v.index, co.x, co.y, co.z, g.weight))

print('Tail on head count:', len(tail_on_head))
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/clean_status.txt', 'w') as out:
    out.write(f'Tail on head count: {len(tail_on_head)}\n')
