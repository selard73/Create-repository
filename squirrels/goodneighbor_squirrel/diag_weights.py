import bpy

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\goodneighbor_squirrel_rigged.blend")
sq = bpy.data.objects["Squirrel"]

groups = {g.name: g.index for g in sq.vertex_groups}
print("Groups:", groups)

# Find verts with high Head weight AND high Tail1/Tail2 weight
# Or verts near head with Tail weight
head_verts_with_tail = []
tail_verts_with_head = []

h_idx = groups.get("Head")
t1_idx = groups.get("Tail1")
t2_idx = groups.get("Tail2")
n_idx = groups.get("Neck")
c_idx = groups.get("Chest")

with open(r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\weight_diag.txt", "w") as f:
    f.write(f"Total verts: {len(sq.data.vertices)}\n")
    
    # Vertices above z=1.6
    head_region_tail_pull = []
    for v in sq.data.vertices:
        weights = {g.group: g.weight for g in v.groups}
        hw = weights.get(h_idx, 0.0)
        nw = weights.get(n_idx, 0.0)
        t1w = weights.get(t1_idx, 0.0)
        t2w = weights.get(t2_idx, 0.0)
        cw = weights.get(c_idx, 0.0)
        
        tw = t1w + t2w
        
        if v.co.z > 1.6 and tw > 0.05:
            head_region_tail_pull.append((v.index, v.co.x, v.co.y, v.co.z, hw, nw, tw, cw))
            
    f.write(f"Verts with Z > 1.6 that have Tail weight > 0.05: {len(head_region_tail_pull)}\n")
    for row in head_region_tail_pull[:30]:
        f.write(f"idx={row[0]} pos=({row[1]:.2f}, {row[2]:.2f}, {row[3]:.2f}) Head={row[4]:.2f} Neck={row[5]:.2f} Tail={row[6]:.2f} Chest={row[7]:.2f}\n")
        
    # Also check how many verts in the whole head have Tail weight
    face_verts = [v for v in sq.data.vertices if v.co.z > 1.6 and v.co.y < 0.1]
    f.write(f"Face/Front Head verts (Z>1.6, Y<0.1): {len(face_verts)}\n")
    face_tail_count = 0
    for v in face_verts:
        weights = {g.group: g.weight for g in v.groups}
        if weights.get(t1_idx, 0.0) + weights.get(t2_idx, 0.0) > 0.05:
            face_tail_count += 1
    f.write(f"Face verts with Tail weight > 0.05: {face_tail_count}\n")
    f.write("DIAG_DONE\n")
