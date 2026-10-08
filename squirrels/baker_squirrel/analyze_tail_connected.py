import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()

# Tail is on +X, +Y side.
# Let\'s look at the furthest back, highest, and rightmost parts of the tail:
# Seed 1: extreme tail tip / back: (0.80, 0.60, 1.80)
# Let\'s see all faces / vertices connected to this seed that stay within the tail volume!
# Where does the tail touch the head/ear in the original geometry?
# In Blender, let\'s calculate the closest distance between:
# Set A: Head verts (X < 0.20, Z > 1.50)
# Set B: Tail verts (X > 0.60, Y > 0.30)
# Are there mesh bridges / connecting triangles between the head and tail?

head_verts = {v for v in bm.verts if v.co.x < 0.20 and v.co.z > 1.50}
tail_verts = {v for v in bm.verts if v.co.x > 0.60 and v.co.y > 0.30}

# Shortest path in edge graph from any head vert to any tail vert:
queue = [(v, 0) for v in head_verts]
visited = {v: 0 for v in head_verts}
min_dist = 999
bridge_verts = []

for v, d in queue:
    if v in tail_verts:
        min_dist = d
        break
    for e in v.link_edges:
        o = e.other_vert(v)
        if o not in visited:
            visited[o] = d + 1
            queue.append((o, d + 1))

print(f'Shortest edge distance from head to tail: {min_dist}')

# Let\'s inspect vertices with 0.20 <= X <= 0.50 and 1.50 <= Z <= 2.00:
# How many faces bridge across this region?
border_verts = [v for v in bm.verts if 0.20 <= v.co.x <= 0.55 and 0.0 <= v.co.y <= 0.25 and 1.50 <= v.co.z <= 2.00]
print(f'Border region verts: {len(border_verts)}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/bridge_info.txt', 'w') as out:
    out.write(f'Shortest edge dist: {min_dist}\n')
    out.write(f'Border verts: {len(border_verts)}\n')
    for v in border_verts:
        out.write(f'  idx {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})\n')
