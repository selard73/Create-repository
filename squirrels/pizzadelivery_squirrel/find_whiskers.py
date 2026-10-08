import bpy, bmesh
from mathutils import Vector

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

# Let's inspect the whiskers on the nose
# In the render, the nose button is around x = -0.55 .. -0.58, y = -0.08 .. 0.08, z = 1.60 .. 1.75
# The stray whiskers extend further in -x (x < -0.58):
# Whisker 1 (top): z around 1.75 - 1.95, y around 0.0, x < -0.60
# Whisker 2 (front): z around 1.60 - 1.68, y around 0.0, x < -0.62

whisker_verts = []
for v in bm.verts:
    # Top nose whisker:
    if v.co.z > 1.72 and abs(v.co.y) < 0.08 and v.co.x < -0.59:
        whisker_verts.append((v, "top_whisker"))
    # Front nose whisker:
    elif 1.60 <= v.co.z <= 1.70 and abs(v.co.y) < 0.08 and v.co.x < -0.64:
        whisker_verts.append((v, "front_whisker"))

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\whiskers_found.txt", "w") as f:
    f.write(f"Candidate whisker verts: {len(whisker_verts)}\n")
    for v, tag in whisker_verts:
        f.write(f"{tag}: id={v.index}, co=({v.co.x:.4f}, {v.co.y:.4f}, {v.co.z:.4f}), valence={len(v.link_edges)}\n")

bm.free()
