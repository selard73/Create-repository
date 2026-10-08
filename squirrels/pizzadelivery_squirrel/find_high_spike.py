import bpy, bmesh

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

high_verts = []
for v in bm.verts:
    if v.co.z > 1.80 and abs(v.co.y) < 0.15 and v.co.x < -0.45:
        high_verts.append(v)

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\high_verts.txt", "w") as f:
    f.write(f"Found {len(high_verts)} high spike verts:\n")
    for v in sorted(high_verts, key=lambda v: v.co.x):
        f.write(f"id={v.index}: co=({v.co.x:.4f}, {v.co.y:.4f}, {v.co.z:.4f}), valence={len(v.link_edges)}\n")

bm.free()
