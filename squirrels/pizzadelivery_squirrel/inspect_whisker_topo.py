import bpy, bmesh

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]

bm = bmesh.new()
bm.from_mesh(sq.data)

top_ids = {60, 1003, 1917, 3737, 7012}
front_ids = {1454, 1457, 3256, 4659, 5120, 6071, 6994}

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\whisker_topology.txt", "w") as f:
    f.write("TOP WHISKER FACES:\n")
    for f_bm in bm.faces:
        v_ids = set(v.index for v in f_bm.verts)
        if len(v_ids.intersection(top_ids)) >= 2:
            f.write(f"face {f_bm.index}: verts={list(v_ids)}\n")
            
    f.write("\nFRONT WHISKER FACES:\n")
    for f_bm in bm.faces:
        v_ids = set(v.index for v in f_bm.verts)
        if len(v_ids.intersection(front_ids)) >= 2:
            f.write(f"face {f_bm.index}: verts={list(v_ids)}\n")

bm.free()
