import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

# Use bmesh to find connected components of the rolling pin:
# Can we identify rolling pin vertices by material / UV / connectivity?
import bmesh
bm = bmesh.new()
bm.from_mesh(mesh.data)

# Let\'s check the UVs or materials:
print('Materials count:', len(mesh.data.materials))
for mat in mesh.data.materials:
    print('  Material:', mat.name)

# Let\'s inspect face vertices:
# Face center: X ~ -0.2..0.1, Y ~ -0.7..-0.4, Z ~ 1.5..1.9
# Cheeks: left cheek is +X (X ~ 0.1..0.4), right cheek is -X (X ~ -0.4..-0.1)
# Rolling pin: held in right paw at X ~ -0.7..-0.9, Y ~ -0.4..0.1, Z ~ 0.9..1.8
