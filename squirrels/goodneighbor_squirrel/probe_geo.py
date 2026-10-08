import bpy

bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\goodneighbor_squirrel.blend")
sq = bpy.data.objects.get("Squirrel")
pts = [v.co for v in sq.data.vertices]

out_path = r"C:\Users\slard\roblox-props\squirrels\goodneighbor_squirrel\probe_out.txt"
with open(out_path, "w") as f:
    f.write(f"Object: {sq.name}, Verts: {len(pts)}\n")
    for ycut in [-0.1, -0.2, -0.3, -0.4]:
        for zcut in [1.5, 1.7, 1.8, 1.9]:
            h = [p for p in pts if p.y < ycut and p.z > zcut]
            if h:
                f.write(f"y<{ycut}, z>{zcut}: n={len(h)}, cx={sum(p.x for p in h)/len(h):.2f}, cy={sum(p.y for p in h)/len(h):.2f}, cz={sum(p.z for p in h)/len(h):.2f}\n")
    t = [p for p in pts if p.y > 0.2 and 1.2 < p.z]
    f.write(f"tail: n={len(t)}, x range: [{min(p.x for p in t):.2f}, {max(p.x for p in t):.2f}]\n")
    f.write("PROBE_DONE\n")
