import bpy, os

LOG = r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\audit_head_verts.txt"
with open(LOG, "w") as f:
    try:
        bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\sassyshopper_squirrel_rigged.blend")
        sq = bpy.data.objects["Squirrel"]
        gi = {g.index: g.name for g in sq.vertex_groups}
        
        f.write("--- Head group vertices ---\n")
        head_verts = [v for v in sq.data.vertices if any(gi[g.group] == "Head" and g.weight > 0.1 for g in v.groups)]
        f.write(f"Total Head verts: {len(head_verts)}\n")
        xs = [v.co.x for v in head_verts]
        ys = [v.co.y for v in head_verts]
        zs = [v.co.z for v in head_verts]
        f.write(f"Head X range: {min(xs):.3f} .. {max(xs):.3f}\n")
        f.write(f"Head Y range: {min(ys):.3f} .. {max(ys):.3f}\n")
        f.write(f"Head Z range: {min(zs):.3f} .. {max(zs):.3f}\n")
        
        f.write("\n--- Tail2 group vertices ---\n")
        t2_verts = [v for v in sq.data.vertices if any(gi[g.group] == "Tail2" and g.weight > 0.1 for g in v.groups)]
        f.write(f"Total Tail2 verts: {len(t2_verts)}\n")
        t2_xs = [v.co.x for v in t2_verts]
        t2_ys = [v.co.y for v in t2_verts]
        t2_zs = [v.co.z for v in t2_verts]
        f.write(f"Tail2 X range: {min(t2_xs):.3f} .. {max(t2_xs):.3f}\n")
        f.write(f"Tail2 Y range: {min(t2_ys):.3f} .. {max(t2_ys):.3f}\n")
        f.write(f"Tail2 Z range: {min(t2_zs):.3f} .. {max(t2_zs):.3f}\n")
        
        # Check where Tail2 overlaps into the Head height (Z > 1.6)
        overlap = [v for v in sq.data.vertices if v.co.z > 1.6 and any(gi[g.group] == "Tail2" and g.weight > 0.1 for g in v.groups)]
        f.write(f"\nTail2 vertices with Z > 1.6: {len(overlap)}\n")
        for v in overlap:
            weights = {gi[g.group]: round(g.weight, 3) for g in v.groups if gi.get(g.group)}
            f.write(f"  v {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}) -> {weights}\n")
            
        f.write("\nDONE\n")
    except Exception as e:
        f.write(f"ERROR: {e}\n")
