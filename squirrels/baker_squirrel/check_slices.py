import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = bpy.data.objects['Squirrel']

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/slices.txt', 'w') as f:
    for z_level in [1.25, 1.30, 1.35, 1.40, 1.45, 1.50]:
        verts = [v for v in mesh.data.vertices if abs(v.co.z - z_level) < 0.02]
        f.write(f"Z={z_level:.2f}: count={len(verts)}\n")
        # min/max Y for these verts (excluding pin x < -0.6 and tail x > 0.3)
        center_verts = [v for v in verts if -0.4 <= v.co.x <= 0.25]
        if center_verts:
            min_y = min(v.co.y for v in center_verts)
            max_y = max(v.co.y for v in center_verts)
            f.write(f"   Center Y range: [{min_y:.3f}, {max_y:.3f}]\n")
