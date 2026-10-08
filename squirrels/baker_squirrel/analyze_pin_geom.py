import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
vgs = {vg.name: vg for vg in mesh.vertex_groups}

# Look at idx 46, 54, 59, 61, 62, 64 at Z=2.0..2.23, X=-0.70..-0.65!
# What is that? The top of the rolling pin handle? Or the left side of the chef toque hat?!
# In front render check_front3.png:
# Where does the chef toque hat reach in X, Y, Z?
# Toque hat is at Z=1.8..2.4, X=-0.70..+0.40!
# At X < -0.45, Z > 1.9, that\'s the puffy overhang of his chef hat!
# And at X=-0.5..-0.3, Y=-0.5..-0.2, Z=1.5..1.8, that\'s his left cheek, eye, and whiskers!

hat_overhang = [v for v in mesh.data.vertices if v.co.z > 1.9 and v.co.x < -0.45]
print('Hat overhang verts at X < -0.45:', len(hat_overhang))
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/hat_info.txt', 'w') as out:
    out.write(f'Hat overhang count: {len(hat_overhang)}\n')
    for v in hat_overhang:
        out.write(f'  idx {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})\n')
