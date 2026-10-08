import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()

# Let\'s inspect the faces connecting the ear/hat (X < 0.35, Y < 0.20, Z > 1.45)
# to the tail (X > 0.40, Y > 0.25, Z > 1.45).
# Can we slice the bridge cleanly, or can we separate them into distinct mesh surfaces?
# Or: what if we rip/disconnect the vertices along the seam between ear and tail?
# Let\'s see how many edges bridge across the seam!

# Seam plane:
# Ear is at Y < 0.12. Tail is at Y > 0.18.
# In between, for X in 0.20..0.55 and Z in 1.45..2.10:
# How thick is the connection?
seam_verts = [v for v in bm.verts if 0.22 < v.co.x < 0.55 and 0.05 < v.co.y < 0.22 and 1.50 < v.co.z < 2.05]
print(f'Seam verts: {len(seam_verts)}')

# Look at normals or vertex connectivity:
for v in seam_verts:
    print(f'v {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}) links: {len(v.link_edges)}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/seam.txt', 'w') as out:
    out.write(f'Seam verts: {len(seam_verts)}\n')
    for v in seam_verts:
        out.write(f'v {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}) links: {len(v.link_edges)}\n')
