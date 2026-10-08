import bpy, bmesh

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

needle_ids = {1917, 2386, 1475, 556, 4710}
for f in bm.faces:
    v_ids = set(v.index for v in f.verts)
    if v_ids.intersection(needle_ids):
        print(f"face {f.index}: verts={list(v_ids)}")

# Let's inspect where the snout surface below the needle is:
# The forehead/snout between eyes is around x = -0.45, z = 1.88, y = 0.0
# The needle vertices are at x = -0.57, z = 1.88..1.93!
# They are protruding forward by 0.12 units in front of the forehead!
# If we move them to x = -0.46 (flush with the forehead fur):
for v in bm.verts:
    if v.index in needle_ids:
        print(f"Needle vert {v.index}: was {v.co}")
        v.co.x = -0.44

bm.to_mesh(sq.data)
bm.free()
sq.data.update()

bpy.ops.wm.save_mainfile(filepath=blend_path)

# Render face front
sc = bpy.context.scene
sc.render.filepath = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\face_front_fixed.png"
bpy.ops.render.render(write_still=True)
print("NEEDLE_FIX_DONE")
