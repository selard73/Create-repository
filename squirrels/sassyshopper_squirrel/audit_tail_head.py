import bpy, os

LOG = r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\audit_th_log.txt"
with open(LOG, "w") as f:
    try:
        bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\sassyshopper_squirrel_rigged.blend")
        sq = bpy.data.objects["Squirrel"]
        gi = {g.index: g.name for g in sq.vertex_groups}
        f.write(f"Total vertices: {len(sq.data.vertices)}\n")
        
        # Check all vertices with Z > 1.5
        tail_on_head = 0
        for v in sq.data.vertices:
            if v.co.z > 1.5:
                weights = {gi[g.group]: round(g.weight, 4) for g in v.groups if gi.get(g.group)}
                t_weight = sum(w for name, w in weights.items() if "Tail" in name)
                if t_weight > 0.001:
                    tail_on_head += 1
                    if tail_on_head <= 25:
                        f.write(f"v {v.index} co: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}) -> {weights}\n")
        f.write(f"Total verts with Z > 1.5 having Tail weight: {tail_on_head}\n")
        
        # Check bone positions
        arm = bpy.data.objects["SquirrelRig"]
        for b in arm.data.bones:
            f.write(f"Bone {b.name}: head={b.head}, tail={b.tail}\n")
        f.write("AUDIT_TH_DONE\n")
    except Exception as e:
        f.write(f"ERROR: {e}\n")
