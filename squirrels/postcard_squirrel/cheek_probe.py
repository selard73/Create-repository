import bpy, sys, os
D = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "postcard_squirrel_rigged.blend"))
sq = bpy.data.objects["Squirrel"]
names = {g.index: g.name for g in sq.vertex_groups}
cnt = {}; n = 0
for v in sq.data.vertices:
    c = v.co
    if c.z > 1.5 and c.x < -0.45 and c.y < 0.3:
        n += 1
        w = {names[g.group]: g.weight for g in v.groups}
        top = max(w, key=w.get) if w else "none"
        if w.get("Chest", 0) > 0.2 and c.z > 1.55:
            cnt["chest>0.2 (cheek zone)"] = cnt.get("chest>0.2 (cheek zone)", 0) + 1
        cnt[top] = cnt.get(top, 0) + 1
open(os.path.join(D, "cheek_probe.txt"), "w").write(f"verts x<-0.45 z>1.5: {n}; dominant bone counts {cnt}")
