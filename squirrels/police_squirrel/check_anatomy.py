import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_prepped.blend")
mesh = bpy.data.objects['Squirrel']

# Find min/max coordinates
min_z = min(v.co.z for v in mesh.data.vertices)
max_z = max(v.co.z for v in mesh.data.vertices)
min_y = min(v.co.y for v in mesh.data.vertices)
max_y = max(v.co.y for v in mesh.data.vertices)
min_x = min(v.co.x for v in mesh.data.vertices)
max_x = max(v.co.x for v in mesh.data.vertices)

# Sample Z slices to determine anatomy
slices = {}
for i in range(24):
    z_low = i * 0.1
    z_high = (i + 1) * 0.1
    verts = [v for v in mesh.data.vertices if z_low <= v.co.z < z_high]
    if verts:
        min_vy = min(v.co.y for v in verts)
        max_vy = max(v.co.y for v in verts)
        min_vx = min(v.co.x for v in verts)
        max_vx = max(v.co.x for v in verts)
        slices[f"{z_low:.1f}-{z_high:.1f}"] = (len(verts), min_vx, max_vx, min_vy, max_vy)

report = []
report.append(f"Z Range: [{min_z:.3f}, {max_z:.3f}]")
report.append(f"Y Range: [{min_y:.3f}, {max_y:.3f}] (negative is front, positive is back)")
report.append(f"X Range: [{min_x:.3f}, {max_x:.3f}]")
report.append("\nZ Slices (Count, MinX, MaxX, MinY(front), MaxY(back)):")
for k, v in slices.items():
    report.append(f"  Z {k}: {v[0]} verts | X: [{v[1]:.2f}, {v[2]:.2f}] | Y: [{v[3]:.2f}, {v[4]:.2f}]")

with open(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/anatomy.txt", "w") as f:
    f.write("\n".join(report))
print("ANATOMY_ANALYSIS_DONE")
