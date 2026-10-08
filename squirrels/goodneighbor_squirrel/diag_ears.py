import bpy

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\goodneighbor_squirrel_rigged.blend")
sq = bpy.data.objects["Squirrel"]
groups = {g.name: g.index for g in sq.vertex_groups}

# Inspect all vertices with Z > 2.0 (ears and top of head)
# Find their weights across Head, Neck, Tail1, Tail2, Chest, Root
with open(r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\ear_diag.txt", "w") as f:
    f.write(f"Groups: {groups}\n")
    top_verts = [v for v in sq.data.vertices if v.co.z > 2.05]
    f.write(f"Verts with Z > 2.05: {len(top_verts)}\n")
    
    ear_tail_pull = []
    for v in top_verts:
        weights = {g.group: g.weight for g in v.groups}
        hw = weights.get(groups.get("Head"), 0.0)
        t1w = weights.get(groups.get("Tail1"), 0.0)
        t2w = weights.get(groups.get("Tail2"), 0.0)
        tw = t1w + t2w
        if tw > 0.01:
            ear_tail_pull.append((v.index, v.co.x, v.co.y, v.co.z, hw, tw))
            
    f.write(f"Ears/top verts with Tail weight > 0.01: {len(ear_tail_pull)}\n")
    for r in ear_tail_pull[:50]:
        f.write(f"idx {r[0]} pos=({r[1]:.2f}, {r[2]:.2f}, {r[3]:.2f}) Head={r[4]:.2f} Tail={r[5]:.2f}\n")
        
    # Check max Z and Y range of ears
    ear_tips = [v for v in sq.data.vertices if v.co.z > 2.2]
    f.write(f"Ears tips (Z > 2.2): {len(ear_tips)}\n")
    for v in ear_tips:
        weights = {g.group: g.weight for g in v.groups}
        hw = weights.get(groups.get("Head"), 0.0)
        tw = weights.get(groups.get("Tail1"), 0.0) + weights.get(groups.get("Tail2"), 0.0)
        f.write(f"  ear_tip idx {v.index} pos=({v.co.x:.2f}, {v.co.y:.2f}, {v.co.z:.2f}) Head={hw:.2f} Tail={tw:.2f}\n")
        
    f.write("EAR_DIAG_DONE\n")
