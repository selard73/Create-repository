import bpy, bmesh
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

# Find that upward whisker spike:
# In ref_front_after_fix.png, it sits at x between -0.45 and -0.55, z between 1.70 and 1.85, y near 0
# Let's inspect the vertices in that thin blade
spike_candidates = []
for v in bm.verts:
    if 1.70 <= v.co.z <= 1.86 and abs(v.co.y) < 0.05 and v.co.x < -0.45:
        spike_candidates.append(v)

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\upward_whisker.txt", "w") as f:
    f.write(f"Found {len(spike_candidates)} candidates:\n")
    for v in sorted(spike_candidates, key=lambda v: v.co.x):
        f.write(f"id={v.index}: co=({v.co.x:.4f}, {v.co.y:.4f}, {v.co.z:.4f})\n")

bm.free()
