import bpy, os

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

verts = [v for v in sq.data.vertices if v.co.z > 1.45 and v.co.x < -0.35]
out_txt = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\nose_verts.txt"
with open(out_txt, "w") as f:
    f.write(f"Found {len(verts)} verts in nose zone (z > 1.45, x < -0.35):\n")
    for v in sorted(verts, key=lambda v: v.co.x):
        f.write(f"id={v.index}: x={v.co.x:.4f}, y={v.co.y:.4f}, z={v.co.z:.4f}\n")

print("INSPECT_NOSE_DONE")
