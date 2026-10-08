import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.faces.ensure_lookup_table()

# Shortest path from head_seed to tail_seed:
head_seed = min(bm.verts, key=lambda v: (v.co - Vector((0, -0.7, 1.6))).length)
tail_seed = min(bm.verts, key=lambda v: (v.co - Vector((0.8, 0.6, 1.8))).length)

prev = {head_seed: None}
queue = [head_seed]
while queue:
    curr = queue.pop(0)
    if curr == tail_seed:
        break
    for e in curr.link_edges:
        o = e.other_vert(curr)
        if o not in prev:
            prev[o] = curr
            queue.append(o)

path = []
curr = tail_seed
while curr:
    path.append(curr)
    curr = prev.get(curr)
path.reverse()

print(f'Path length: {len(path)}')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/path.txt', 'w') as out:
    for v in path:
        out.write(f'({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})\n')
