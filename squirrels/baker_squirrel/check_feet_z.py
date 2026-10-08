import bpy
import numpy as np

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')
mesh = bpy.data.objects['Squirrel']

verts = [v.co for v in mesh.data.vertices]
zs = [v.z for v in verts]
min_z = min(zs)
max_z = max(zs)

# Lowest 20 vertices
sorted_v = sorted(verts, key=lambda v: v.z)
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/feet.txt', 'w') as f:
    f.write(f"Min Z: {min_z:.6f}, Max Z: {max_z:.6f}\n")
    f.write(f"Height: {max_z - min_z:.6f}\n")
    f.write("Lowest 10 vertices:\n")
    for v in sorted_v[:10]:
        f.write(f"  ({v.x:.4f}, {v.y:.4f}, {v.z:.4f})\n")
