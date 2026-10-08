import bpy, os, bmesh

LOG = r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\audit_islands.txt"
with open(LOG, "w") as f:
    try:
        bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\sassyshopper_squirrel.blend")
        sq = bpy.data.objects["Squirrel"]
        
        # Let's inspect vertices around X = -0.5, Z = 1.8:
        # What is the distance from the head center?
        # Head top is at (0.15, 0.0, 2.3)
        # Tail top is at (-0.8, 0.7, 2.0)
        
        f.write("Vertices around head height (Z > 1.5):\n")
        # Let's check vertices with X in [-0.6, -0.2]:
        for v in sq.data.vertices:
            if -0.7 <= v.co.x <= -0.2 and v.co.z >= 1.6:
                # Is it face or tail?
                # Let's check Y:
                f.write(f"v {v.index}: x={v.co.x:.3f}, y={v.co.y:.3f}, z={v.co.z:.3f}\n")
        f.write("\nDONE\n")
    except Exception as e:
        f.write(f"ERROR: {e}\n")
