import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')
mesh = bpy.data.objects['Squirrel']

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/face_heights.txt', 'w') as f:
    face_verts = [v for v in mesh.data.vertices if v.co.y < -0.15 and v.co.x > -0.60 and v.co.x < 0.30]
    zs = [v.co.z for v in face_verts]
    f.write(f"Face verts count: {len(face_verts)}\n")
    f.write(f"Min face Z: {min(zs):.3f}, Max face Z: {max(zs):.3f}\n")
    apron_verts = [v for v in mesh.data.vertices if abs(v.co.x) < 0.25 and v.co.y < 0.0 and v.co.z < 1.35 and v.co.z > 0.9]
    f.write(f"Apron top Z: {max(v.co.z for v in apron_verts):.3f}\n")
