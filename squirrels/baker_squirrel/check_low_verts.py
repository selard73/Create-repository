import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')
mesh = bpy.data.objects['Squirrel']

with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/low_verts.txt', 'w') as f:
    low = [v for v in mesh.data.vertices if v.co.z < 0.05]
    f.write(f"Total verts with Z < 0.05: {len(low)}\n")
    for v in low[:25]:
        groups = [mesh.vertex_groups[g.group].name for g in v.groups]
        f.write(f"  co=({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}) groups={groups}\n")
