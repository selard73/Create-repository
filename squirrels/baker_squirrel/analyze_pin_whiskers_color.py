import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.faces.ensure_lookup_table()
uv_layer = bm.loops.layers.uv.active

img = [n for n in mesh.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0].image
W, H = img.size
px = img.pixels[:]

def get_color(uv):
    u = min(max(uv.x, 0.0), 1.0)
    v = min(max(uv.y, 0.0), 1.0)
    x = min(int(u * W), W - 1)
    y = min(int(v * H), H - 1)
    idx = (y * W + x) * 4
    return (px[idx], px[idx+1], px[idx+2])

# Whiskers are pure white / light cream: (R > 0.8, G > 0.8, B > 0.8)
# Rolling pin is brown wood: (R ~ 0.5..0.6, G ~ 0.3..0.4, B ~ 0.15..0.25)
# Fur is dark brown / white belly.
# Let\'s sample the color of the spike vertices vs pin barrel:
spike_verts = [v for v in bm.verts if -0.85 <= v.co.x <= -0.65 and v.co.y < -0.40 and 1.60 <= v.co.z <= 1.80]
for v in spike_verts[:10]:
    loop = v.link_loops[0]
    col = get_color(loop[uv_layer].uv)
    print(f'v {v.index}: ({v.co.x:.2f}, {v.co.y:.2f}, {v.co.z:.2f}) -> RGB: ({col[0]:.2f}, {col[1]:.2f}, {col[2]:.2f})')

pin_barrel = [v for v in bm.verts if v.co.x < -0.80 and -0.30 <= v.co.y <= 0.0 and 1.2 <= v.co.z <= 1.6]
for v in pin_barrel[:5]:
    loop = v.link_loops[0]
    col = get_color(loop[uv_layer].uv)
    print(f'pin {v.index}: RGB: ({col[0]:.2f}, {col[1]:.2f}, {col[2]:.2f})')
