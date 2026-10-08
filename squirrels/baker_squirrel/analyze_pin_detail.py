import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# In check_front3.png:
# Chef hat is at Z >= 1.9, X is around -0.35..0.0.
# The rolling pin is held up vertically: it goes up to Z=1.85, at X around -0.6..-0.9!
# Let\'s check verts near X=-0.75, Z > 1.4:
pin_top = [v for v in verts if v.x < -0.5 and v.z > 1.3]
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/pin_top.txt', 'w') as out:
    out.write(f'Pin top verts: {len(pin_top)}\n')
    out.write(f'X range: {min(v.x for v in pin_top):.2f} .. {max(v.x for v in pin_top):.2f}\n')
    out.write(f'Y range: {min(v.y for v in pin_top):.2f} .. {max(v.y for v in pin_top):.2f}\n')
    out.write(f'Z range: {min(v.z for v in pin_top):.2f} .. {max(v.z for v in pin_top):.2f}\n')
