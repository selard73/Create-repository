import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

# In Edit mode, let\'s see if the mesh has separate connected components / mesh islands!
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='DESELECT')

# Or in object mode using bmesh
import bmesh
bm = bmesh.new()
bm.from_mesh(mesh.data)

# Find connected islands
islands = []
visited = set()
for v in bm.verts:
    if v.index not in visited:
        island = []
        queue = [v]
        visited.add(v.index)
        while queue:
            curr = queue.pop()
            island.append(curr)
            for edge in curr.link_edges:
                other = edge.other_vert(curr)
                if other.index not in visited:
                    visited.add(other.index)
                    queue.append(other)
        islands.append(island)

print(f'Total mesh islands: {len(islands)}')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/islands.txt', 'w') as out:
    out.write(f'Total islands: {len(islands)}\n')
    for i, isl in enumerate(islands):
        xs = [v.co.x for v in isl]
        ys = [v.co.y for v in isl]
        zs = [v.co.z for v in isl]
        out.write(f'Island {i}: {len(isl)} verts | X: {min(xs):.2f}..{max(xs):.2f}, Y: {min(ys):.2f}..{max(ys):.2f}, Z: {min(zs):.2f}..{max(zs):.2f}\n')
