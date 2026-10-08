import bpy, os, sys, json, bmesh
from mathutils import Vector

OUTD = r"C:\Users\slard\roblox-props\squirrels\sassyshopper_squirrel"
NAME = "sassyshopper_squirrel"
LOG = os.path.join(OUTD, "fixw_test_log.txt")

with open(LOG, "w") as logf:
    def log(m):
        logf.write(str(m) + "\n")
        print(m)

    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = bpy.data.objects["SquirrelRig"]
    gi = {g.index: g.name for g in sq.vertex_groups}

    def inbox(c, b):
        return b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5]

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

    # Rule 1: Below head (z < 1.55), bags, dress, chest: Head+Neck -> Chest
    n1 = move(lambda c, i: inbox(c, [-1.4, 1.4, -1.0, 1.0, 0.0, 1.55]), ["Head", "Neck"], "Chest")
    log(f"Rule 1 (bags/body z<1.55 Head+Neck->Chest): {n1} verts")

    # Rule 2: Entire head/face/ears: box [-0.68, 0.75, -0.50, 0.48, 1.55, 2.50]:
    # Move ANY Tail1 or Tail2 weight to Head!
    n2 = move(lambda c, i: inbox(c, [-0.68, 0.75, -0.50, 0.48, 1.55, 2.50]), ["Tail1", "Tail2"], "Head")
    log(f"Rule 2 (entire head/face/ears Tail1+Tail2->Head): {n2} verts")

    # Rule 3: Actual tail (x < -0.72): move any stray Head/Neck weight to Tail2
    n3 = move(lambda c, i: inbox(c, [-1.4, -0.72, -0.5, 1.0, 0.0, 2.50]), ["Head", "Neck"], "Tail2")
    log(f"Rule 3 (actual tail x<-0.72 Head+Neck->Tail2): {n3} verts")

    # Rule 4: Lower tail below z 1.2: tail -> root
    n4 = move(lambda c, i: c.z < 1.2 and c.y < 0.5 and inbox(c, [-1.4, 0.0, -1.0, 1.0, 0.0, 1.2]), ["Tail1", "Tail2"], "Root")
    log(f"Rule 4 (lower tail/hips Tail->Root): {n4} verts")

    # Audit the face: check if ANY vertex in the head box still has Tail weight
    tail_leaks = 0
    for v in sq.data.vertices:
        if inbox(v.co, [-0.68, 0.75, -0.50, 0.48, 1.55, 2.50]):
            weights = {gi[g.group]: round(g.weight, 4) for g in v.groups if gi.get(g.group)}
            tw = sum(w for nm, w in weights.items() if "Tail" in nm)
            if tw > 0.001:
                tail_leaks += 1
                log(f"LEAK: v {v.index} ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f}) has tail weight: {weights}")
    log(f"Post-fix tail leaks on head/face: {tail_leaks}")

    # Check total bone weights to ensure no bone is emptied
    for bname in ["Root", "Chest", "Neck", "Head", "Tail1", "Tail2"]:
        count = sum(1 for v in sq.data.vertices if any(gi.get(g.group) == bname and g.weight > 0.05 for g in v.groups))
        log(f"Bone {bname} vert count: {count}")

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
    # Assign gray texture
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
    log("FIX_ALL_DONE")
