import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.faces.ensure_lookup_table()

# Let\'s see all faces in the junction crease:
# Crease box: X in [0.22, 0.55], Y in [0.04, 0.22], Z in [1.45, 2.05]
crease_faces = []
for f in bm.faces:
    cents = f.calc_center_median()
    if 0.22 <= cents.x <= 0.55 and 0.04 <= cents.y <= 0.22 and 1.45 <= cents.z <= 2.05:
        # Check normal: webbing faces typically point upwards or sideways between the two volumes
        crease_faces.append(f)

print(f'Crease faces: {len(crease_faces)}')
with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/crease_faces.txt', 'w') as out:
    out.write(f'Crease faces: {len(crease_faces)}\n')
    for f in crease_faces[:20]:
        c = f.calc_center_median()
        out.write(f'face {f.index}: center=({c.x:.3f}, {c.y:.3f}, {c.z:.3f}), normal=({f.normal.x:.2f}, {f.normal.y:.2f}, {f.normal.z:.2f})\n')
