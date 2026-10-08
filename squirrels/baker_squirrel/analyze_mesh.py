
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
verts = [v.co for v in mesh.data.vertices]

# Canonical forward is -Y.
# Let's find snout/face forwardmost verts (lowest Y)
face_verts = sorted(verts, key=lambda v: v.y)[:50]
print('Forwardmost verts (min Y):')
for v in face_verts[:10]:
    print(f'  X={v.x:.3f}, Y={v.y:.3f}, Z={v.z:.3f}')

# Tail verts (highest Y)
tail_verts = sorted(verts, key=lambda v: v.y, reverse=True)[:50]
print('Rearmost verts (max Y):')
for v in tail_verts[:10]:
    print(f'  X={v.x:.3f}, Y={v.y:.3f}, Z={v.z:.3f}')

# Let's check Z slices:
for z_low in [0.0, 0.4, 0.8, 1.2, 1.4, 1.6, 1.8, 2.0]:
    sl = [v for v in verts if z_low <= v.z < z_low + 0.2]
    if sl:
        min_y = min(v.y for v in sl)
        max_y = max(v.y for v in sl)
        min_x = min(v.x for v in sl)
        max_x = max(v.x for v in sl)
        print(f'Z={z_low:.1f}..{z_low+0.2:.1f}: cnt={len(sl)}, Y={min_y:.2f}..{max_y:.2f}, X={min_x:.2f}..{max_x:.2f}')
