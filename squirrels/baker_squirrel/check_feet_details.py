import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')
mesh = bpy.data.objects['Squirrel']

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/feet_details.txt', 'w') as f:
    vg_root = mesh.vertex_groups.get('Root')
    root_verts = []
    for v in mesh.data.vertices:
        for g in v.groups:
            if g.group == vg_root.index and g.weight > 0.5:
                root_verts.append(v)
                break

    f.write(f"Root verts count: {len(root_verts)}\n")
    root_zs = [v.co.z for v in root_verts]
    f.write(f"Root min Z: {min(root_zs):.4f}, max Z: {max(root_zs):.4f}\n")

    left_foot = [v for v in root_verts if v.co.x < 0]
    right_foot = [v for v in root_verts if v.co.x > 0]
    f.write(f"Left foot min Z: {min(v.co.z for v in left_foot):.4f}\n")
    f.write(f"Right foot min Z: {min(v.co.z for v in right_foot):.4f}\n")

    pin_verts = [v for v in mesh.data.vertices if v.co.x < -0.6 and v.co.z < 1.0]
    if pin_verts:
        f.write(f"Pin min Z: {min(v.co.z for v in pin_verts):.4f}\n")
    else:
        f.write("No pin verts below Z 1.0\n")
