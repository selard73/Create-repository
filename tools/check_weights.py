import bpy

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\operasinger_squirrel\operasinger_squirrel_rigged.blend")
sq = bpy.data.objects["Squirrel"]
gi = {g.index: g.name for g in sq.vertex_groups}

# Check vertices in outstretched arm: x > 0.2, z between 1.0 and 1.7
arm_verts = [v for v in sq.data.vertices if v.co.x > 0.2 and 1.0 < v.co.z < 1.7]
print("Arm verts count:", len(arm_verts))
arm_bone_weights = {}
for v in arm_verts:
    for g in v.groups:
        nm = gi[g.group]
        arm_bone_weights[nm] = arm_bone_weights.get(nm, 0) + g.weight

with open(r"C:\Users\slard\roblox-props\tools\arm_check.txt", "w") as f:
    f.write(f"Arm verts: {len(arm_verts)}\n")
    for k, v in arm_bone_weights.items():
        f.write(f"{k}: {v/len(arm_verts):.3f}\n")
    
    # Check below-neck chest/dress: z between 0.8 and 1.45, y < 0
    bodice_verts = [v for v in sq.data.vertices if 0.8 < v.co.z < 1.45 and v.co.y < 0.1]
    f.write(f"\nBodice verts: {len(bodice_verts)}\n")
    bodice_weights = {}
    for v in bodice_verts:
        for g in v.groups:
            nm = gi[g.group]
            bodice_weights[nm] = bodice_weights.get(nm, 0) + g.weight
    for k, v in bodice_weights.items():
        f.write(f"{k}: {v/len(bodice_verts):.3f}\n")
