import bpy, bmesh

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

# Let's find vertices with y between -0.15 and 0.0, z between 1.68 and 1.85, x < -0.45:
verts = []
for v in bm.verts:
    if 1.68 <= v.co.z <= 1.85 and -0.15 <= v.co.y <= 0.0 and v.co.x < -0.45:
        verts.append(v)

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\right_whisker.txt", "w") as f:
    f.write(f"Found {len(verts)} verts:\n")
    for v in sorted(verts, key=lambda v: v.co.x):
        f.write(f"id={v.index}: co=({v.co.x:.4f}, {v.co.y:.4f}, {v.co.z:.4f})\n")

bm.free()
