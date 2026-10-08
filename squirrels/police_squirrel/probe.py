import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath=r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_prepped.blend")
mesh = bpy.data.objects['Squirrel']

# Check head bounding box (Z >= 1.45)
head_verts = [v for v in mesh.data.vertices if v.co.z >= 1.45 and (v.co.x < 0.25 or v.co.y < 0.0)]
hx_min = min(v.co.x for v in head_verts)
hx_max = max(v.co.x for v in head_verts)
hy_min = min(v.co.y for v in head_verts)
hy_max = max(v.co.y for v in head_verts)
hz_min = min(v.co.z for v in head_verts)
hz_max = max(v.co.z for v in head_verts)

# Check tail bounding box
tail_verts = [v for v in mesh.data.vertices if v.co.x > 0.20 and v.co.y > 0.0]
tx_min = min(v.co.x for v in tail_verts)
tx_max = max(v.co.x for v in tail_verts)
ty_min = min(v.co.y for v in tail_verts)
ty_max = max(v.co.y for v in tail_verts)
tz_min = min(v.co.z for v in tail_verts)
tz_max = max(v.co.z for v in tail_verts)

# Check torso bounding box (Z between 0.7 and 1.45, X < 0.25)
torso_verts = [v for v in mesh.data.vertices if 0.70 <= v.co.z < 1.45 and v.co.x < 0.25]
bx_min = min(v.co.x for v in torso_verts)
bx_max = max(v.co.x for v in torso_verts)
by_min = min(v.co.y for v in torso_verts)
by_max = max(v.co.y for v in torso_verts)

print(f"HEAD: X[{hx_min:.2f}, {hx_max:.2f}] Y[{hy_min:.2f}, {hy_max:.2f}] Z[{hz_min:.2f}, {hz_max:.2f}]")
print(f"TAIL: X[{tx_min:.2f}, {tx_max:.2f}] Y[{ty_min:.2f}, {ty_max:.2f}] Z[{tz_min:.2f}, {tz_max:.2f}]")
print(f"TORSO: X[{bx_min:.2f}, {bx_max:.2f}] Y[{by_min:.2f}, {by_max:.2f}]")

with open(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/spatial_probe.txt", "w") as f:
    f.write(f"HEAD: X[{hx_min:.2f}, {hx_max:.2f}] Y[{hy_min:.2f}, {hy_max:.2f}] Z[{hz_min:.2f}, {hz_max:.2f}]\n")
    f.write(f"TAIL: X[{tx_min:.2f}, {tx_max:.2f}] Y[{ty_min:.2f}, {ty_max:.2f}] Z[{tz_min:.2f}, {tz_max:.2f}]\n")
    f.write(f"TORSO: X[{bx_min:.2f}, {bx_max:.2f}] Y[{by_min:.2f}, {by_max:.2f}]\n")
