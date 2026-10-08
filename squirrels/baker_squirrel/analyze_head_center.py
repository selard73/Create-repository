import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
verts = [v.co for v in mesh.data.vertices]

# Nose tip:
nose = min(verts, key=lambda v: v.y)
print('Nose tip:', nose.x, nose.y, nose.z)

# Verts in head (Z >= 1.5, Y < -0.2):
head_front = [v for v in verts if v.z >= 1.5 and v.y < -0.2]
xs = [v.x for v in head_front]
ys = [v.y for v in head_front]
zs = [v.z for v in head_front]
print(f'Head front ({len(head_front)} verts):')
print(f'  X: {min(xs):.3f} .. {max(xs):.3f} (center: {(min(xs)+max(xs))/2:.3f})')
print(f'  Y: {min(ys):.3f} .. {max(ys):.3f}')
print(f'  Z: {min(zs):.3f} .. {max(zs):.3f}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/head_center.txt', 'w') as out:
    out.write(f'Nose: {nose.x:.3f}, {nose.y:.3f}, {nose.z:.3f}\n')
    out.write(f'X center: {(min(xs)+max(xs))/2:.3f}\n')
    out.write(f'X range: {min(xs):.3f} .. {max(xs):.3f}\n')
