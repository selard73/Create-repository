import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()

# The rolling pin is a cylindrical wooden pin held in his hand.
# The lowest point of the rolling pin handle is around X=-0.75, Y=-0.25, Z=0.6..0.8.
# Let\'s find a seed vertex on the pin handle that is 100% on the pin:
pin_seeds = [v for v in bm.verts if v.co.x < -0.75 and -0.4 < v.co.y < -0.1 and 0.8 < v.co.z < 1.1]
print('Pin seed count:', len(pin_seeds))

# Check UV coordinates or material texture color of pin vs squirrel fur!
# The rolling pin texture has wood grain and white flour on it.
# Squirrel cheek has white/brown fur!
# Let\'s inspect image texture of the material:
img = [n for n in mesh.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0].image
uv_layer = bm.loops.layers.uv.active

# For each face containing pin seeds, what are the UVs?
uvs = []
for v in pin_seeds[:5]:
    for l in v.link_loops:
        uv = l[uv_layer].uv
        uvs.append((uv.x, uv.y))
print('Pin UV samples:', uvs[:5])

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pin_bmesh.txt', 'w') as out:
    out.write(f'Seeds: {len(pin_seeds)}\n')
    for u in uvs[:10]:
        out.write(f'UV: {u[0]:.3f}, {u[1]:.3f}\n')
