import bpy

log_path = r"C:\Users\slard\roblox-props\tools\head_tail.txt"
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\operasinger_squirrel\operasinger_squirrel.blend")
sq = bpy.data.objects["Squirrel"]
pts = [v.co for v in sq.data.vertices]

with open(log_path, "w") as f:
    f.write(f"Z max: {max(p.z for p in pts):.3f}\n")
    f.write(f"Y min (front): {min(p.y for p in pts):.3f}\n")
    f.write(f"Y max (back): {max(p.y for p in pts):.3f}\n")
    f.write(f"X min: {min(p.x for p in pts):.3f}\n")
    f.write(f"X max: {max(p.x for p in pts):.3f}\n")
    
    # Head search: look at front view x = -0.1 to -0.3
    # Let's inspect z slices near the top
    for z_floor in [1.2, 1.4, 1.6, 1.8]:
        head_pts = [p for p in pts if p.z > z_floor and p.y < -0.1]
        if head_pts:
            hx = sum(p.x for p in head_pts)/len(head_pts)
            hy = sum(p.y for p in head_pts)/len(head_pts)
            hz = sum(p.z for p in head_pts)/len(head_pts)
            f.write(f"Head (z > {z_floor}): count={len(head_pts)}, centroid=({hx:.3f}, {hy:.3f}, {hz:.3f})\n")
    
    # Tail search (y > 0.2)
    for z_floor in [0.6, 0.8, 1.0, 1.2]:
        tail_pts = [p for p in pts if p.y > 0.2 and p.z > z_floor]
        if tail_pts:
            tx = sum(p.x for p in tail_pts)/len(tail_pts)
            ty = sum(p.y for p in tail_pts)/len(tail_pts)
            tz = sum(p.z for p in tail_pts)/len(tail_pts)
            f.write(f"Tail (z > {z_floor}): count={len(tail_pts)}, centroid=({tx:.3f}, {ty:.3f}, {tz:.3f})\n")
