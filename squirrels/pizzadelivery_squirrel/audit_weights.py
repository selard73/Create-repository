import bpy

blend_path = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\pizzadelivery_squirrel_rigged.blend"
bpy.ops.wm.open_mainfile(filepath=blend_path)
sq = bpy.data.objects["Squirrel"]
gi = {g.index: g.name for g in sq.vertex_groups}

def bweights(v):
    return {gi[g.group]: round(g.weight, 3) for g in v.groups if gi.get(g.group) in ["Root", "Chest", "Neck", "Head", "Tail1", "Tail2"]}

# 1. Wheels / undercarriage (z < 0.8)
low_verts = [v for v in sq.data.vertices if v.co.z < 0.80]
low_bones = {}
for v in low_verts:
    for b, w in bweights(v).items():
        if w > 0.1: low_bones[b] = low_bones.get(b, 0) + 1

# 2. Pizza box (y > 0.5, z < 1.5)
box_verts = [v for v in sq.data.vertices if v.co.y > 0.50 and v.co.z < 1.50]
box_bones = {}
for v in box_verts:
    for b, w in bweights(v).items():
        if w > 0.1: box_bones[b] = box_bones.get(b, 0) + 1

# 3. Head & helmet (z >= 1.45, y < 0.0)
head_verts = [v for v in sq.data.vertices if v.co.z >= 1.45 and v.co.y < 0.0]
head_tail_leaks = sum(1 for v in head_verts if any(b in ["Tail1", "Tail2"] and w > 0.01 for b, w in bweights(v).items()))

# 4. Tail (y > 0.3, z >= 1.2)
tail_verts = [v for v in sq.data.vertices if v.co.y > 0.30 and v.co.z >= 1.20]
tail_head_leaks = sum(1 for v in tail_verts if any(b in ["Head", "Neck"] and w > 0.01 for b, w in bweights(v).items()))

with open(r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel\weight_audit.txt", "w") as f:
    f.write(f"Low verts (z < 0.8): {len(low_verts)} -> {low_bones}\n")
    f.write(f"Pizza box verts (y > 0.5, z < 1.5): {len(box_verts)} -> {box_bones}\n")
    f.write(f"Head/helmet verts: {len(head_verts)}, tail leaks: {head_tail_leaks}\n")
    f.write(f"Tail verts: {len(tail_verts)}, head leaks: {tail_head_leaks}\n")

print("WEIGHT_AUDIT_DONE")
