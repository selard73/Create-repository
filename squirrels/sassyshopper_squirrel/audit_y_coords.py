import bpy, os

LOG = r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\audit_y_coords.txt"
with open(LOG, "w") as f:
    try:
        bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel\sassyshopper_squirrel.blend")
        sq = bpy.data.objects["Squirrel"]
        
        # Check all vertices around the head height: Z > 1.6
        f.write("Vertices with Z > 1.6 and X between -0.7 and 0.7:\n")
        # Find the nose or front of face:
        # What is the forward direction?
        # In Blender:
        # Chest bone: head=(0,0,0), tail=(0, 0.4768, 0.1233). Chest tail is at +Y! So +Y is towards the front / chest!
        # Head bone: tail=(0, 0.1519, 0.9311). Head is tilted +Y and +Z!
        # Tail1 bone: head=(-1.09, 0, -0.30), tail=(-1.10, 0.40, -0.62).
        
        # Let's inspect where the face and tail are in Y:
        # Let's print out the min and max Y for various X slices at Z > 1.6:
        for x_start in [-1.2, -0.9, -0.6, -0.3, 0.0, 0.3]:
            verts = [v for v in sq.data.vertices if x_start <= v.co.x < x_start + 0.3 and v.co.z > 1.6]
            if verts:
                ys = [v.co.y for v in verts]
                zs = [v.co.z for v in verts]
                f.write(f"X slice [{x_start:.1f} .. {x_start+0.3:.1f}]: count={len(verts)}, Y range={min(ys):.3f}..{max(ys):.3f}, Z range={min(zs):.3f}..{max(zs):.3f}\n")
        f.write("\nDONE\n")
    except Exception as e:
        f.write(f"ERROR: {e}\n")
