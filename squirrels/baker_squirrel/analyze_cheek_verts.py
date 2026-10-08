import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Squirrel is facing canonical -Y.
# Cheeks and whiskers:
# Snout tip / nose is at Y ~ -0.77, Z ~ 1.60.
# Left cheek (from squirrel\'s perspective, which is +X side):
# Cheeks at +X: X in 0.10 .. 0.50, Y in -0.75 .. -0.30, Z in 1.45 .. 1.80.
# Right cheek (from squirrel\'s perspective, which is -X side):
# Cheeks at -X: X in -0.50 .. -0.10, Y in -0.75 .. -0.30, Z in 1.45 .. 1.80.

left_cheek = [v for v in verts if 0.10 <= v.x <= 0.60 and -0.77 <= v.y <= -0.25 and 1.40 <= v.z <= 1.85]
right_cheek = [v for v in verts if -0.60 <= v.x <= -0.10 and -0.77 <= v.y <= -0.25 and 1.40 <= v.z <= 1.85]

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/cheeks.txt', 'w') as out:
    out.write(f'+X cheek (squirrel left, viewer right): {len(left_cheek)} verts\n')
    out.write(f'-X cheek (squirrel right, viewer left): {len(right_cheek)} verts\n')
    # Check X bounds of left cheek:
    xs_l = [v.x for v in left_cheek]
    ys_l = [v.y for v in left_cheek]
    zs_l = [v.z for v in left_cheek]
    out.write(f'+X cheek bounds: X={min(xs_l):.2f}..{max(xs_l):.2f}, Y={min(ys_l):.2f}..{max(ys_l):.2f}, Z={min(zs_l):.2f}..{max(zs_l):.2f}\n')
    # Check what vertex groups these +X cheek verts belong to in baker_squirrel_rigged.blend!
