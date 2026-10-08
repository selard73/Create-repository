import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.faces.ensure_lookup_table()

# Let\'s check the distance between ear verts (X in 0.15..0.40, Y < 0.10, Z > 1.6)
# and tail verts in that same Z range (Z in 1.6..2.0, X > 0.35, Y > 0.15):
ear_pts = [v for v in bm.verts if 0.15 <= v.co.x <= 0.40 and v.co.y < 0.05 and v.co.z > 1.6]
tail_pts = [v for v in bm.verts if v.co.x > 0.35 and v.co.y > 0.15 and 1.6 < v.co.z < 2.0]

print(f'Ear pts: {len(ear_pts)}, Tail pts: {len(tail_pts)}')

min_dist = 999
closest_pair = None
for e in ear_pts:
    for t in tail_pts:
        d = (e.co - t.co).length
        if d < min_dist:
            min_dist = d
            closest_pair = (e, t)

print(f'Minimum 3D spatial distance: {min_dist:.3f}')
print(f'Closest ear: {closest_pair[0].co}')
print(f'Closest tail: {closest_pair[1].co}')

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/gap.txt', 'w') as out:
    out.write(f'Min dist: {min_dist:.3f}\n')
    out.write(f'Ear: {closest_pair[0].co}\n')
    out.write(f'Tail: {closest_pair[1].co}\n')
