import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.mode_set(mode='EDIT')

bm = bmesh.from_edit_mesh(mesh.data)
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()
bm.faces.ensure_lookup_table()

# Select edges that bridge between Ear/Head (Y < 0.08, X in 0.2..0.55, Z in 1.45..2.1)
# and Tail (Y > 0.18, X in 0.2..0.55, Z in 1.45..2.1):
bridging_edges = []
for e in bm.edges:
    v1, v2 = e.verts
    c1, c2 = v1.co, v2.co
    # Both in the bounding region:
    if 0.18 <= c1.x <= 0.60 and 0.18 <= c2.x <= 0.60 and 1.40 <= c1.z <= 2.15 and 1.40 <= c2.z <= 2.15:
        # Crosses the Y seam between ear and tail:
        if (c1.y < 0.10 and c2.y > 0.10) or (c2.y < 0.10 and c1.y > 0.10):
            bridging_edges.append(e)

print(f'Bridging edges count: {len(bridging_edges)}')
for e in bridging_edges:
    e.select = True

# Also find faces in the junction crease:
# In Meshy models, the tail and ear are connected by a thin webbing/crease of faces.
# If we delete the webbing faces or split the edges, they become 2 completely independent surfaces!
# Let\'s see if bmesh.ops.split_edges can rip them:
res = bmesh.ops.split_edges(bm, edges=bridging_edges)
bmesh.update_edit_mesh(mesh.data)
bpy.ops.object.mode_set(mode='OBJECT')

print('Split edges successfully!')
bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_split.blend')
