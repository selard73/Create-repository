import bpy

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\goodneighbor_squirrel_rigged.blend")
sq = bpy.data.objects["Squirrel"]

groups = {g.name: g.index for g in sq.vertex_groups}
print("Groups:", groups)

with open(r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\rig_audit.txt", "w") as f:
    f.write(f"Total verts: {len(sq.data.vertices)}\n")
    
    # 1. Any Head verts below Z=1.5 or Y < -0.4?
    # Lasagna pan vertices (Y < -0.4, Z between 1.0 and 1.6)
    pan_verts = [v for v in sq.data.vertices if v.co.y < -0.4 and 0.9 < v.co.z < 1.6]
    f.write(f"Pan verts: {len(pan_verts)}\n")
    pan_head_weight = sum(g.weight for v in pan_verts for g in v.groups if g.group in [groups.get('Head'), groups.get('Neck')])
    f.write(f"Pan Head/Neck total weight: {pan_head_weight:.4f}\n")
    
    # 2. Face / Head verts (Z > 1.6, Y < 0.15)
    face_verts = [v for v in sq.data.vertices if v.co.z > 1.6 and v.co.y < 0.15]
    f.write(f"Face verts: {len(face_verts)}\n")
    face_tail_weight = sum(g.weight for v in face_verts for g in v.groups if g.group in [groups.get('Tail1'), groups.get('Tail2')])
    f.write(f"Face Tail total weight: {face_tail_weight:.4f}\n")
    
    # 3. Tail verts (Y > 0.3)
    tail_verts = [v for v in sq.data.vertices if v.co.y > 0.3]
    f.write(f"Tail verts: {len(tail_verts)}\n")
    tail_head_weight = sum(g.weight for v in tail_verts for g in v.groups if g.group in [groups.get('Head'), groups.get('Neck')])
    f.write(f"Tail Head/Neck total weight: {tail_head_weight:.4f}\n")
    
    # 4. Check for any vertices in the whole mesh that have both Head > 0.1 and Tail > 0.1
    both = []
    h_idx = groups.get("Head")
    t1_idx = groups.get("Tail1")
    t2_idx = groups.get("Tail2")
    for v in sq.data.vertices:
        hw = sum(g.weight for g in v.groups if g.group == h_idx)
        tw = sum(g.weight for g in v.groups if g.group in [t1_idx, t2_idx])
        if hw > 0.05 and tw > 0.05:
            both.append((v.index, v.co.x, v.co.y, v.co.z, hw, tw))
    f.write(f"Vertices with BOTH Head > 0.05 AND Tail > 0.05: {len(both)}\n")
    for b in both[:20]:
        f.write(f"  idx {b[0]} pos ({b[1]:.2f}, {b[2]:.2f}, {b[3]:.2f}) Head={b[4]:.2f} Tail={b[5]:.2f}\n")
        
    f.write("AUDIT_COMPLETE\n")
