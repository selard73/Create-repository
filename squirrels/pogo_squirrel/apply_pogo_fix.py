import bpy, os, sys, math
from mathutils import Vector

OUTD = r"C:\Users\slard\roblox-props\squirrels\pogo_squirrel"
NAME = "pogo_squirrel"
LOG = os.path.join(OUTD, "fixw_pogo_log.txt")

with open(LOG, "w") as logf:
    def log(m):
        logf.write(str(m) + "\n")
        print(m)

    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = bpy.data.objects["SquirrelRig"]
    gi = {g.index: g.name for g in sq.vertex_groups}

    def move(test, src_names, dst_name):
        dst = sq.vertex_groups.get(dst_name) or sq.vertex_groups.new(name=dst_name)
        moved = 0
        for v in sq.data.vertices:
            if not test(v.co, v.index): continue
            old = {gi[g.group]: g.weight for g in v.groups if gi.get(g.group) in src_names}
            w = sum(old.values())
            if w <= 0: continue
            for nm, ow in old.items():
                sq.vertex_groups[nm].remove([v.index])
            cur = sum(g.weight for g in v.groups if gi.get(g.group) == dst_name)
            dst.add([v.index], min(1.0, cur + w), "REPLACE")
            moved += 1
        return moved

    # 1. Lower pogo stick (z < 0.85): 100% rigid on Root
    n1 = move(lambda c, i: c.z < 0.85, ["Chest", "Neck", "Head", "Tail1", "Tail2"], "Root")
    log(f"1. Lower pogo stick (z < 0.85 -> Root): {n1} verts")

    # 2. Mid body / handlebars / jacket (0.85 <= z < 1.50): Head + Neck -> Chest
    n2 = move(lambda c, i: 0.85 <= c.z < 1.50, ["Head", "Neck"], "Chest")
    log(f"2. Mid body / handlebars (0.85 <= z < 1.50 Head+Neck -> Chest): {n2} verts")

    # 3. Tail weight in front of y < 0.1 below z 1.50 -> Chest
    n3 = move(lambda c, i: c.z < 1.50 and c.y < 0.1, ["Tail1", "Tail2"], "Chest")
    log(f"3. Stray tail in front (z < 1.50, y < 0.1 -> Chest): {n3} verts")

    # 4. Entire head / face / cap (x < 0.10, z >= 1.50): ALL Tail1 and Tail2 -> Head
    n4 = move(lambda c, i: c.x < 0.10 and c.z >= 1.50, ["Tail1", "Tail2"], "Head")
    log(f"4. Entire head/face/cap (x < 0.10, z >= 1.50 Tail1+Tail2 -> Head): {n4} verts")

    # 5. Tail region (x >= 0.15, z >= 0.85): Head + Neck -> Tail2
    n5 = move(lambda c, i: c.x >= 0.15 and c.z >= 0.85, ["Head", "Neck"], "Tail2")
    log(f"5. Tail region (x >= 0.15 Head+Neck -> Tail2): {n5} verts")

    # Audit the bone counts
    for bname in ["Root", "Chest", "Neck", "Head", "Tail1", "Tail2"]:
        count = sum(1 for v in sq.data.vertices if any(gi.get(g.group) == bname and g.weight > 0.05 for g in v.groups))
        log(f"Bone {bname} vert count: {count}")

    # Verify 0 tail on head
    head_leaks = sum(1 for v in sq.data.vertices if v.co.x < 0.10 and v.co.z >= 1.50 and any("Tail" in gi.get(g.group, "") and g.weight > 0.001 for g in v.groups))
    log(f"Head tail leaks: {head_leaks}")

    # Save fixed blend
    bpy.ops.wm.save_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    log("Saved fixed blend file.")

    # Export colour FBX
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUTD, f"{NAME}_color.fbx"),
        use_selection=False,
        bake_anim=False,
        add_leaf_bones=False,
        primary_bone_axis='Y',
        secondary_bone_axis='X',
        armature_nodetype='NULL'
    )
    log("Exported color FBX.")

    # Export gray FBX
    img_gray = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_gray_1k.png"))
    for mat in sq.data.materials:
        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE':
                node.image = img_gray
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUTD, f"{NAME}_gray.fbx"),
        use_selection=False,
        bake_anim=False,
        add_leaf_bones=False,
        primary_bone_axis='Y',
        secondary_bone_axis='X',
        armature_nodetype='NULL'
    )
    log("Exported gray FBX.")
    log("POGO_FIX_ALL_DONE")
