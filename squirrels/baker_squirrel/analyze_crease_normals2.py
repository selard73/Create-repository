import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.faces.ensure_lookup_table()

del_faces = []
for f in bm.faces:
    c = f.calc_center_median()
    if 0.20 <= c.x <= 0.55 and 0.04 <= c.y <= 0.22 and 1.45 <= c.z <= 2.05:
        if f.normal.y < -0.30:
            del_faces.append(f)

print(f'Deleting {len(del_faces)} webbing faces...')
bmesh.ops.delete(bm, geom=del_faces, context='FACES')

head_seed = min(bm.verts, key=lambda v: (v.co - Vector((0, -0.7, 1.6))).length)
tail_seed = min(bm.verts, key=lambda v: (v.co - Vector((0.8, 0.6, 1.8))).length)

visited = {head_seed}
queue = [head_seed]
while queue:
    curr = queue.pop()
    for e in curr.link_edges:
        o = e.other_vert(curr)
        if o not in visited:
            visited.add(o)
            queue.append(o)

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/reach.txt', 'w') as out:
    out.write(f'Reachable: {tail_seed in visited}\n')
    out.write(f'Visited count: {len(visited)} / {len(bm.verts)}\n')
