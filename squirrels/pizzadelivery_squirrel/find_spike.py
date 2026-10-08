import bpy, bmesh
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

# Let's find vertices in the spike above the nose:
# The spike is above the nose button (z > 1.68) and sticks out in -x direction
spike_verts = []
for v in bm.verts:
    if 1.68 <= v.co.z <= 1.82 and abs(v.co.y) < 0.08 and v.co.x < -0.52:
        spike_verts.append(v)

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\spike_verts.txt", "w") as f:
    f.write(f"Found {len(spike_verts)} verts in spike region:\n")
    for v in sorted(spike_verts, key=lambda v: v.co.x):
        f.write(f"id={v.index}: co=({v.co.x:.4f}, {v.co.y:.4f}, {v.co.z:.4f}), valence={len(v.link_edges)}\n")

bm.free()
