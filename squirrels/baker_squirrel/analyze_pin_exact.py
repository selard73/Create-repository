import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Look at verts with X < -0.65.
# Rolling pin is cylindrical:
pin_verts = [v for v in verts if v.x < -0.70 and v.z < 1.85]
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pin_exact.txt', 'w') as out:
    out.write(f'Pin verts count: {len(pin_verts)}\n')
    out.write(f'X: {min(v.x for v in pin_verts):.2f}..{max(v.x for v in pin_verts):.2f}\n')
    out.write(f'Y: {min(v.y for v in pin_verts):.2f}..{max(v.y for v in pin_verts):.2f}\n')
    out.write(f'Z: {min(v.z for v in pin_verts):.2f}..{max(v.z for v in pin_verts):.2f}\n')
