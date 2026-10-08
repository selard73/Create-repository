import bpy, os

LOG = r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\test_split.txt"
with open(LOG, "w") as f:
    try:
        bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\sassyshopper_squirrel.blend")
        sq = bpy.data.objects["Squirrel"]
        
        # Check all vertices with Z > 1.55
        head_cand = []
        tail_cand = []
        ambiguous = []
        for v in sq.data.vertices:
            if v.co.z >= 1.55:
                if v.co.y < 0.42:
                    head_cand.append(v)
                elif v.co.y > 0.48:
                    tail_cand.append(v)
                else:
                    ambiguous.append(v)
                    
        f.write(f"Head candidates (y < 0.42, z >= 1.55): {len(head_cand)}\n")
        f.write(f"Tail candidates (y > 0.48, z >= 1.55): {len(tail_cand)}\n")
        f.write(f"Ambiguous in gap [0.42 .. 0.48]: {len(ambiguous)}\n")
        for v in ambiguous:
            f.write(f"  v {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})\n")
            
        f.write("\nDONE\n")
    except Exception as e:
        f.write(f"ERROR: {e}\n")
