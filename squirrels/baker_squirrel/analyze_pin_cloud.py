import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Verts on negative X side:
for x_cut in [-0.9, -0.8, -0.7, -0.6, -0.5, -0.4]:
    sub = [v for v in verts if x_cut - 0.1 <= v.x < x_cut and 1.4 <= v.z <= 1.9]
    print(f'X in [{x_cut-0.1:.2f}, {x_cut:.2f}), Z in [1.4, 1.9]: count={len(sub)}')
    if sub:
        min_y = min(v.y for v in sub)
        max_y = max(v.y for v in sub)
        print(f'   Y range: {min_y:.2f} .. {max_y:.2f}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/slices.txt', 'w') as out:
    for x_cut in [-0.9, -0.8, -0.7, -0.6, -0.5, -0.4]:
        sub = [v for v in verts if x_cut - 0.1 <= v.x < x_cut and 1.4 <= v.z <= 1.9]
        if sub:
            out.write(f'X in [{x_cut-0.1:.2f}, {x_cut:.2f}), Z in [1.4, 1.9]: cnt={len(sub)}, Y={min(v.y for v in sub):.2f}..{max(v.y for v in sub):.2f}\n')
