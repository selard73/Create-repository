import bpy, os

LOG = r"C:\Users\slard\roblox-props\squirrels\pogo_squirrel\audit_weights_pogo.txt"
with open(LOG, "w") as f:
    bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\pogo_squirrel\pogo_squirrel_rigged.blend")
    sq = bpy.data.objects["Squirrel"]
    gi = {g.index: g.name for g in sq.vertex_groups}
    
    # Check tail weight on head region (x < 0.1, z > 1.5)
    tail_on_head = []
    head_on_body = []
    head_on_tail = []
    
    for v in sq.data.vertices:
        w = {gi[g.group]: round(g.weight, 4) for g in v.groups if gi.get(g.group)}
        # Head is x < 0.1, z > 1.5
        if v.co.x < 0.1 and v.co.z > 1.5:
            tw = sum(weight for name, weight in w.items() if "Tail" in name)
            if tw > 0.01:
                tail_on_head.append((v.index, v.co, w))
        # Body/pogo below z 1.45 having Head/Neck
        if v.co.z < 1.45:
            hn = sum(weight for name, weight in w.items() if name in ["Head", "Neck"])
            if hn > 0.01:
                head_on_body.append((v.index, v.co, w))
        # Tail having Head/Neck
        if v.co.x > 0.15 and v.co.z > 0.8:
            hn = sum(weight for name, weight in w.items() if name in ["Head", "Neck"])
            if hn > 0.01:
                head_on_tail.append((v.index, v.co, w))
                
    f.write(f"Tail weights on head (x < 0.1, z > 1.5): {len(tail_on_head)}\n")
    f.write(f"Head/Neck weights on body/pogo (z < 1.45): {len(head_on_body)}\n")
    f.write(f"Head/Neck weights on tail (x > 0.15): {len(head_on_tail)}\n")
    
    # Check lower pogo stick (z < 0.8) weights
    f.write("\nLower pogo stick (z < 0.7) bone distributions:\n")
    low_bones = {}
    for v in sq.data.vertices:
        if v.co.z < 0.7:
            for g in v.groups:
                if gi.get(g.group) and g.weight > 0.05:
                    bname = gi[g.group]
                    low_bones[bname] = low_bones.get(bname, 0) + 1
    f.write(f"Lower pogo bones: {low_bones}\n")
    f.write("DONE\n")
